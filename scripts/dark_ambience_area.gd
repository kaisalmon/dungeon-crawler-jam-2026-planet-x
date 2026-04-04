extends Area3D

var active = false
var ambient_color

func _ready():
	ambient_color = get_world_3d().environment.ambient_light_color
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node3D) -> void:
	if not body.get_parent().is_in_group("player"):
		return
	active = true

func _on_body_exited(body: Node3D) -> void:
	if not body.get_parent().is_in_group("player"):
		return
	active = false

func _process(delta: float) -> void:
	var world_environment = get_world_3d().environment
	var target_color = Color(0.0, 0.0, 0.0) if active else ambient_color
	world_environment.ambient_light_color = target_color
