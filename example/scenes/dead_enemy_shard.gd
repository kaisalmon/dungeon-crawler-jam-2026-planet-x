extends RigidBody3D

var lifetime: float = 2.5

func _ready():
    # Add random velocity and angular velocity to the shard for a more dynamic effect
    self.linear_velocity += Vector3(randf_range(-2, 2), randf_range(1, 3), randf_range(-2, 2))
    self.angular_velocity = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))
    lifetime += randf_range(-1, 1) * .4  # Add some random variation to lifetime

func _process(delta):
    lifetime -= delta
    if lifetime <= 0:
        queue_free()
    var scale = min(lifetime, 1.0)  # Scale down as it gets closer to disappearing
    for child in get_children():
        child.scale = Vector3(scale, scale, scale)