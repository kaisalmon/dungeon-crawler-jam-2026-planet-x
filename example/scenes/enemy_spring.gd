extends Node3D
class_name EnemySpring

var velocity: Vector3 = Vector3.ZERO
var rotational_velocity: Quaternion = Quaternion.IDENTITY
@export var override_rotation: bool = false
@export var rotation_override: Quaternion = Quaternion.IDENTITY

var offset = Vector3.ZERO

func _ready():
	var target_position = self.get_parent().global_transform.origin
	self.top_level = true
	offset =  target_position - self.global_transform.origin

func _process(delta: float) -> void:
	var k = 250.0
	var damping = 0.5

	var target_position = self.get_parent().global_transform.origin - offset * get_parent().global_transform.basis.get_rotation_quaternion().inverse()
	var position_diff = target_position - self.global_transform.origin
	var target_velocity = position_diff * k
	velocity = velocity.lerp(target_velocity, 0.1)
	velocity *= damping
	var MAX_VEL = 30.0
	if velocity.length() > MAX_VEL:
		velocity = velocity.normalized() * MAX_VEL
	self.global_transform.origin += velocity * delta
	var MAX_DIST = 1.0
	if position_diff.length() > MAX_DIST:
		self.global_transform.origin = target_position - position_diff.normalized() * MAX_DIST

	k = 50.0
	damping = 0.4
	var target_rotation = self.get_parent().global_transform.basis.get_rotation_quaternion()
	if override_rotation:
		target_rotation = rotation_override
	var rotation_diff = target_rotation * self.global_transform.basis.get_rotation_quaternion().inverse()
	rotational_velocity = rotational_velocity.slerp(rotation_diff, 0.1)
	rotational_velocity = rotational_velocity.slerp(Quaternion.IDENTITY, damping)  
	self.global_transform.basis = Basis(rotational_velocity * self.global_transform.basis.get_rotation_quaternion())
	
func knockback(direction: Vector3, strength: float):
	velocity += direction.normalized() * strength
	var parent = get_parent()
	if parent and parent.has_method("knockback"):
		parent.knockback(direction, strength * 0.5)
