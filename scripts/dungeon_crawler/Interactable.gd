extends Node3D

@export var interaction_range: float = 2.0
signal interacted

var meshes: Array

func _ready():
	# Find all MeshInstances3D in the node
	meshes = Globals.getAllChildren(self).filter(func(child):
		return child is MeshInstance3D
	)


func _process(_delta):
	var player = get_tree().get_first_node_in_group("player")

	if is_player_in_range(player) and is_player_looking(player):
		apply_highlight()
		if Input.is_action_just_pressed("ui_accept"):
			interact()
	else:
		remove_highlight()

func is_player_in_range(player: Node3D) -> bool:
	return global_position.distance_to(player.global_position) <= interaction_range

func is_player_looking(player: Node3D) -> bool:
	if player.is_moving or player.in_cutscene or player.is_turning:
		return false
	var distance = global_position.distance_to(player.global_position)

	if distance > 10:
		return false

	var distance_vector = player.global_position - global_position
	var player_look_direction = player.target_rotation.z.normalized()
	var dot_product = distance_vector.normalized().dot(player_look_direction)
	var is_looking_at = dot_product > .70

	if not is_looking_at:
		return false

	var ray_params = PhysicsRayQueryParameters3D.new()
	ray_params.from = player.global_position
	ray_params.to = global_position
	ray_params.exclude = [player]
	var collision = get_world_3d().direct_space_state.intersect_ray(ray_params)
	if collision:
		var node = collision.collider
		while node:
			if node == self:
				return true
			node = node.get_parent()
		return false

	return true

func apply_highlight():
	meshes = Globals.getAllChildren(self).filter(func(child):
		return child is MeshInstance3D
	)

	var owner_node = self as Node3D
	if owner_node is MeshInstance3D:
		meshes.append(owner_node)
	for mesh in meshes:
		if mesh is MeshInstance3D:
			mesh.material_overlay = (preload("res://materials/focus_outline.tres"))
	
func remove_highlight():
	# Get all MeshInstance3D children
	meshes = Globals.getAllChildren(self).filter(func(child):
		return child is MeshInstance3D
	)
	var owner_node = self as Node3D
	if owner_node is MeshInstance3D:
		meshes.append(owner_node)
	for mesh in meshes:
		if mesh is MeshInstance3D:
			mesh.material_overlay = null



func interact():
	emit_signal("interacted")
