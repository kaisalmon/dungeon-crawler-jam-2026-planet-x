extends Node3D

class_name GridEntity

# Inner class for move validation result
class MoveResult:
	var is_allowed: bool
	var override: CollisionOverride
	var ground_override: CollisionOverride

	func _init(allowed: bool, collision_override: CollisionOverride = null, ground_override: CollisionOverride = null):
		is_allowed = allowed
		override = collision_override
		self.ground_override = ground_override

# Movement config
const GRID_SIZE: float = 2.0
const TURN_ANGLE: float = 90.0
const GRID_OFFSET: Vector3 = Vector3(GRID_SIZE / 2, 0, GRID_SIZE / 2)
static var gravity: Vector3 = Vector3(0, -1, 0) 

# Spring physics
@export var spring_constant: float = 80.0
@export var turn_spring_constant: float = 10.0
@export var damping_constant: float = 12
@export var frozen: bool = false
@export var can_move_through_doors = false
@export var lock_x: bool = false
@export var lock_y: bool = false
@export var lock_z: bool = false
@export var gravity_strength: float = 9.0
@export var max_step_height: float = 0.6

# State
var target_position: Vector3
var target_rotation: Basis
var is_moving: bool = false
var is_turning: bool = false
var prev_action: String = ""
var visual_gravity:Vector3 = gravity
var velocity: Vector3 = Vector3.ZERO
var fall_height = 0.0
var bump_at = 0

@onready var player_turn_sfx: AudioStreamPlayer = %PlayerTurnSFX

func _ready():
	target_position = snap_to_grid(global_transform.origin)
	target_rotation = global_transform.basis
	add_to_group("grid_entities")
	add_to_group("saveable")

func snap_to_grid(pos: Vector3, snap_y = false) -> Vector3:
	var snapped_pos = (pos - GRID_OFFSET).snapped(Vector3(GRID_SIZE, GRID_SIZE, GRID_SIZE)) + GRID_OFFSET
	if not snap_y:
		snapped_pos.y = pos.y # Keep original Y to avoid vertical snapping
	return snapped_pos


func _physics_process(delta):
	if frozen:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var player_distance = (player.global_transform.origin - global_transform.origin).length()
	if player_distance > 80:
		return
	gravity = gravity.normalized()
	visual_gravity = visual_gravity.normalized()
	if visual_gravity.is_equal_approx(-1 * gravity):
		visual_gravity += Vector3(0.01,0.01,0.01) # Give it some direction to slerp
		visual_gravity = visual_gravity.normalized()
	if not  visual_gravity.is_equal_approx( gravity):
		visual_gravity = visual_gravity.slerp(gravity, delta * 5)
	
	update_movement(delta)

func is_valid_move(from_pos: Vector3, dir: Vector3) -> MoveResult:
	var move_vector = dir.normalized() * GRID_SIZE
	var new_pos = snap_to_grid(from_pos + move_vector)

	var original_move_allowed = true  # Track if move would normally be allowed
	var collision_override = null
	var ground_override = null

	# Check what we're currently standing on
	var current_ground_override = null
	var current_ground_ray = PhysicsRayQueryParameters3D.new()
	current_ground_ray.from = from_pos
	current_ground_ray.to = from_pos + gravity * GRID_SIZE * 1.1
	current_ground_ray.exclude = [self]
	if can_move_through_doors:
		current_ground_ray.set_collision_mask(1)

	var current_ground_collision = get_world_3d().direct_space_state.intersect_ray(current_ground_ray)
	if not current_ground_collision.is_empty():
		var current_ground_collider = current_ground_collision["collider"]
		if current_ground_collider is CollisionOverride:
			current_ground_override = current_ground_collider
		elif current_ground_collider.get_parent() is CollisionOverride:
			current_ground_override = current_ground_collider.get_parent()

	# Prevent moving into a tile another GridEntity is targeting
	for other in get_tree().get_nodes_in_group("grid_entities"):
		if other == self or other.frozen:
			continue
		if other is GridEntity:
			if snap_to_grid(other.target_position, true) == snap_to_grid(new_pos, true):
				original_move_allowed = false
				break

	if new_pos.distance_to(from_pos) < 0.1:
		original_move_allowed = false

	if original_move_allowed:
		var ray_params = PhysicsRayQueryParameters3D.new()
		ray_params.from = from_pos
		ray_params.to = new_pos
		ray_params.exclude = [self]
		if can_move_through_doors:
			ray_params.set_collision_mask(1)

		var collision = get_world_3d().direct_space_state.intersect_ray(ray_params)

		var movement_blocked = false
		if not collision.is_empty():
			var collider = collision["collider"]
			var override = null
			if collider is CollisionOverride:
				override = collider
			elif collider.get_parent() is CollisionOverride:
				override = collider.get_parent()
			if override:
				collision_override = override
				if not override.can_entity_move_into(self, from_pos, new_pos):
					movement_blocked = true
			else:
				movement_blocked = true

		if movement_blocked:
			original_move_allowed = false

	if original_move_allowed:
		var ground_ray_params = PhysicsRayQueryParameters3D.new()
		ground_ray_params.from = new_pos
		ground_ray_params.to = new_pos + gravity * GRID_SIZE * 1
		ground_ray_params.exclude = [self]
		if can_move_through_doors:
			ground_ray_params.set_collision_mask(1)

		var ground_collision = get_world_3d().direct_space_state.intersect_ray(ground_ray_params)
		var has_ground = not ground_collision.is_empty()
		if not ground_collision.is_empty():
			var ground_collider = ground_collision["collider"]
			if ground_collider is CollisionOverride:
				ground_override = ground_collider
			elif ground_collider.get_parent() is CollisionOverride:
				ground_override = ground_collider.get_parent()
			if ground_override:
				if not ground_override.can_entity_move_ontop(self, new_pos):
					has_ground = false

		# Allow current ground override to override the result
		if current_ground_override:
			has_ground = current_ground_override.can_entity_move_off(self, from_pos, new_pos, has_ground)

		return MoveResult.new(has_ground, collision_override, ground_override)

	# Move was blocked, but allow current ground override to override
	var final_allowed = false
	if current_ground_override:
		final_allowed = current_ground_override.can_entity_move_off(self, from_pos, new_pos, false)

	return MoveResult.new(final_allowed, null, null)

func try_move_dir(dir: Vector3):
	var move_vector = dir.normalized() * GRID_SIZE
	var new_pos = snap_to_grid(target_position + move_vector)

	var move_result = is_valid_move(target_position, dir)
	if move_result.is_allowed:
		# Check what we're currently standing on for move_off callback
		var current_ground_override = null
		var current_ground_ray = PhysicsRayQueryParameters3D.new()
		current_ground_ray.from = target_position
		current_ground_ray.to = target_position + gravity * GRID_SIZE * 1.1
		current_ground_ray.exclude = [self]
		if can_move_through_doors:
			current_ground_ray.set_collision_mask(1)

		var current_ground_collision = get_world_3d().direct_space_state.intersect_ray(current_ground_ray)
		if not current_ground_collision.is_empty():
			var current_ground_collider = current_ground_collision["collider"]
			if current_ground_collider is CollisionOverride:
				current_ground_override = current_ground_collider
			elif current_ground_collider.get_parent() is CollisionOverride:
				current_ground_override = current_ground_collider.get_parent()

		if move_result.override:
			var skip_normal = await move_result.override.on_entity_move_into(self, target_position, new_pos)
			if skip_normal:
				return
		# Check if we're moving off a ground override
		if current_ground_override and current_ground_override != move_result.ground_override:
			var skip_normal = current_ground_override.on_entity_move_off(self, target_position, new_pos)
			if skip_normal:
				return
		if move_result.ground_override:
			var skip_normal = await move_result.ground_override.on_entity_move_ontop(self, target_position, new_pos)
			if skip_normal:
				return
		target_position = new_pos
		is_moving = true
		on_move_success()
	else:
		on_move_fail(dir)

func try_move_to(pos: Vector3):
	var dir = pos - target_position
	try_move_dir(dir)

func on_move_success():
	pass # child override

func on_move_fail(dir: Vector3):
	var t = Time.get_ticks_msec()
	if t - bump_at < 500:
		return
	bump_at = t
	velocity += dir * 6
	
func start_turn(direction: int):
	player_turn_sfx.play()
	target_rotation = target_rotation.rotated(-gravity, deg_to_rad(direction * TURN_ANGLE))
	is_turning = true

func is_grounded() -> bool:
	if gravity == Vector3.UP or gravity == Vector3.DOWN:
		if lock_y:
			return true
	if gravity == Vector3.LEFT or gravity == Vector3.RIGHT:
		if lock_x:
			return true
	if gravity == Vector3.FORWARD or gravity == Vector3.BACK:
		if lock_z:
			return true

	var ray_params = PhysicsRayQueryParameters3D.new()
	ray_params.from = target_position
	ray_params.to = target_position + gravity * GRID_SIZE * 1.1
	ray_params.exclude = [self]
	var collision = get_world_3d().direct_space_state.intersect_ray(ray_params)
	return not collision.is_empty()
	
func align_basis_up(vector: Basis, up: Vector3) -> Basis:
	var new_up = up.normalized()
	var old_forward = vector.z.normalized()

	# Check if old_forward and up are aligned
	if abs(old_forward.dot(new_up)) > 0.999:
		# If they're nearly parallel, pick an arbitrary perpendicular forward
		old_forward = new_up.cross(Vector3(1, 0, 0)).normalized()
		if old_forward.length_squared() < 0.01:
			old_forward = new_up.cross(Vector3(0, 0, 1)).normalized()

	# Remove the up component from forward to make it orthogonal to new up
	var new_forward = (old_forward - new_up * old_forward.dot(new_up)).normalized()

	# If forward and up are aligned, cross product will naturally fix it
	var new_right = new_forward.cross(new_up).normalized()
	new_forward = new_up.cross(new_right).normalized() # Recompute forward to ensure orthogonality

	return Basis(new_right, new_up, new_forward).orthonormalized()


func update_movement(delta):
	# Rotation smoothing
	var current_basis = global_transform.basis

	#Ensure target rotation's down vector is aligned with gravity
	target_rotation = align_basis_up(target_rotation, gravity)

	var new_basis = current_basis.slerp(target_rotation.get_rotation_quaternion(), delta * turn_spring_constant)
	global_transform.basis = new_basis



	var pos_error = (target_position - global_transform.origin)
	var accel = pos_error * spring_constant - velocity * damping_constant
	velocity += accel * delta
	global_transform.origin += velocity * delta

	

	if is_moving and pos_error.length() < 1.0:
		is_moving = false
		check_input_queue()

	if is_turning and basis_almost_equal(current_basis, target_rotation):
		is_turning = false
		check_input_queue()

func basis_almost_equal(b1: Basis, b2: Basis) -> bool:
	return b1.get_rotation_quaternion().angle_to(b2.get_rotation_quaternion()) < deg_to_rad(4)

func check_input_queue():
	pass # override for player input queue

func save():
	var save_data = {
		"x": target_position.x,
		"y": target_position.y,
		"z": target_position.z,
		"rotation": {
			"x": {
				"x": target_rotation.x.x,
				"y": target_rotation.x.y,
				"z": target_rotation.x.z,
			},
			"y": {
				"x": target_rotation.y.x,
				"y": target_rotation.y.y,
				"z": target_rotation.y.z,
			},
			"z": {
				"x": target_rotation.z.x,
				"y": target_rotation.z.y,
				"z": target_rotation.z.z,
			},
		},
		"gravity": {
			"x": gravity.x,
			"y": gravity.y,
			"z": gravity.z,
		},
		"frozen": frozen,
		"can_move_through_doors": can_move_through_doors,
		"lock_x": lock_x,
		"lock_y": lock_y,
		"lock_z": lock_z,
	}
	return save_data

func load(data):
	target_position = Vector3(data["x"], data["y"], data["z"])
	target_rotation = Basis(
		Vector3(data["rotation"]["x"]["x"], data["rotation"]["x"]["y"], data["rotation"]["x"]["z"]),
		Vector3(data["rotation"]["y"]["x"], data["rotation"]["y"]["y"], data["rotation"]["y"]["z"]),
		Vector3(data["rotation"]["z"]["x"], data["rotation"]["z"]["y"], data["rotation"]["z"]["z"])
	)
	gravity = Vector3(data["gravity"]["x"], data["gravity"]["y"], data["gravity"]["z"])
	visual_gravity = gravity
	velocity = Vector3.ZERO
	global_transform.origin = target_position
	global_transform.basis = target_rotation
	frozen = data["frozen"]
	can_move_through_doors = data["can_move_through_doors"]
	lock_x = data["lock_x"]
	lock_y = data["lock_y"]
	lock_z = data["lock_z"]


func teleport_to_position(new_position: Vector3):
	new_position = snap_to_grid(new_position)
	global_transform.origin = new_position
	target_position = new_position
