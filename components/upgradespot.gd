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
	self.add_to_group("saveable")

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
		set_visually_picked_up()
		on_upgrade()

func set_visually_picked_up():
	for child in get_children():
		child.queue_free()
		# Remove shader_parameter/texture_emission 
	self.material_override.set("shader_parameter/texture_emission", null)

func on_upgrade():
	var player: Player = Globals.getPlayer()
	if upgrade_type == UpgradeType.GUN:
		player.has_gun_upgrade = true
		Globals.say("Trusty Raygun Mk. II acquired!")
		#SFX (Gun Pickup)
	if upgrade_type == UpgradeType.SHIELD:
		player.max_shields += 1
		player.shield_cooldown = 0.3
		if player.max_shields == 1:
			Globals.say("Shield Generator acquired!")
			Globals.say("Shields will automatically recharge")
			Globals.say("after not taking damage for a few seconds")
		else:
			Globals.say("Shield Generator upgraded!")
		#SFX (Shield Pickup)
	if upgrade_type == UpgradeType.HEALTH:
		player.max_health += 1
		player.health += 1
		Globals.say("Health increased!")
		#SFX (Health Pickup)

func save() -> Dictionary:
	var json = {
		"upgrade_type": upgrade_type,
		"picked_up": picked_up,
	}
	return json

func load(json: Dictionary) -> void:
	upgrade_type = json["upgrade_type"]
	picked_up = json["picked_up"]
	if picked_up:
		set_visually_picked_up()