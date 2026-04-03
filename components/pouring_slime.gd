extends MeshInstance3D

func _process(delta: float) -> void:
	var global_time = Time.get_ticks_msec() / 1000.0
	var y = (-global_time * 0.2)
	y = fmod(y, 1)
	y *= 32.0
	y = floor(y)
	y /= 32.0
	material_override.set("shader_parameter/uv1_offset", Vector3(0, y, 0))
