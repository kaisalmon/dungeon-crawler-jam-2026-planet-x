extends StaticBody3D
class_name Shootable
signal shot

func on_shot():
	emit_signal("shot")
