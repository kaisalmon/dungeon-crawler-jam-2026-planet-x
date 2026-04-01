extends Node

@onready var menu_music: AudioStreamPlayer = %MenuMusic
@onready var gameplay_music: AudioStreamPlayer = %GameplayMusic
@onready var credits_music: AudioStreamPlayer = %CreditsMusic

const mute = -60
const unmute = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play_music()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
var is_fading_combat = false

func _process(delta: float) -> void:
	if Globals.in_combat and not is_fading_combat:
		is_fading_combat = true
		tween_combat_in()
	elif not Globals.in_combat and is_fading_combat:
		is_fading_combat = false
		tween_combat_out()

func play_music():
	gameplay_music.play()
	

func music_volume(vol: float) -> void:
	gameplay_music.stream.set_sync_stream_volume(1, vol)

func tween_combat_in() -> void:
	var combat_fade_in = create_tween()
	combat_fade_in.tween_method(Callable(self, "music_volume"), mute, unmute, 1)

func tween_combat_out() -> void:
	var combat_fade_out = create_tween()
	combat_fade_out.tween_method(Callable(self, "music_volume"), unmute, mute, 1)

func music_stop():
	var fadeout = create_tween() #Tween for smooth music fadeouts
	var fadeout_timer = 2.0
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
	if credits_music.is_playing():
		print("stopping credits music")
		fadeout.tween_property(credits_music, "volume_linear", 0, fadeout_timer)
		await get_tree().create_timer(fadeout_timer).timeout
		credits_music.stop()		
	else:
		print("no music playing")
