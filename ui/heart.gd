extends Sprite2D

class_name PlayerUiHeart
var vis_full = true
var vis_shield = false

func _process(_delta):
	if vis_shield:
		if vis_full:
			self.texture = load("res://ui/healthshield.png")
		else:
			self.texture = load("res://ui/healthshieldempty.png")
	else:
		if vis_full:
			self.texture = load("res://ui/healthfull.png")
		else:
			self.texture = load("res://ui/healthempty.png")
