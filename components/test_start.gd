extends Marker3D

@export var invincible = false
@export var health = 3
@export var shields = 1

func _ready():
    if not self.visible:
        return
    Globals.test_start = self
    var player = Globals.getPlayer()
    player.global_transform.origin = self.global_transform.origin
    player.global_transform.basis = self.global_transform.basis
    player.target_position = self.global_transform.origin
    player.target_rotation = self.global_transform.basis
    player.health = health
    player.max_health = health
    player.shields = shields
    player.max_shields = shields
    player.invincible = invincible
    player.has_gun_upgrade = true