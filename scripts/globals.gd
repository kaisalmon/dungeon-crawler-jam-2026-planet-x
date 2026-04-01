extends Node

var fovSetting: int = 100


var in_combat = false
var within_range_of_enemy = false

func _ready() -> void:
	var timer = Timer.new()
	timer.wait_time = 3
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_check_proximity_to_enemies)

func _check_proximity_to_enemies() -> void:
	var player = getPlayer()
	var enemies = get_tree().get_nodes_in_group("enemies")
	within_range_of_enemy = false
	for enemy in enemies:
		if player.global_transform.origin.distance_to(enemy.global_transform.origin) < 10*player.GRID_SIZE:
			within_range_of_enemy = true
			break
	if not within_range_of_enemy:
		in_combat = false

func _process(_delta: float) -> void:
	pass


func getAllChildren(node, results=[]):
	for N in node.get_children():
		results.append(N)
		if N.get_child_count() > 0:
			getAllChildren(N, results)
	return results

func easeInOutCubic(x: float) -> float:
	if x < 0.5:
		return 4 * x * x * x
	else:
		return 1 - pow(-2 * x + 2, 3) / 2

func getPlayer() -> Player:
	return get_tree().get_first_node_in_group("player")


var queue: Array = []
var tutorial_strings: Array = []
func say(text: String) -> void:
	queue.append(text)

func tutorialize(text: String) -> void:
	if text in tutorial_strings:
		return
	tutorial_strings.append(text)
	say(text)