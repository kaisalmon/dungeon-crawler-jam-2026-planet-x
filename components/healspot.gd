extends MeshInstance3D

var cooldown = 0.0

func _process(delta):
	cooldown = max(0.0, cooldown - delta)
	var player = Globals.getPlayer()
	if player.global_position.distance_to(self.global_position) < player.GRID_SIZE:
		print(player.health, player.max_health)
		if cooldown <= 0.0 and player.health < player.max_health:
			player.health += 1
			cooldown = 1.0
			# sfx(heal)
	else:
		cooldown = 0.0
