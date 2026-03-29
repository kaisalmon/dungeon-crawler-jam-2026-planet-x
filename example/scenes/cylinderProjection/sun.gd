extends DirectionalLight3D


func _process(_delta):
	var player = Globals.getPlayer()

	self.look_at(player.global_transform.origin, Vector3.UP)
