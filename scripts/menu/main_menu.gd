extends Node

@export var main_menu_container: Container
@export var options_container: Container

signal new_game_pressed
signal continue_pressed

var new_game_button: Button
var continue_button: Button
var settings_button: Button
var quit_button: Button
var credits_button: Button

var done: bool = false
var overlay_target: float = 0.0
var _intro_playing: bool = false

@onready var button_click_sfx: AudioStreamPlayer = $ButtonClickSFX


const SAVE_FILE_PATH = "user://autosave.save"
const PREFS_FILE_PATH = "user://preferences.save"

func _ready():
	self.done = false
	self.overlay_target = 0.0
	var music_manager = get_tree().get_nodes_in_group("MusicManager")[0]
	music_manager.reset_state()
	music_manager.menu_music.play()
	var player = Globals.getPlayer()
	player.in_cutscene = true
	RenderingServer.global_shader_parameter_set("use_camera_as_curve_origin", true)

	# Step 1: Create buttons for "New Game", "Continue", and "Settings"
	new_game_button = Button.new()
	new_game_button.text = "New Game"
	main_menu_container.add_child(new_game_button)

	continue_button = Button.new()
	continue_button.text = "Continue"
	main_menu_container.add_child(continue_button)

	settings_button = Button.new()
	settings_button.text = "Settings"
	main_menu_container.add_child(settings_button)

	
	credits_button = Button.new()
	credits_button.text = "Credits"
	main_menu_container.add_child(credits_button)

	if FileAccess.file_exists(SAVE_FILE_PATH):
		continue_button.disabled = false
		continue_button.focus_mode = Control.FOCUS_ALL
		continue_button.grab_focus()
	else:
		continue_button.disabled = true
		continue_button.focus_mode = Control.FOCUS_NONE
		new_game_button.grab_focus()

	if OS.get_name() != "Web":
		quit_button = Button.new()
		quit_button.text = "Quit"
		main_menu_container.add_child(quit_button)

	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

	options_container.visible = false
	options_container.process_mode = Node.PROCESS_MODE_DISABLED


func has_seen_intro() -> bool:
	if not FileAccess.file_exists(PREFS_FILE_PATH):
		return false
	var file = FileAccess.open(PREFS_FILE_PATH, FileAccess.READ)
	if not file:
		return false
	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		return data.get("intro_seen", false)
	return false

func mark_intro_seen() -> void:
	var data: Dictionary = {}
	if FileAccess.file_exists(PREFS_FILE_PATH):
		var read_file = FileAccess.open(PREFS_FILE_PATH, FileAccess.READ)
		if read_file:
			var parsed = JSON.parse_string(read_file.get_as_text())
			if parsed is Dictionary:
				data = parsed
	data["intro_seen"] = true
	var write_file = FileAccess.open(PREFS_FILE_PATH, FileAccess.WRITE)
	if write_file:
		write_file.store_line(JSON.stringify(data))

func _play_intro() -> void:
	main_menu_container.visible = false
	$Logo.visible = false
	overlay_target = 1.0

	# Fade out menu music
	var music_manager = get_tree().get_nodes_in_group("MusicManager")[0]
	await music_manager.music_stop()

	await Globals.say_centered(
"In 2056 scientists discovered a habitable sub-moon
orbiting Saturn's largest moon, Titan. Officially
designated Saturn VI-A, it was quickly nicknamed...")
	await Globals.say_centered(
"Planet X.")
	await Globals.say_centered(
"And so, by 2094 the North Atlantic Federation,
emboldened by recent advances in robotics,
established a small permanent colony on Planet X.")
	await Globals.say_centered(
"It took less than 3 years for the AI to have
replaced every task needed to keep the colony
running.  Once the Master AI had fully replaced
the human colonists...")
	await Globals.say_centered(
"It had them all killed. ")
	await Globals.say_centered(
"The year is 2101, and Captain Raygun has arrived
on Planet X.  His mission is simple.")
	await Globals.say_centered(
"Find the Master AI and destroy it.")
	mark_intro_seen()

func _on_new_game_pressed():
	if done or _intro_playing:
		return
	button_click_sfx.play()
	Analytics.begin_session()
	Analytics.track("new_game_started")
	Globals.in_lab_environment = false # Ensure this is reset when starting a new game from the main menu
	if not has_seen_intro():
		_intro_playing = true
		await _play_intro()
		_intro_playing = false
	start_game()

func _on_continue_pressed():
	button_click_sfx.play()
	Globals.load()
	Analytics.begin_session()
	Analytics.track("game_continued")
	start_game()

func start_game():
	var music_manager = get_tree().get_nodes_in_group("MusicManager")[0]
	music_manager.play_music(music_manager.gameplay_music)
	if done:
		return
	done = true
	overlay_target = 1.0
	await get_tree().create_timer(1.0).timeout
	overlay_target = 0.0
	var player = Globals.getPlayer()
	player.in_cutscene = false
	RenderingServer.global_shader_parameter_set("use_camera_as_curve_origin", false)
	self.get_parent().is_active = false
	self.get_parent().transition_to_player_camera(player.camera, 0)

func _on_settings_pressed():
	button_click_sfx.play()
	if done:
		return
	main_menu_container.visible = false
	$Logo.visible = false
	options_container.visible = true
	options_container.process_mode = Node.PROCESS_MODE_INHERIT

	# Focus the first focusable child in options container
	for child in options_container.get_children():
		if child is Control and child.focus_mode != Control.FOCUS_NONE:
			child.grab_focus()
			break

func _on_credits_pressed():
	button_click_sfx.play()
	if done:
		return
	self.get_parent().is_active = false
	main_menu_container.visible = false
	$Logo.visible = false
	Analytics.track("credits_viewed")
	Globals.end_game("credits")

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and options_container.visible:
		_go_back_to_main_menu()
		get_viewport().set_input_as_handled()

func _go_back_to_main_menu():
	options_container.visible = false
	options_container.process_mode = Node.PROCESS_MODE_DISABLED
	main_menu_container.visible = true
	$Logo.visible = true
	settings_button.grab_focus()
	

func _on_quit_pressed():
	button_click_sfx.play()
	get_tree().quit()


func _process(delta):
	if not done and Globals.test_start:
		_on_new_game_pressed()
	if done and not _intro_playing:
		self.modulate.a = lerp(self.modulate.a, 0.0, delta * 3)
		if self.modulate.a <= 0.01:
			self.visible = false
	if not Globals.is_game_over:
		var overlay_delta = overlay_target - %Overlay.modulate.a
		%Overlay.modulate.a += sign(overlay_delta) * delta
		%Overlay.modulate.a = max(0.0, min(1.0, %Overlay.modulate.a))


func _on_settings_back_pressed() -> void:
	button_click_sfx.play()
	_go_back_to_main_menu()
