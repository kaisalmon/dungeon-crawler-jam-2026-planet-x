extends Node

@export var paths: Array[Path3D]
@export var camera_one: Camera3D
@export var camera_two: Camera3D
@export var focus_markers: Array[Marker3D]  # One focus marker per path

@export_group("Animation Settings")
@export var travel_duration: float = 5.0
@export var fade_duration: float = 1.0

@export_group("Focus Settings")
@export var focus_screen_offset: Vector2 = Vector2.ZERO  # Pixel offset from screen center

var current_path_index: int = 0
var current_camera: Camera3D
var next_camera: Camera3D
var path_followers: Array[PathFollow3D] = []
var is_transitioning: bool = false
var current_focus: Marker3D
var next_focus: Marker3D
var is_active: bool = true

# For proper cross-fade - render next camera to texture overlay
var canvas_layer: CanvasLayer
var texture_rect: TextureRect
var sub_viewport: SubViewport
var camera_one_clone: Camera3D
var camera_two_clone: Camera3D

# Track all active tweens so we can kill them
var active_tweens: Array[Tween] = []

func _ready() -> void:
	if paths.is_empty() or not camera_one or not camera_two:
		push_error("FancyCameras: Missing paths or cameras!")
		return

	# Validate focus markers match paths
	if focus_markers.size() != paths.size():
		push_warning("FancyCameras: Number of focus markers (%d) doesn't match number of paths (%d). Some focuses may be missing." % [focus_markers.size(), paths.size()])

	# Set initial focus
	if not focus_markers.is_empty():
		current_focus = focus_markers[0]
		next_focus = focus_markers[1 % focus_markers.size()] if focus_markers.size() > 1 else current_focus

	# Create SubViewport to render the "next" camera
	sub_viewport = SubViewport.new()
	var main_vp = get_viewport()
	sub_viewport.size = main_vp.size
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.world_3d = main_vp.world_3d  # CRITICAL: Share the same 3D world!
	sub_viewport.transparent_bg = false

	# Copy rendering settings from main viewport
	sub_viewport.msaa_3d = main_vp.msaa_3d
	sub_viewport.screen_space_aa = main_vp.screen_space_aa
	sub_viewport.use_taa = main_vp.use_taa
	sub_viewport.use_debanding = main_vp.use_debanding
	sub_viewport.scaling_3d_mode = main_vp.scaling_3d_mode
	sub_viewport.scaling_3d_scale = main_vp.scaling_3d_scale

	# Copy texture filtering settings
	sub_viewport.canvas_item_default_texture_filter = main_vp.canvas_item_default_texture_filter
	sub_viewport.canvas_item_default_texture_repeat = main_vp.canvas_item_default_texture_repeat

	add_child(sub_viewport)

	# Create TextureRect to display the SubViewport's texture as an overlay
	texture_rect = TextureRect.new()
	texture_rect.texture = sub_viewport.get_texture()
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Create shader material for blending with transparency
	var shader_code = """
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blend_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 overlay_color = texture(TEXTURE, UV);
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	COLOR = mix(screen_color, overlay_color, blend_amount);
}
"""
	var shader = Shader.new()
	shader.code = shader_code
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("blend_amount", 0.0)
	texture_rect.material = shader_material

	# Connect to viewport size changes to update SubViewport size
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	# Add to CanvasLayer BELOW UI (low layer number)
	# UI elements on default layers (0-10) will appear on top
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = -100
	add_child(canvas_layer)
	canvas_layer.add_child(texture_rect)

	# Create PathFollow3D nodes for each camera
	var follower_one = PathFollow3D.new()
	var follower_two = PathFollow3D.new()
	path_followers = [follower_one, follower_two]

	# Create camera duplicates that will live in the SubViewport
	# These will be positioned by RemoteTransform3D to match the real cameras
	camera_one_clone = Camera3D.new()
	camera_two_clone = Camera3D.new()
	sub_viewport.add_child(camera_one_clone)
	sub_viewport.add_child(camera_two_clone)

	# Copy camera properties
	camera_one_clone.fov = camera_one.fov
	camera_one_clone.cull_mask = camera_one.cull_mask
	camera_one_clone.environment = camera_one.environment
	camera_one_clone.attributes = camera_one.attributes

	camera_two_clone.fov = camera_two.fov
	camera_two_clone.cull_mask = camera_two.cull_mask
	camera_two_clone.environment = camera_two.environment
	camera_two_clone.attributes = camera_two.attributes

	# Set up RemoteTransform3D to sync positions from real cameras to clones
	var remote_one = RemoteTransform3D.new()
	remote_one.remote_path = camera_one_clone.get_path()
	remote_one.update_position = true
	remote_one.update_rotation = true
	camera_one.add_child(remote_one)

	var remote_two = RemoteTransform3D.new()
	remote_two.remote_path = camera_two_clone.get_path()
	remote_two.update_position = true
	remote_two.update_rotation = true
	camera_two.add_child(remote_two)

	# Set up initial state
	current_camera = camera_one
	next_camera = camera_two

	# Main viewport uses the real current camera
	current_camera.current = true

	# SubViewport will use the CLONE of the next camera
	camera_two_clone.current = true

	# Start the first path
	_setup_camera_on_path(current_camera, path_followers[0], 0)
	start_camera_movement()

func _on_viewport_size_changed() -> void:
	# Update SubViewport size and settings to match main viewport
	if sub_viewport:
		var main_vp = get_viewport()
		sub_viewport.size = main_vp.size
		sub_viewport.scaling_3d_mode = main_vp.scaling_3d_mode
		sub_viewport.scaling_3d_scale = main_vp.scaling_3d_scale

func _process(_delta: float) -> void:
	if not is_active:
		return

	# Make each camera look at its corresponding focus point
	# Current camera looks at current focus, next camera looks at next focus
	var cam1_is_current = (current_camera == camera_one)

	var cam1_focus = current_focus if cam1_is_current else next_focus
	var cam2_focus = next_focus if cam1_is_current else current_focus

	if cam1_focus:
		var adjusted_target = _calculate_offset_look_target(camera_one, cam1_focus.global_position)
		camera_one.look_at(adjusted_target, Vector3.UP)
	if cam2_focus:
		var adjusted_target = _calculate_offset_look_target(camera_two, cam2_focus.global_position)
		camera_two.look_at(adjusted_target, Vector3.UP)

## Public API: Stop menu cameras and fade to player camera
func transition_to_player_camera(player_camera: Camera3D, transition_duration: float = 1.0) -> void:
	# Stop all menu camera animations
	is_active = false

	# Kill all active tweens
	for tween in active_tweens:
		if tween and tween.is_valid():
			tween.kill()
	active_tweens.clear()

	# Create a temporary camera clone in SubViewport that mirrors the player camera
	# This way we don't break the player script by reparenting their camera
	var player_camera_clone = Camera3D.new()
	player_camera_clone.fov = player_camera.fov
	player_camera_clone.cull_mask = player_camera.cull_mask
	player_camera_clone.environment = player_camera.environment
	player_camera_clone.attributes = player_camera.attributes
	sub_viewport.add_child(player_camera_clone)
	player_camera_clone.current = true

	# Set up RemoteTransform to sync player camera transform to the clone
	var remote_transform = RemoteTransform3D.new()
	remote_transform.remote_path = player_camera_clone.get_path()
	remote_transform.update_position = true
	remote_transform.update_rotation = true
	player_camera.add_child(remote_transform)

	# Fade from menu camera to player camera
	var fade_tween = create_tween()
	fade_tween.tween_method(
		func(value): texture_rect.material.set_shader_parameter("blend_amount", value),
		0.0,
		1.0,
		transition_duration
	)

	# After fade, switch player camera to active and clean up
	fade_tween.tween_callback(func():
		# Activate the real player camera
		player_camera.current = true

		# Disable menu cameras
		current_camera.current = false
		next_camera.current = false

		# Clean up the clone and remote transform
		remote_transform.queue_free()
		player_camera_clone.queue_free()

		# Completely disable the rendering system to save performance
		texture_rect.material.set_shader_parameter("blend_amount", 0.0)
		canvas_layer.visible = false

		# Disable SubViewport rendering - this is the key performance saver!
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

		# Clean up camera clones
		camera_one_clone.queue_free()
		camera_two_clone.queue_free()
	)

func _calculate_offset_look_target(camera: Camera3D, world_target: Vector3) -> Vector3:
	# Calculate where the camera should look to place the target at the offset position
	if focus_screen_offset == Vector2.ZERO:
		return world_target

	# Get viewport size
	var viewport_size = get_viewport().size

	# Calculate the normalized offset (-1 to 1 range)
	# Positive X = right, Positive Y = down (screen space)
	var normalized_offset = Vector2(
		focus_screen_offset.x / (viewport_size.x * 0.5),
		focus_screen_offset.y / (viewport_size.y * 0.5)
	)

	# Get camera basis vectors
	var cam_right = camera.global_transform.basis.x
	var cam_up = -camera.global_transform.basis.y  # Negative because Y is down in screen space

	# Calculate the distance from camera to target
	var distance = camera.global_position.distance_to(world_target)

	# Calculate how much to offset in world space
	# Use FOV to determine how far the offset should be at this distance
	var fov_radians = deg_to_rad(camera.fov)
	var vertical_size = distance * tan(fov_radians * 0.5) * 2.0
	var horizontal_size = vertical_size * (viewport_size.x / viewport_size.y)

	# Calculate the offset in world space
	var world_offset = cam_right * (normalized_offset.x * horizontal_size * 0.5) + \
					   cam_up * (normalized_offset.y * vertical_size * 0.5)

	# Return the adjusted target position
	return world_target + world_offset

func _setup_camera_on_path(camera: Camera3D, follower: PathFollow3D, path_index: int) -> void:
	# Clean up old remote transform if it exists
	for child in follower.get_children():
		if child is RemoteTransform3D:
			child.queue_free()

	# Remove follower from old parent if it has one
	if follower.get_parent():
		follower.get_parent().remove_child(follower)

	# Add follower to the new path
	paths[path_index].add_child(follower)
	follower.progress_ratio = 0.0
	follower.loop = false

	# Use remote transform to control camera position without reparenting
	var remote_transform = RemoteTransform3D.new()
	remote_transform.remote_path = camera.get_path()
	remote_transform.update_position = true
	remote_transform.update_rotation = false  # We'll handle rotation manually with look_at
	remote_transform.update_scale = false
	follower.add_child(remote_transform)

func start_camera_movement() -> void:
	_animate_current_path()

func _animate_current_path() -> void:
	if not is_active:
		return

	var current_follower = path_followers[0] if current_camera == camera_one else path_followers[1]

	# Calculate timing for seamless overlap
	# The fade should complete exactly when current path completes
	# So the fade starts fade_duration seconds before the end
	var time_until_fade_starts = travel_duration - fade_duration

	# Animate the camera along the full path
	var path_tween = create_tween()
	active_tweens.append(path_tween)
	path_tween.tween_property(current_follower, "progress_ratio", 1.0, travel_duration)

	# Start the fade transition fade_duration seconds before path completes
	var fade_trigger_tween = create_tween()
	active_tweens.append(fade_trigger_tween)
	fade_trigger_tween.tween_interval(time_until_fade_starts)
	fade_trigger_tween.tween_callback(_prepare_next_path)

func _prepare_next_path() -> void:
	# Calculate next path index (loop through all paths)
	var next_path_index = (current_path_index + 1) % paths.size()

	# Set up the next camera on the next path
	var next_follower = path_followers[1] if current_camera == camera_one else path_followers[0]
	_setup_camera_on_path(next_camera, next_follower, next_path_index)

	# Update the next focus marker to match the next path
	if not focus_markers.is_empty():
		next_focus = focus_markers[next_path_index % focus_markers.size()]

	# Start transition
	_transition_to_next_camera(next_path_index)

func _transition_to_next_camera(next_path_index: int) -> void:
	if not is_active:
		return

	is_transitioning = true
	var next_follower = path_followers[1] if current_camera == camera_one else path_followers[0]

	# Activate the correct clone in the SubViewport
	# The SubViewport should show the NEXT camera's clone
	var next_clone = camera_one_clone if next_camera == camera_one else camera_two_clone
	next_clone.current = true

	# Start animating the next camera along its full path
	var next_path_tween = create_tween()
	active_tweens.append(next_path_tween)
	next_path_tween.tween_property(next_follower, "progress_ratio", 1.0, travel_duration)

	# Create tween for cross-fade
	var fade_tween = create_tween()
	active_tweens.append(fade_tween)

	# TRUE CROSS-FADE: Fade in the overlay showing next camera view
	# Use shader parameter to blend between the two camera views
	fade_tween.tween_method(
		func(value): texture_rect.material.set_shader_parameter("blend_amount", value),
		0.0,
		1.0,
		fade_duration
	)

	# After fade completes, swap cameras
	fade_tween.tween_callback(func():
		# Swap which camera is active in the MAIN viewport
		current_camera.current = false
		next_camera.current = true

		# Reset blend amount (transition complete)
		texture_rect.material.set_shader_parameter("blend_amount", 0.0)

		# Update references - swap which camera is "current" vs "next"
		var temp = current_camera
		current_camera = next_camera
		next_camera = temp

		# Swap focus markers too
		var temp_focus = current_focus
		current_focus = next_focus
		next_focus = temp_focus

		current_path_index = next_path_index
		is_transitioning = false

		# Continue the loop - schedule next transition
		# The path has already been animating for fade_duration seconds
		# It will run for travel_duration total, so time remaining is:
		var time_already_elapsed = fade_duration
		var time_remaining = travel_duration - time_already_elapsed
		# Next fade should start fade_duration seconds before the path ends
		var time_until_next_fade = time_remaining - fade_duration

		var continue_tween = create_tween()
		active_tweens.append(continue_tween)
		continue_tween.tween_interval(time_until_next_fade)
		continue_tween.tween_callback(_prepare_next_path)
	)
