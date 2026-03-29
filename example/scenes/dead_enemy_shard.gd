extends RigidBody3D

var lifetime: float = 2.5

@onready var enemy_death_sfx: AudioStreamPlayer3D = %EnemyDeathSFX
@onready var bounce_early_sfx: AudioStreamPlayer3D = %BounceEarlySFX
@onready var bounce_late_sfx: AudioStreamPlayer3D = %BounceLateSFX

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

func _integrate_forces(state):
	# Check if we have contacts
	if state.get_contact_count() > 0:
		# Get the impulse of the first contact point
		var impulse = state.get_contact_impulse(0)
		var force = impulse / state.step # Estimate force
		var magnitude = force.length()
		if magnitude > 150:
			bounce_early_sfx.play()
		elif magnitude > 50:
			bounce_late_sfx.play()
			print("Sound here pls")
		
