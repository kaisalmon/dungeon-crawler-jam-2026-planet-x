extends VBoxContainer

@export var in_game_menu = false

signal back_pressed

var music_volume_button: Button
var sfx_volume_button: Button
var back_button: Button
var quit_button: Button
@onready var button_click_sfx: AudioStreamPlayer = $"../ButtonClickSFX"

func _ready():
	self.visible = false
	music_volume_button = Button.new()
	music_volume_button.text = ""
	self.add_child(music_volume_button)
	music_volume_button.pressed.connect(_on_music_volume_pressed)

	sfx_volume_button = Button.new()
	sfx_volume_button.text = ""
	self.add_child(sfx_volume_button)
	sfx_volume_button.pressed.connect(_on_sfx_volume_pressed)

	if in_game_menu:
		back_button = Button.new()
		back_button.text = "Continue"
		self.add_child(back_button)
		back_button.pressed.connect(_on_back_pressed)

		quit_button = Button.new()
		quit_button.text = "Quit to Main Menu"
		self.add_child(quit_button)
		quit_button.pressed.connect(_on_quit_pressed)
	else:
		back_button = Button.new()
		back_button.text = "Back"
		self.add_child(back_button)
		back_button.pressed.connect(_on_back_pressed)

func _on_music_volume_pressed():
	Globals.music_volume -= 0.25
	if Globals.music_volume < 0.0:
		Globals.music_volume = 1.0
		
	var bus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(bus, linear_to_db(Globals.music_volume))
	button_click_sfx.play()
	
func _on_sfx_volume_pressed():
	Globals.sfx_volume -= 0.25
	if Globals.sfx_volume < 0.0:
		Globals.sfx_volume = 1.0

	var bus = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus, linear_to_db(Globals.sfx_volume))
	button_click_sfx.play()

func _on_back_pressed():
	emit_signal("back_pressed")

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and in_game_menu:
		self.visible = false
		get_tree().paused = false
		get_viewport().set_input_as_handled()

func _process(_delta):
	music_volume_button.text = "Music Volume: " + str(int(Globals.music_volume * 100)) + "%"
	sfx_volume_button.text = "SFX Volume: " + str(int(Globals.sfx_volume * 100)) + "%"
