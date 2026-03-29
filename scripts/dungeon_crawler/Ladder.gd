extends CollisionOverride

# Called by GridEntity when a collision with this Mesh's CollisionShape blocks normal movement
func can_entity_move_into(_entity: GridEntity, _from_position: Vector3, _to_position: Vector3) -> bool:
	return true

func can_entity_move_ontop(_entity: GridEntity, _position: Vector3) -> bool:
	return true

func can_entity_move_off(_entity: GridEntity, _from_position: Vector3, _to_position: Vector3, original_result: bool) -> bool:
	return original_result

# Called when an entity has moved into this collision override, if true normal behavior is skipped
func on_entity_move_into(entity: GridEntity, _from_position: Vector3, new_pos: Vector3) -> bool:
	if entity is Player:
		var player = entity as Player
		player.in_cutscene = true
	entity.is_moving = true

	var dot = entity.basis.z.dot(self.basis.z.normalized())
	if dot > -0.9:
		entity.target_rotation = self.global_basis.get_rotation_quaternion()
		await get_tree().create_timer(0.1).timeout

	entity.target_position = _from_position - self.basis.z.normalized() * entity.GRID_SIZE / 2.5
	await get_tree().create_timer(.2).timeout
	entity.target_position = _from_position + Vector3(0, entity.GRID_SIZE, 0)  - self.basis.z.normalized() * entity.GRID_SIZE / 2.5
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

	var dot = entity.basis.z.dot(self.basis.z.normalized())
	if dot > -0.9:
		# Not aligne, need to rotate first
		entity.target_rotation = self.global_basis.get_rotation_quaternion()
		await get_tree().create_timer(0.1).timeout

	entity.target_position = _from_position + self.basis.z.normalized() * entity.GRID_SIZE / 2
	await get_tree().create_timer(.2).timeout
	entity.target_position = _from_position - Vector3(0, entity.GRID_SIZE, 0)  + self.basis.z.normalized() * entity.GRID_SIZE / 2
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
