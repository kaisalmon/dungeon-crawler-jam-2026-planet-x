extends Node3D
class_name DeadEnemy

func knockback(direction: Vector3, force: float):
    for child in get_children():
        if child is RigidBody3D:
            var body = child as RigidBody3D
            body.linear_velocity += direction * force