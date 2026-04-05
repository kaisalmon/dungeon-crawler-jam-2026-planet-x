extends Node



func _process(_delta):
	var player = Globals.getPlayer()
	RenderingServer.global_shader_parameter_set("planet_radius", 30.0)
	RenderingServer.global_shader_parameter_set("curve_origin", player.global_position)
