extends Node

var fovSetting: int = 100

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass
	# var vp = get_viewport()
	# if vp:
	# 	var cam = vp.get_camera_3d()
	# 	if cam:
	# 		cam.fov = fovSetting

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