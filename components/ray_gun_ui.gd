extends TextureRect

@export var cool_gradient: Gradient
@export var hot_gradient: Gradient

func _process(_delta):
	var player = Globals.getPlayer()
	if player.raygun_overheated:
		self.texture = load("res://ui/ui_bottom_overheat.png")
	else:
		self.texture = load("res://ui/ui_bottom.png")

	var heat_guage: TextureRect = $"HeatGuage"
	heat_guage.size.x = player.raygun_heat / 100.0 * 54

	if player.raygun_overheated:
		self.modulate = hot_gradient.sample(player.raygun_heat / 100.0)
	else:
		self.modulate = cool_gradient.sample(player.raygun_heat / 100.0)
