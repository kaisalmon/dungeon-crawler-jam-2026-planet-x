extends Label

var timer = 0.0
var duration = 3.5
var _current_item: Dictionary = {}

const WORDS_PER_MINUTE = 130.0
const MIN_DURATION = 2.0

func _duration_for(msg: String) -> float:
	var word_count = msg.strip_edges().split(" ", false).size()
	return maxf(MIN_DURATION, word_count / (WORDS_PER_MINUTE / 60.0))

var _orig_anchor_top: float
var _orig_offset_top: float
var _orig_vertical_alignment: VerticalAlignment


func _ready() -> void:
	self.text = ""
	_orig_anchor_top = anchor_top
	_orig_offset_top = offset_top
	_orig_vertical_alignment = vertical_alignment as VerticalAlignment


func _set_centered_layout(centered: bool) -> void:
	if centered:
		anchor_top = 0.0
		offset_top = 0.0
		offset_bottom = 0.0
		vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	else:
		anchor_top = _orig_anchor_top
		offset_top = _orig_offset_top
		vertical_alignment = _orig_vertical_alignment


func _process(delta: float) -> void:
	var queue = Globals.queue
	var prev_timer = timer
	timer -= delta
	var FADE_DURATION = 0.3

	if prev_timer > 0.0 and timer <= 0.0:
		if _current_item.has("token"):
			_current_item["token"].done.emit()
		_current_item = {}

	if timer <= 0.0 and queue.size() > 0:
		_current_item = queue.pop_front()
		self.text = _current_item["text"]
		_set_centered_layout(_current_item.get("centered", false))
		duration = _duration_for(self.text)
		timer = duration

	var alpha = 1.0
	if timer < FADE_DURATION:
		alpha = timer / FADE_DURATION
	elif timer > duration - FADE_DURATION:
		alpha = (duration - timer) / FADE_DURATION
	self.modulate.a = alpha
