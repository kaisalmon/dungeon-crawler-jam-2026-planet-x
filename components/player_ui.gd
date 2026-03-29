extends Sprite2D

var vis_health = 5
@export var heart_scene: PackedScene
var hearts = []

func _process(_delta):
	var player = Globals.getPlayer()
	while hearts.size() < player.max_health:
		var heart = heart_scene.instantiate()
		add_child(heart)
		heart.position = Vector2(-45 + hearts.size() * 20, -43)
		hearts.append(heart)

	while hearts.size() > player.max_health:
		var heart = hearts.pop_back()
		heart.queue_free()

	for i in range(player.max_health):
		var heart: PlayerUiHeart = hearts[i]
		heart.vis_full = i < player.health

	if player.iframes > 0 and fmod(player.iframes, 0.2) < 0.1:
		self.modulate = Color(1, 1, 1, 0)
	else:
		self.modulate = Color(1, 1, 1, 1)
	

	
