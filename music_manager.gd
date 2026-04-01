extends Node

@onready var menu_music: AudioStreamPlayer = %MenuMusic
@onready var gameplay_music: AudioStreamPlayer = %GameplayMusic
@onready var credits_music: AudioStreamPlayer = %CreditsMusic


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func play_music(string):
	
	

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
