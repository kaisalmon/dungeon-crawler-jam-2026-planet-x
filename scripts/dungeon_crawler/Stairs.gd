extends CollisionOverride

# Called by GridEntity when a collision with this Mesh's CollisionShape blocks normal movement
func can_entity_move_into(_entity: GridEntity, from_position: Vector3, to_position: Vector3) -> bool:
    if not _entity.is_player:
        return false
    var move_dir = (to_position - from_position).normalized()
    var dot = move_dir.dot(self.global_basis.z)
    if dot > 0.8:
        return true  # Moving "up" the stairs
    elif dot < -0.8:
        return true  # Moving "down" the stairs
    return false


func can_entity_move_ontop(_entity: GridEntity, _position: Vector3) -> bool:
    if not _entity.is_player:
        return false
    var move_dir = (_position - _entity.global_transform.origin).normalized()
    var dot = move_dir.dot(self.global_basis.z)
    if dot > 0.8:
        return true  # Moving "up" the stairs
    elif dot < -0.8:
        return true  # Moving "down" the stairs
    return false

func can_entity_move_off(_entity: GridEntity, from_position: Vector3, to_position: Vector3, original_result: bool) -> bool:
    var move_dir = (to_position - from_position).normalized()
    var dot = move_dir.dot(self.global_basis.z)
    if dot > 0.8:
        return true  # Moving "up" the stairs
    elif dot < -0.8:
        return true  # Moving "down" the stairs
    return original_result


# Called when an entity has moved into this collision override, if true normal behavior is skipped
func on_entity_move_into(entity: GridEntity, _from_position: Vector3, new_pos: Vector3) -> bool:
    entity.target_position = new_pos + Vector3(0, entity.GRID_SIZE / 2, 0)
    entity.is_moving = true
    entity.on_move_success()

    return true

# Called when an entity has moved ontop of this collision override, if true normal behavior is skipped
func on_entity_move_ontop(entity: GridEntity, _from_position: Vector3, new_pos: Vector3) -> bool:
    entity.target_position = new_pos - Vector3(0, entity.GRID_SIZE/2, 0)
    entity.is_moving = true
    entity.on_move_success()

    return true

# Called when an entity has moved off of this collision override, if true normal behavior is skipped
func on_entity_move_off(entity: GridEntity, from_position: Vector3, to_position: Vector3) -> bool:
    var move_dir = (to_position - from_position).normalized()
    var dot = move_dir.dot(self.global_basis.z)
    if dot > 0.8:
        # Moving "up" the stairs
        entity.target_position = to_position - Vector3(0, entity.GRID_SIZE / 2, 0)
    elif dot < -0.8:
        # Moving "down" the stairs
        entity.target_position = to_position + Vector3(0, entity.GRID_SIZE / 2, 0)
    print(dot)
    entity.is_moving = true
    entity.on_move_success()
    return true
