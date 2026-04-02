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
	timer.timeout.connect(_print_fps)

func _check_proximity_to_enemies() -> void:
	var player = getPlayer()
	var enemies = get_tree().get_nodes_in_group("enemies")
	within_range_of_enemy = false
	for enemy in enemies:
		if player.global_transform.origin.distance_to(enemy.global_transform.origin) < 8*player.GRID_SIZE:
			within_range_of_enemy = true
			break
	if not within_range_of_enemy:
		in_combat = false

func _print_fps() -> void:
	print("FPS: ", Engine.get_frames_per_second())

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

func save():
	var save_data = {}
	var saveables = get_tree().get_nodes_in_group("saveable")
	for saveable in saveables:
		save_data[saveable.get_path()] = saveable.save()
	var save_name = "autosave"
	var save_file = FileAccess.open("user://" + save_name + ".save", FileAccess.WRITE)
	if save_file:
		var json_string = JSON.stringify(save_data)

		save_file.store_line(json_string)
		say("Progress saved.")
	else:
		say("Error saving progress.")

func load():
	var save_name = "autosave"
	var save_file = FileAccess.open("user://" + save_name + ".save", FileAccess.READ)
	if save_file:
		var json_string = save_file.get_as_text()
		var save_data = JSON.parse_string(json_string)
		for path in save_data.keys():
			var node = get_node(path)
			if node and node.has_method("load"):
				node.load(save_data[path])
			else:
				print("No node or load method for path: ", path)
	else:
		print("No save file found.")
