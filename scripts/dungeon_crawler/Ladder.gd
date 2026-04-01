extends CollisionOverride

# Called by GridEntity when a collision with this Mesh's CollisionShape blocks normal movement
func can_entity_move_into(_entity: GridEntity, _from_position: Vector3, _to_position: Vector3) -> bool:
	return true

func can_entity_move_ontop(_entity: GridEntity, _position: Vector3) -> bool:
	return true

func can_entity_move_off(_entity: GridEntity, _from_position: Vector3, _to_position: Vector3, original_result: bool) -> bool:
	return original_result

# Called when an entity has moved into this collision override, if true normal behavior is skipped
func on_entity_move_into(entity: GridEntity, from_position: Vector3, new_pos: Vector3) -> bool:
	var dir = new_pos - from_position
	var moving_dot = dir.normalized().dot(self.global_basis.z.normalized())
	if moving_dot > -0.9:
		return true # Only works as a ladder if you use it in the right direction

	if entity is Player:
		var player = entity as Player
		player.in_cutscene = true
	entity.is_moving = true

	var facing_dot = entity.global_basis.z.dot(self.global_basis.z.normalized())
	if facing_dot > -0.9:
		entity.target_rotation = self.global_basis.get_rotation_quaternion()
		await get_tree().create_timer(0.1).timeout

	entity.target_position = from_position - self.global_basis.z.normalized() * entity.GRID_SIZE / 4.0
	await get_tree().create_timer(.2).timeout
	entity.target_position = from_position + Vector3(0, entity.GRID_SIZE, 0)  - self.global_basis.z.normalized() * entity.GRID_SIZE / 2.5
	await get_tree().create_timer(0.3).timeout
	entity.target_position = new_pos + Vector3(0, entity.GRID_SIZE, 0)


	if entity is Player:
		var player = entity as Player
		player.in_cutscene = false
	entity.on_move_success()
	return true

# Called when an entity has moved ontop of this collision override, if true normal behavior is skipped
func on_entity_move_ontop(entity: GridEntity, _from_position: Vector3, new_pos: Vector3) -> bool:
	if entity is Player:
		var player = entity as Player
		player.in_cutscene = true
	entity.is_moving = true

	var dot = entity.global_basis.z.dot(self.global_basis.z.normalized())
	if dot > -0.9:
		# Not aligne, need to rotate first
		entity.target_rotation = self.global_basis.get_rotation_quaternion()
		await get_tree().create_timer(0.1).timeout

	entity.target_position = _from_position + self.global_basis.z.normalized() * entity.GRID_SIZE / 4.0
	await get_tree().create_timer(.2).timeout
	entity.target_position = _from_position - Vector3(0, entity.GRID_SIZE, 0)  + self.global_basis.z.normalized() * entity.GRID_SIZE / 2
	await get_tree().create_timer(0.3).timeout
	entity.target_position = new_pos - Vector3(0, entity.GRID_SIZE, 0)


	if entity is Player:
		var player = entity as Player
		player.in_cutscene = false
	entity.on_move_success()
	return true

# Called when an entity has moved off of this collision override, if true normal behavior is skipped
func on_entity_move_off(entity: GridEntity, _from_position: Vector3, to_position: Vector3) -> bool:
	return false
