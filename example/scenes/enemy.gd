extends GridEntity

var wait_time: float = 1.0
var starting_position: Vector3
var max_distance = 5.0

@export var gun: NodePath
@export var laserParticles: NodePath

var state = "wander"
func _ready():
	super._ready()
	starting_position = self.global_transform.origin

func _process(delta: float) -> void:
	if wait_time > 0:
		wait_time -= delta
		return

	if has_line_of_sight(Globals.getPlayer().global_transform.origin):
		state = "attack"
	else:
		state = "wander"

	if state == "wander":
		process_wander(delta)
	elif state == "attack":
		process_attack(delta)

func process_wander(_delta: float) -> void:

	# Move in random direction
	var rotate_chance = 0.1
	var forward = -transform.basis.z.normalized()
	var forward_position = self.target_position + forward * GRID_SIZE
	if forward_position.distance_to(starting_position) > max_distance * GRID_SIZE:
		rotate_chance = 1.0  # Force rotation if we're too far from the starting position
	if randf() < rotate_chance:
		var rotation_amount = PI / 2
		if randf() < 0.5:
			rotation_amount = -rotation_amount    
		self.target_rotation = self.target_rotation.rotated(Vector3.UP, rotation_amount)
		wait_time = 0.5
	else:
		self.try_move_dir(forward)
		wait_time = 1.0


func process_attack(_delta: float) -> void:
	var player = Globals.getPlayer()
	if player == null:
		return

	if is_facing(player.target_position):
		attack(player)
	else:
		rotate_towards(player.target_position)

func rotate_towards(target_position: Vector3):
	var direction_to_target = (target_position - self.global_transform.origin).normalized()
	var current_forward = -transform.basis.z.normalized()
	var go_left = current_forward.cross(direction_to_target).y > 0
	var rotation_amount = PI / 2
	if not go_left:
		rotation_amount = -rotation_amount
	self.target_rotation = self.target_rotation.rotated(Vector3.UP, rotation_amount)
	wait_time = 0.5

func is_facing(target_position: Vector3) -> bool:
	var direction_to_target = (target_position - self.global_transform.origin).normalized()
	var current_forward = -transform.basis.z.normalized()
	var angle_to_target = current_forward.angle_to(direction_to_target)
	return abs(angle_to_target) < PI / 8  # Consider facing if within 22.5 degrees

func attack(player: Player):
	shoot_at(player.global_transform.origin)

func miss(target_position: Vector3):
	var delta = target_position - self.global_transform.origin
	var miss_direction = delta.cross(
		Vector3(randf_range(-1, 1), randf_range(-1, 1), 0).normalized()
	).normalized()
	shoot_at(target_position + miss_direction * GRID_SIZE * .5)
		

func shoot_at(target_position: Vector3):
	wait_time = .8

	var gun_node: EnemySpring = get_node(gun)
	target_position += Vector3(0, 0.25, 0)
	var looking_at_player_from_gun_node = (target_position - gun_node.global_transform.origin).normalized()
	var target_gun_rotation = Basis.looking_at(looking_at_player_from_gun_node, Vector3.UP).get_rotation_quaternion()
	gun_node.rotation_override = target_gun_rotation
	gun_node.override_rotation = true
	var laser_particles_node: GPUParticles3D = get_node(laserParticles)
	await get_tree().create_timer(.3).timeout
	laser_particles_node.emitting = true
	gun_node.knockback(-looking_at_player_from_gun_node, 50)
	await get_tree().create_timer(.1).timeout
	gun_node.override_rotation = false


func has_line_of_sight(target_position: Vector3, origin = self.global_transform.origin) -> bool:
	var deltaY = target_position.y - origin.y
	if abs(deltaY) > GRID_SIZE * .1:
		return false

	var deltaX = target_position.x - origin.x
	var deltaZ = target_position.z - origin.z
	var differentX = abs(deltaX) > GRID_SIZE * .1
	var differentZ = abs(deltaZ) > GRID_SIZE * .1
	if differentX and differentZ:
		return false
	
	return true
