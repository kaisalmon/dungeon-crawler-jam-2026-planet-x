extends MeshInstance3D
class_name CollisionOverride

# Called by GridEntity when a collision with this Mesh's CollisionShape blocks normal movement
func can_entity_move_into(_entity: GridEntity, _from_position: Vector3, _to_position: Vector3) -> bool:
    return true

func can_entity_move_ontop(_entity: GridEntity, _position: Vector3) -> bool:
    return true

func can_entity_move_off(_entity: GridEntity, _from_position: Vector3, _to_position: Vector3, original_result: bool) -> bool:
    return original_result

# Called when an entity has moved into this collision override, if true normal behavior is skipped
func on_entity_move_into(_entity: GridEntity, _from_position: Vector3, _new_pos: Vector3) -> bool:
    return false

# Called when an entity has moved ontop of this collision override, if true normal behavior is skipped
func on_entity_move_ontop(_entity: GridEntity, _from_position: Vector3, _new_pos: Vector3) -> bool:
    return false

# Called when an entity has moved off of this collision override, if true normal behavior is skipped
func on_entity_move_off(_entity: GridEntity, _from_position: Vector3, _to_position: Vector3) -> bool:
    return false