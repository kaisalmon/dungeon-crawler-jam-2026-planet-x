extends Node3D
class_name DeadEnemy

@onready var enemy_death_sfx: AudioStreamPlayer3D = %EnemyDeathSFX

func _ready():
	await get_tree().create_timer(0.1).timeout
	enemy_death_sfx.play()

func knockback(direction: Vector3, force: float):
	for child in get_children():
		if child is RigidBody3D:
			var body = child as RigidBody3D
			body.linear_velocity += direction * force


