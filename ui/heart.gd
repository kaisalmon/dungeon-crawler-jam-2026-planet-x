extends Sprite2D

class_name PlayerUiHeart
var vis_full = true

func _process(_delta):
    if vis_full:
        self.texture = load("res://ui/healthfull.png")
    else:
        self.texture = load("res://ui/healthempty.png")