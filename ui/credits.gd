extends VBoxContainer

@export var scroll_speed: float = 15.0
const AMBIENT_FADE_DELAY: float = 20.0
const AMBIENT_FADE_TIME: float = 12.0

var _scrolling: bool = false
var _elapsed: float = 0.0
var _ambient_initial: float = 0.0
var _world_env: WorldEnvironment = null

func _ready() -> void:
	var label := find_child("Label") as RichTextLabel
	if label:
		label.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))

func start() -> void:
	await get_tree().process_frame
	var music_manager = get_tree().get_nodes_in_group("MusicManager")[0]
	music_manager.play_music(music_manager.credits_music)
	self.visible = true
	Globals.getPlayer().has_gun_upgrade = false
	position.y = get_viewport_rect().size.y
	_scrolling = true
	_world_env = get_tree().root.find_child("WorldEnvironment", true, false)
	if _world_env and _world_env.environment:
		_ambient_initial = _world_env.environment.ambient_light_energy
	var overlay = get_tree().root.find_child("Overlay", true, false)
	if overlay:
		var tween = create_tween()
		tween.tween_property(overlay, "modulate:a", 0.0, 1.5)

func _process(delta: float) -> void:
	if not _scrolling:
		return

	var fast_forward := Input.is_action_pressed("shoot") or Input.is_action_pressed("ui_accept")
	Engine.time_scale = 4.0 if fast_forward else 1.0

	_elapsed += delta
	position.y -= scroll_speed * delta

	# Fade ambient light after delay
	var fade_progress: float = (_elapsed - AMBIENT_FADE_DELAY) / AMBIENT_FADE_TIME
	if fade_progress > 0.0 and _world_env and _world_env.environment:
		_world_env.environment.ambient_light_energy = _ambient_initial * (1.0 - min(fade_progress, 1.0))

	if position.y + size.y < 0:
		_scrolling = false
		_finish()

func _finish() -> void:
	var overlay = get_tree().root.find_child("Overlay", true, false)
	if overlay:
		var tween = create_tween()
		tween.tween_property(overlay, "modulate:a", 1.0, 1.5)
		await tween.finished
	Engine.time_scale = 1.0
	if _world_env and _world_env.environment:
		_world_env.environment.ambient_light_energy = _ambient_initial
	get_tree().reload_current_scene()
