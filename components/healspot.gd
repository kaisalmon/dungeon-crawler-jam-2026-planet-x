extends MeshInstance3D

var cooldown = 0.0
var save_cooldown = 0.0

@onready var progress_save: AudioStreamPlayer = $ProgressSave

func _process(delta):
	cooldown = max(0.0, cooldown - delta)
	var player = Globals.getPlayer()
	if player.global_position.distance_to(self.global_position) < player.GRID_SIZE * .55:
		if cooldown <= 0.0:
			if Globals.in_combat:
				Globals.tutorialize("Cannot heal during combat!")
			else:
				if player.health < player.max_health:
					player.health += 1
					cooldown = 1.0
					# sfx(heal)
				if save_cooldown <= 0.0:
					progress_save.play()
					Globals.save()
					save_cooldown = 10.0
	else:
		cooldown = 0.5
