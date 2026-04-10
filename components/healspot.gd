extends MeshInstance3D

var cooldown = 0.0
var save_cooldown = 0.0

@onready var progress_save: AudioStreamPlayer = $ProgressSave
@onready var health_increase: AudioStreamPlayer = $HealthIncrease

func _process(delta):
	cooldown = max(0.0, cooldown - delta)
	save_cooldown = max(0.0, save_cooldown - delta)
	var player = Globals.getPlayer()
	if player.global_position.distance_to(self.global_position) < player.GRID_SIZE * .55:
		if cooldown <= 0.0:
			if Globals.in_combat:
				Globals.tutorialize("Cannot heal during combat!")
			else:
				if player.health < player.max_health:
					player.health += 1
					cooldown = 1.0
					health_increase.play()
				if save_cooldown <= 0.0:
					progress_save.play()
					Globals.save()
					
					Analytics.track("progress_saved",{
						"x": player.global_position.x,
						"y": player.global_position.y,
						"z": player.global_position.z,
						"max_health": player.max_health,
						"max_shields": player.max_shields,
						"id": str(get_path()),
					})
					save_cooldown = 10.0
	else:
		cooldown = 0.5
