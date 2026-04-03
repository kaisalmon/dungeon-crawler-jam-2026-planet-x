extends Node



func _process(_delta):
	var player = Globals.getPlayer()
	RenderingServer.global_shader_parameter_set("planet_radius", 30.0)
	RenderingServer.global_shader_parameter_set("curve_origin", player.global_position)


func _on_boss_died() -> void:
	Globals.say("The master-AI has been defeated!")
	Globals.say("Captain Raygun has once again saved the day!")
	await get_tree().create_timer(6.0).timeout
	# TODO roll credits
	# For now, just reload the scene
	get_tree().reload_current_scene()
