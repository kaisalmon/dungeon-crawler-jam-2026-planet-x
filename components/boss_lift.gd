extends CollisionOverride

# Called by GridEntity when a collision with this Mesh's CollisionShape blocks normal movement
func can_entity_move_into(_entity: GridEntity, from_position: Vector3, to_position: Vector3) -> bool:
    return false

func can_entity_move_ontop(_entity: GridEntity, _position: Vector3) -> bool:
    if not _entity.is_player:
        return false
    return true

func can_entity_move_off(_entity: GridEntity, from_position: Vector3, to_position: Vector3, original_result: bool) -> bool:
    return true


# Called when an entity has moved into this collision override, if true normal behavior is skipped
func on_entity_move_into(entity: GridEntity, _from_position: Vector3, new_pos: Vector3) -> bool:
    return false

# Called when an entity has moved ontop of this collision override, if true normal behavior is skipped
func on_entity_move_ontop(entity: GridEntity, _from_position: Vector3, new_pos: Vector3) -> bool:
    entity.target_position = new_pos
    entity.is_moving = true
    entity.on_move_success()
    print("moved ontop of lift")
    return true

# Called when an entity has moved off of this collision override, if true normal behavior is skipped
func on_entity_move_off(entity: GridEntity, from_position: Vector3, to_position: Vector3) -> bool:
    print("moved off of lift") 
    return false
    
