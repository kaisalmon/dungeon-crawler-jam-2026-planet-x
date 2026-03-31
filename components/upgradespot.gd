extends MeshInstance3D

var t = 0.0
var picked_up = false

enum UpgradeType {
	GUN,
	SHIELD,
	HEALTH
}

@export var upgrade_type: UpgradeType = UpgradeType.GUN
func _ready():
	self.material_override = self.material_override.duplicate()

func _process(delta):
	t += delta
	for child in get_children():
		if child is MeshInstance3D:
			child.position.y = 0.1 * sin(t) + 0.7
			child.rotation.y = t * 1.7
			child.visible = false
	
	if not picked_up:
		if upgrade_type == UpgradeType.GUN:
			$Gun.visible = true
		elif upgrade_type == UpgradeType.SHIELD:
			$Shield.visible = true
		elif upgrade_type == UpgradeType.HEALTH:
			$Health.visible = true

	if picked_up: 
		return

	var player = Globals.getPlayer()
	if player.global_position.distance_to(self.global_position) < player.GRID_SIZE * 0.6:
		picked_up = true
		for child in get_children():
			child.queue_free()
			# Remove shader_parameter/texture_emission 
		self.material_override.set("shader_parameter/texture_emission", null)
		on_upgrade()

func on_upgrade():
	var player: Player = Globals.getPlayer()
	if upgrade_type == UpgradeType.GUN:
		player.has_gun_upgrade = true
		#SFX (Gun Pickup)
	if upgrade_type == UpgradeType.SHIELD:
		player.max_shields += 1
		player.shield_cooldown = 0.3
		#SFX (Shield Pickup)
	if upgrade_type == UpgradeType.HEALTH:
		player.max_health += 1
		player.health += 1
		#SFX (Health Pickup)
