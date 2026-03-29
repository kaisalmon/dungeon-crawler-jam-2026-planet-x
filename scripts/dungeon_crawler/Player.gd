extends "res://scripts/dungeon_crawler/GridEntity.gd"
class_name Player

const inputQueueTime: float = 0.1
const inputQueueTimeTurn: float = 0.1

@export var height: float = 0.7
@export var camera_offset: Vector3 = Vector3(0, 0, 0)
@export var bob_size: float = -0.01

var last_input: String = ""
var last_input_time: float = -1.0
var world_rotation: float = 0.0 # Fake rotation for quirk
var in_cutscene: bool = true
var iframes:float = 0.0
var move_delay: float = 0.0

var boomer_mode: bool = false

func _ready():
	super._ready()
	add_to_group("player")

func can_move() -> bool:
	return (not is_moving) and (not is_turning) and not in_cutscene and not frozen

func _physics_process(delta):
	move_delay -= delta
	if frozen:
		return

	if boomer_mode:
		turn_spring_constant = 25
		global_basis = target_rotation.get_rotation_quaternion()
		global_position = target_position
		world_rotation = 0
	iframes -= delta
	if iframes < 0:
		iframes = 0
	handle_input()
	super._physics_process(delta)
	apply_bobbing(delta)
	apply_fake_world_rotation(delta)

func handle_input():
	if move_delay > 0:
		return
	var now = Time.get_ticks_msec() / 1000.0

	if Input.is_action_pressed("turn_left"):
		queue_input("turn_left", now)
	elif Input.is_action_pressed("turn_right"):
		queue_input("turn_right", now)
	elif Input.is_action_pressed("move_forward"):
		queue_input("move_forward", now)
	elif Input.is_action_pressed("move_back"):
		queue_input("move_back", now)
	elif Input.is_action_pressed("strafe_left"):
		queue_input("strafe_left", now)
	elif Input.is_action_pressed("strafe_right"):
		queue_input("strafe_right", now)

func queue_input(action: String, time: float):
	if can_move():
		execute_input(action)
	else:
		last_input = action
		last_input_time = time

func execute_input(action: String):
	last_input = ""
	last_input_time = -1
	move_delay = 0.25
	prev_action = action
	match action:
		"move_forward": try_move_dir(global_transform.basis.z)
		"move_back": try_move_dir(-global_transform.basis.z)
		"strafe_left": try_move_dir(global_transform.basis.x)
		"strafe_right": try_move_dir(-global_transform.basis.x)
		"turn_left": start_turn(1)
		"turn_right": start_turn(-1)

func on_move_success():
	pass

func check_input_queue():
	var now = Time.get_ticks_msec() / 1000.0
	var tolerance =  inputQueueTimeTurn if (prev_action.begins_with("turn")) else inputQueueTime
	if last_input != "" and last_input_time > 0 and (now - last_input_time) < tolerance:
		execute_input(last_input)

func apply_bobbing(_delta):
	var camera = $Camera3D
	camera.global_position = global_position
	camera.global_position -= (height + abs(velocity.length()) * bob_size) * visual_gravity
	camera.position += self.camera_offset # Using local positioning

func apply_fake_world_rotation(_delta):
	var camera = $Camera3D
	if gravity == Vector3.DOWN:
		var player_rotation = global_transform.basis.get_euler()
		camera.rotation_degrees.z = world_rotation * sin(player_rotation.y+PI/2)
		camera.rotation_degrees.x = world_rotation * cos(player_rotation.y+PI/2)
	else:
		camera.rotation_degrees.z = 0
		camera.rotation_degrees.x = 0


func save():
	var json = super.save()
	json["world_rotation"] = world_rotation
	json["is_player"] = true
	return json

func load(json: Dictionary):
	super.load(json)
	world_rotation = json["world_rotation"]

func activate():
	in_cutscene = false
