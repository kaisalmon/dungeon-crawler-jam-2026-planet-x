extends Area3D

enum MusicState {
    LAB,
    PLANET
}

@export var change_music_to: MusicState

func _ready():
    connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
    if body.get_parent().is_in_group("player"):
        Globals.in_lab_environment = change_music_to == MusicState.LAB