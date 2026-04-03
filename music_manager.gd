extends Node



@onready var menu_music: AudioStreamPlayer = $MenuMusic
@onready var gameplay_music: AudioStreamPlayer = $GameplayMusic
@onready var gameplay_music_2: AudioStreamPlayer = $GameplayMusic2
@onready var credits_music: AudioStreamPlayer = $CreditsMusic

const mute = -60
const unmute = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.add_to_group("MusicManager")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
var is_fading_combat = false
var entered_lab = false
var is_switching_music = false

func _process(delta: float) -> void:
	if Globals.in_combat and not is_fading_combat:
		is_fading_combat = true
		tween_combat_in()
	if not Globals.in_combat and is_fading_combat:
		is_fading_combat = false
		tween_combat_out()
	if Globals.in_lab_environment and not entered_lab:
		entered_lab = true
		play_music(gameplay_music_2)
	if not Globals.in_lab_environment and entered_lab:
		entered_lab = false
		play_music(gameplay_music)
	

func play_music(musicplayer: AudioStreamPlayer) -> void:
	if is_switching_music:
		return
	is_switching_music = true
	await music_stop()
	musicplayer.volume_linear = 1.0
	musicplayer.play()
	print("playing:", musicplayer.name)
	
	is_switching_music = false
	musicplayer.volume_linear = 1.0

func music_volume(vol: float) -> void:
	if gameplay_music.is_playing():
		gameplay_music.stream.set_sync_stream_volume(1, vol)
	if gameplay_music_2.is_playing():
		gameplay_music_2.stream.set_sync_stream_volume(1, vol)

func tween_combat_in() -> void:
	var combat_fade_in = create_tween()
	combat_fade_in.tween_method(Callable(self, "music_volume"), mute, unmute, 2)

func tween_combat_out() -> void:
	var combat_fade_out = create_tween()
	combat_fade_out.tween_method(Callable(self, "music_volume"), unmute, mute, 2)
	

func music_stop():
	var fadeout = create_tween() #Tween for smooth music fadeouts
	var fadeout_timer = 1.0
	if menu_music.is_playing():
		print("stopping menu music")
		fadeout.tween_property(menu_music, "volume_linear", 0, fadeout_timer)
		await get_tree().create_timer(fadeout_timer).timeout
		menu_music.stop()
	if gameplay_music.is_playing():
		print("stopping gameplay music")
		fadeout.tween_property(gameplay_music, "volume_linear", 0, fadeout_timer)
		await get_tree().create_timer(fadeout_timer).timeout
		gameplay_music.stop()
	if gameplay_music_2.is_playing():
		print("stopping gameplay music 2")
		fadeout.tween_property(gameplay_music_2, "volume_linear", 0, fadeout_timer)
		await get_tree().create_timer(fadeout_timer).timeout
		gameplay_music_2.stop()
	if credits_music.is_playing():
		print("stopping credits music")
		fadeout.tween_property(credits_music, "volume_linear", 0, fadeout_timer)
		await get_tree().create_timer(fadeout_timer).timeout
		credits_music.stop()		
	else:
		print("no music playing")

func reset_state():
	Globals.in_lab_environment = false
	is_fading_combat = false
	entered_lab = false
