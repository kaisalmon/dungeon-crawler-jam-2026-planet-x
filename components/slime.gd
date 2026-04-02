extends CollisionOverride

func _process(delta: float) -> void:
    var global_time = Time.get_ticks_msec() / 1000.0
    var x = sin(global_time) * 0.08
    var y = cos(global_time * 0.82) * 0.04
    material_override.set("shader_parameter/uv1_offset", Vector3(x, y, 0))

# Called by GridEntity when a collision with this Mesh's CollisionShape blocks normal movement
func can_entity_move_into(entity: GridEntity, _from_position: Vector3, _to_position: Vector3) -> bool:
    if not entity.is_player:
        return false
    return true


func can_entity_move_ontop(entity: GridEntity, _position: Vector3) -> bool:
    if not entity.is_player:
        return false
    return true

func can_entity_move_off(_entity: GridEntity, _from_position: Vector3, _to_position: Vector3, original_result: bool) -> bool:
    return original_result


# Called when an entity has moved into this collision override, if true normal behavior is skipped
func on_entity_move_into(entity: GridEntity, _from_position: Vector3, new_pos: Vector3) -> bool:
    return false

# Called when an entity has moved ontop of this collision override, if true normal behavior is skipped
func on_entity_move_ontop(entity: GridEntity, _from_position: Vector3, new_pos: Vector3) -> bool:
    entity.slime_count += 1
    return false

# Called when an entity has moved off of this collision override, if true normal behavior is skipped
func on_entity_move_off(entity: GridEntity, from_position: Vector3, to_position: Vector3) -> bool:
    entity.slime_count = max(0, entity.slime_count - 1)
    return false

