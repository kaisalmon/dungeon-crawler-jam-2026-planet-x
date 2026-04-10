extends Area3D

var active = false
var ambient_color
var transition = 0.0
var directional_light_strength
var sun_strength
var children_light_strengths = []
var children_lights = []

func _ready():
	ambient_color = get_world_3d().environment.ambient_light_color
	directional_light_strength = %DirectionalLight3D.light_energy
	sun_strength = %Sun.light_energy
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	for child in get_children():
		if child is Light3D:
			children_lights.append(child)
			children_light_strengths.append(child.light_energy)

func _on_body_entered(body: Node3D) -> void:
	print("entered", body.name)
	if not body.get_parent().is_in_group("player"):
		return
	active = true

func _on_body_exited(body: Node3D) -> void:
	print("exited", body.name)
	if not body.get_parent().is_in_group("player"):
		return
	active = false

func _process(delta: float) -> void:
	if Globals.is_game_over:
		return
	transition = move_toward(transition, 1.0 if active else 0.0, delta)
	var world_environment = get_world_3d().environment
	world_environment.ambient_light_color = ambient_color.lerp(ambient_color * 0.4, transition)

	var global_directional_light = %DirectionalLight3D
	global_directional_light.light_energy = directional_light_strength * (1.0 - transition)

	for i in range(len(children_lights)):
		children_lights[i].light_energy = children_light_strengths[i] * (transition)

	var sun = %Sun
	sun.light_energy = sun_strength * (1.0 - transition)
