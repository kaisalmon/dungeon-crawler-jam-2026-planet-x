extends Node

@export var main_menu_container: Container
@export var options_container: Container

signal new_game_pressed
signal continue_pressed

var new_game_button: Button
var continue_button: Button
var settings_button: Button
var quit_button: Button

var done: bool = false
var overlay_target: float = 0.0


const SAVE_FILE_PATH = "user://autosave.save"

func _ready():
	var music_manager = get_tree().get_nodes_in_group("MusicManager")[0]
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
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

	options_container.visible = false
	options_container.process_mode = Node.PROCESS_MODE_DISABLED


func _on_new_game_pressed():
	start_game()

func _on_continue_pressed():
	Globals.load()
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
	if done:
		return
	main_menu_container.visible = false
	options_container.visible = true
	options_container.process_mode = Node.PROCESS_MODE_INHERIT

	# Focus the first focusable child in options container
	for child in options_container.get_children():
		if child is Control and child.focus_mode != Control.FOCUS_NONE:
			child.grab_focus()
			break

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and options_container.visible:
		_go_back_to_main_menu()
		get_viewport().set_input_as_handled()

func _go_back_to_main_menu():
	var music_manager = get_tree().get_nodes_in_group("MusicManager")[0]
	music_manager.play_music(music_manager.menu_music)
	options_container.visible = false
	options_container.process_mode = Node.PROCESS_MODE_DISABLED
	main_menu_container.visible = true
	settings_button.grab_focus()
	

func _on_quit_pressed():
	get_tree().quit()


func _process(delta):
	if done:
		self.modulate.a = lerp(self.modulate.a, 0.0, delta * 3)
		if self.modulate.a <= 0.01:
			self.visible = false
	var overlay_delta = overlay_target - self.modulate.a
	%Overlay.modulate.a += sign(overlay_delta) * delta
	%Overlay.modulate.a = max(0.0, min(1.0, %Overlay.modulate.a))
