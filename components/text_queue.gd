extends Label

var timer = 0.0


func _ready() -> void:
	self.text = ""

func _process(delta: float) -> void:
	var queue = Globals.queue
	timer -= delta
	var DURATION = 2.0
	var FADE_DURATION = 0.3
	if timer <= 0.0 and queue.size() > 0:
		self.text = queue.pop_front() if queue.size() > 0 else ""
		timer = DURATION

	var alpha = 1.0
	if timer < FADE_DURATION:
		alpha = timer / FADE_DURATION
	elif timer > DURATION - FADE_DURATION:
		alpha = (DURATION - timer) / FADE_DURATION
	self.modulate.a = alpha
