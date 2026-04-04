extends Node3D

@export var world_nodes: Array[Node3D] = []
@export var celestial_body_nodes: Array[Node3D] = []
@export var celestial_body_positions: Array[Vector3] = []  # Direction and distance in sky coordinates

var last_player_pos: Vector3
var sky_basis: Basis = Basis.IDENTITY

var grid_spacing: float = 90

func _process(_delta):
	var player = Globals.getPlayer()
	RenderingServer.global_shader_parameter_set("planet_radius", 30.0)
	RenderingServer.global_shader_parameter_set("curve_origin", player.global_position)
	
	update_sky()
	update_celestial_bodies()



func update_sky():
	grid_spacing = 120
	var player = Globals.getPlayer()
	if not player:
		return
	var player_pos = player.global_transform.origin

	# First frame initialization
	if last_player_pos == Vector3.ZERO:
		last_player_pos = player_pos
		return

	# Calculate movement delta
	var delta = player_pos - last_player_pos
	last_player_pos = player_pos

	var lat_step = delta.z / (3 * grid_spacing) * TAU
	var lon_step = delta.x / (3 * grid_spacing) * TAU

	# Accumulate rotations onto sky_basis
	if abs(lat_step) > 0.0001:
		sky_basis = Basis(Vector3.LEFT, lat_step) * sky_basis
	if abs(lon_step) > 0.0001:
		sky_basis = Basis(Vector3.BACK, lon_step) * sky_basis

	var environment = %WorldEnvironment.environment
	if environment:
		environment.sky_rotation = sky_basis.get_euler()

func update_celestial_bodies():
	var player = Globals.getPlayer()
	if not player:
		return
	var player_pos = player.global_transform.origin

	for i in range(min(celestial_body_nodes.size(), celestial_body_positions.size())):
		var node = celestial_body_nodes[i]
		var sky_pos = celestial_body_positions[i]
		if node:
			# Transform the sky_position by the current sky rotation (magnitude = distance)
			var rotated_pos = sky_basis * sky_pos
			node.global_transform.origin = player_pos + rotated_pos

