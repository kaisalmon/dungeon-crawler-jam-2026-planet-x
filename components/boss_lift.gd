extends CollisionOverride

const UNITS = -2
const DROP_DURATION = 1.5
const RISE_DURATION = 1.2


var activated = false
var original_position: Vector3

func _ready():
	original_position = global_position

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
	if activated:
		return false
	entity.target_position = new_pos
	entity.is_moving = true
	entity.on_move_success()
	var player = Globals.getPlayer()
	player.in_cutscene = true
	await get_tree().create_timer(0.4).timeout
	entity.frozen = true

	var drop = GridEntity.gravity.normalized() * UNITS * GridEntity.GRID_SIZE
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", global_position + drop, DROP_DURATION)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(entity, "global_position", entity.target_position + drop, DROP_DURATION)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

	Globals.say("The master AI... he must be defeated!")
	
	await tween.finished
	entity.target_position = new_pos + drop
	player.in_cutscene = false
	entity.frozen = false
	return true

# Called when an entity has moved off of this collision override, if true normal behavior is skipped
func on_entity_move_off(entity: GridEntity, from_position: Vector3, to_position: Vector3) -> bool:
	return false
