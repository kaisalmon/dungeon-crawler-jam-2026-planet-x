extends GridEntity

var wait_time: float = 1.0
var starting_position: Vector3
var max_distance = 5.0

@export var gun: NodePath
@export var laserParticles: NodePath
@export var dead_scene: PackedScene
@export var staticTexture: Texture2D
var faceTexture: Texture2D
@export var face: MeshInstance3D

var static_change_cooldown = 0.0

@export var health = 2
@export var shots_per_attack = 1
@export var accuaracy_modifier_linear = 0.0
var iframes = 0.0
@onready var enemy_shoot_sfx: AudioStreamPlayer3D = %EnemyShootSFX
@onready var enemy_move_sfx: AudioStreamPlayer3D = %EnemyMoveSFX
@onready var enemy_hit_sfx: AudioStreamPlayer3D = %EnemyHitSFX


var decaying_shot_count = 0 # Decreases over time, increases with each attack.

signal died

var state = "wander"
var sleeping = false

func _set_sleeping(value: bool) -> void:
	if sleeping == value:
		return
	sleeping = value
	$EnemyTorso.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT

func _ready():
	super._ready()
	add_to_group("enemies")
	starting_position = self.global_transform.origin
	var laser_particles_node: GPUParticles3D = get_node(laserParticles)
	laser_particles_node.process_material = laser_particles_node.process_material.duplicate()
	face.material_override = face.material_override.duplicate()
	faceTexture = face.material_override.get_shader_parameter("texture_albedo")

func _process(delta: float) -> void:
	var player = Globals.getPlayer()
	var distance_to_player = self.global_transform.origin.distance_to(player.global_transform.origin)

	if distance_to_player > GRID_SIZE * 12:
		_set_sleeping(true)
		return
	_set_sleeping(false)

	decaying_shot_count = max(0, decaying_shot_count - delta * 0.3)
	self.iframes = max(0, self.iframes - delta)

	if self.iframes > 0:
		face.material_override.set("shader_parameter/texture_albedo", staticTexture)
		static_change_cooldown -= delta
		if static_change_cooldown <= 0:
			static_change_cooldown = 0.05
			face.material_override.set("shader_parameter/uv1_offset", Vector3(randf(), randf(), 0))

	else:
		face.material_override.set("shader_parameter/texture_albedo", faceTexture)
		face.material_override.set("shader_parameter/uv1_offset", Vector3(0, 0, 0))

	if wait_time > 0:
		wait_time -= delta
		return

	if not player.in_cutscene and has_line_of_sight(player.global_transform.origin):
		state = "attack"
	else:
		state = "wander"

	if state == "wander":
		process_wander(delta)
	elif state == "attack":
		process_attack(delta)

func get_hit_chance(distance_to_player: float) -> float:
	var distance_tiles = distance_to_player / GRID_SIZE
	if distance_tiles < 1.5:
		if decaying_shot_count < 0.5:
			return 0.2
		return 1 # After the first shot, enemies always hit at point blank
	if distance_tiles < 2.5:
		if decaying_shot_count < 0.5:
			return 0.05
		elif decaying_shot_count < 1.5:
			return 0.5
		elif decaying_shot_count < 2.5:
			return 0.8
		else:
			return 1
	if decaying_shot_count < 0.5:
		return 0 # Always miss on first shot if distance is 3 or more
	elif decaying_shot_count < 1.5:
		return 0.3
	elif decaying_shot_count < 2.5:
		return 0.5
	elif decaying_shot_count < 3.5:
		return 0.9
	else:
		return 1

func process_wander(_delta: float) -> void:
	var player = Globals.getPlayer()
	if not player.in_cutscene:
		var directions = [
			Vector3(1, 0, 0),
			Vector3(-1, 0, 0),
			Vector3(0, 0, 1),
			Vector3(0, 0, -1)
		]
		for dir in directions:
			var check_position = self.target_position + dir * GRID_SIZE
			var move_validity: MoveResult = self.is_valid_move(check_position, dir)
			if move_validity.is_allowed and has_line_of_sight(player.target_position, check_position):
				if not is_facing(player.target_position, check_position):
					rotate_towards(player.target_position, check_position)
					wait_time = 0.1
					return
				else:
					self.try_move_dir(dir)
					wait_time = 0.5
					return
	
	var rotate_chance = 0.1
	var forward = -transform.basis.z.normalized()
	var forward_position = self.target_position + forward * GRID_SIZE
	if forward_position.distance_to(starting_position) > max_distance * GRID_SIZE:
		rotate_chance = 1.0  # Force rotation if we're too far from the starting position
	if not self.is_valid_move(self.target_position, forward).is_allowed:
		rotate_chance = 1.0 
	if randf() < rotate_chance:
		var rotation_amount = PI / 2
		if randf() < 0.5:
			rotation_amount = -rotation_amount    
		self.target_rotation = self.target_rotation.rotated(Vector3.UP, rotation_amount)
		wait_time = 0.25
	else:
		enemy_move_sfx.play()
		self.try_move_dir(forward)
		wait_time = 0.3

func process_attack(_delta: float) -> void:
	var player = Globals.getPlayer()
	if player == null:
		return
	var distance_to_player = self.global_transform.origin.distance_to(player.global_transform.origin)

	if distance_to_player > GRID_SIZE * 6:
		print("Chasing")
		enemy_move_sfx.play()
		var forward = -transform.basis.z.normalized()

		self.try_move_dir(forward)
		wait_time = 0.3
		return

	if is_facing(player.target_position):
		for i in range(shots_per_attack):
			var hit_chance = get_hit_chance(distance_to_player)
			hit_chance += accuaracy_modifier_linear
			var deleta_x = abs(player.global_transform.origin.x - self.global_transform.origin.x)
			var delta_z = abs(player.global_transform.origin.z - self.global_transform.origin.z)
			var different_x = deleta_x > GRID_SIZE * .1
			var different_z = delta_z > GRID_SIZE * .1
			if different_x and different_z:
				await miss(self.global_transform.origin - self.global_basis.z * GRID_SIZE * 5)
			elif randf() < hit_chance:
				await attack(player)
			else:
				await miss(player.global_transform.origin)
	else:
		rotate_towards(player.target_position)

func rotate_towards(point: Vector3, origin = self.target_position):
	var direction_to_target = (point - origin).normalized()
	var current_forward = self.target_rotation.z
	var go_left = current_forward.cross(direction_to_target).y > 0
	var rotation_amount = PI / 2
	if not go_left:
		rotation_amount = -rotation_amount
	self.target_rotation = self.target_rotation.rotated(Vector3.UP, rotation_amount)
	wait_time = 0.1

func is_facing(point: Vector3, origin = self.target_position) -> bool:
	var direction_to_target = (point - origin).normalized()
	var current_forward = self.target_rotation.z
	var angle_to_target = current_forward.angle_to(direction_to_target)
	return abs(angle_to_target) < PI / 8  # Consider facing if within 22.5 degrees

func attack(player: Player):
	await shoot_at(player.global_transform.origin, player.damage)

func miss(target_position: Vector3):
	var delta = target_position - self.global_transform.origin
	var miss_direction = delta.cross(
		Vector3.UP
	).normalized()
	miss_direction = miss_direction.rotated(delta.normalized(), PI*2 * randf_range(-1, 1))  # Add some random spread
	await shoot_at(target_position + miss_direction * GRID_SIZE * .5, false)
		

func shoot_at(target_position: Vector3, allow_damage = true):
	enemy_shoot_sfx.play()
	if Globals.within_range_of_enemy:
		Globals.in_combat = true
	wait_time = .8
	decaying_shot_count += 1

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

	
	var raygun_ray = PhysicsRayQueryParameters3D.new()
	raygun_ray.from = gun_node.global_transform.origin
	raygun_ray.to = target_position
	raygun_ray.exclude = [self, $StaticBody3D]
	

	var hit_pos = target_position
	var ragun_col = get_world_3d().direct_space_state.intersect_ray(raygun_ray)
	if ragun_col and ragun_col.collider and allow_damage:
		hit_pos = ragun_col.position
		var shootable = ragun_col.collider as Shootable
		if shootable and shootable.has_method("on_shot"):
			shootable.on_shot()

	var length = global_transform.origin.distance_to(hit_pos)
	var process_material: ParticleProcessMaterial = laser_particles_node.process_material
	process_material.emission_shape_scale = Vector3(0.05, 0.05, length)
	process_material.emission_shape_offset = Vector3(0, 0, -length)
	laser_particles_node.amount = int(length * 100)
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

	if max(abs(deltaX), abs(deltaZ)) > 6 * GRID_SIZE:
		return false
	
	var raygun_ray = PhysicsRayQueryParameters3D.new()
	raygun_ray.from = origin
	raygun_ray.to = target_position
	raygun_ray.exclude = [self, $StaticBody3D]
	

	var ragun_col = get_world_3d().direct_space_state.intersect_ray(raygun_ray)
	if ragun_col and ragun_col.collider:
		if ragun_col.position.distance_to(target_position) < GRID_SIZE * .5:
			return true

	return false
		



func _on_static_body_3d_shot() -> void:
	health -= 1
	iframes = 0.8
	static_change_cooldown = 0.05
	if health <= 0:
		enemy_hit_sfx.play()
		died.emit()
		self.queue_free()
		var shard: DeadEnemy = dead_scene.instantiate()
		get_parent().add_child(shard)
		shard.global_transform = self.global_transform
		shard.knockback((Globals.getPlayer().global_transform.origin - self.global_transform.origin).normalized(), -4)
	else:
		var headNode: EnemySpring = $EnemyTorso/EnemyHead
		var knockbackDir = (Globals.getPlayer().global_transform.origin - self.global_transform.origin).normalized()
		headNode.knockback(knockbackDir, -65)
		self.velocity += knockbackDir * -15
		enemy_hit_sfx.play()
