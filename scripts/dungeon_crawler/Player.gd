extends "res://scripts/dungeon_crawler/GridEntity.gd"
class_name Player

const inputQueueTime: float = 4
const inputQueueTimeTurn: float =4
const inputQueueTimeShoot: float = 4


@export var height: float = 0.7
@export var camera_offset: Vector3 = Vector3(0, 0, 0)
@export var bob_size: float = -0.01
@export var laser: NodePath
@export var invincible: bool = false

var last_input: String = ""
var last_input_time: float = -1.0
var world_rotation: float = 0.0 # Fake rotation for quirk
var in_cutscene: bool = true
var iframes:float = 0.0
var move_delay: float = 0.0
var shoot_delay: float = 0.0

var boomer_mode: bool = false

var health = 2
var max_health = 2
var shields = 0
var max_shields = 0
var shield_cooldown = 0.0

var raygun_heat = 0.0
var raygun_overheated = false

var has_gun_upgrade = false

@export var equipped_gun_position: Vector3 = Vector3(0,0,0)
@export var unequipped_gun_position: Vector3 = Vector3(0,0,0)
@export var settings: VBoxContainer

@onready var player_shoot_sfx: AudioStreamPlayer = %PlayerShootSFX
@onready var player_move_sfx: AudioStreamPlayer = %PlayerMoveSFX
@onready var player_hit_sfx: AudioStreamPlayer = %PlayerHitSFX
@onready var gun_online_sfx: AudioStreamPlayer = %GunOnlineSFX
@onready var shields_recharged_sfx: AudioStreamPlayer = %ShieldsRechargedSFX
@onready var shield_hit_sfx: AudioStreamPlayer = %ShieldHitSFX
@onready var gun_click_sfx: AudioStreamPlayer = %GunClickSFX
@onready var gun_overheat_sfx: AudioStreamPlayer = %GunOverheatSFX
var camera: Camera3D

var slime_damage_timer = 0.0
var slime_offset = Vector3.ZERO

func _ready():
	super._ready()
	add_to_group("player")
	add_to_group("saveable")
	self.is_player = true
	self.camera = $Camera3D

	settings.back_pressed.connect(unpause)

func can_move() -> bool:
	return (not is_moving) and (not is_turning) and not in_cutscene and not frozen

func _physics_process(delta):
	var target_gun_pos = equipped_gun_position if has_gun_upgrade else unequipped_gun_position
	$Camera3D/Raygun.position = $Camera3D/Raygun.position.lerp(target_gun_pos, 0.2)

	move_delay -= delta
	shoot_delay -= delta
	raygun_heat = max(0, raygun_heat - delta * 20)
	if raygun_overheated and raygun_heat <= 50:
		gun_online_sfx.play()
		raygun_overheated = false

	if shield_cooldown > 0:
		shield_cooldown -= delta
		if shield_cooldown <= 0 and shields < max_shields:
			shields += 1
			shields_recharged_sfx.play()
			shield_cooldown = 0.5
	
	if frozen:
		return

	if slime_count > 0:
		slime_damage_timer += delta
		if slime_damage_timer >= 0.2:
			self.damage(1.5)
			#SFX(Acid/Slime)
	else:
		slime_damage_timer = 0.0

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
	elif Input.is_action_pressed("shoot"):
		queue_input("shoot", now)
	
			

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not settings.visible:
		settings.visible = true
		get_tree().paused = true
		get_viewport().set_input_as_handled()

func unpause():
	get_tree().paused = false
	settings.visible = false

func queue_input(action: String, time: float):
	if action != "shoot":
		if move_delay > 0:
			return
	else:
		if shoot_delay > 0:
			return
	if can_move():
		execute_input(action)
	else:
		last_input = action
		last_input_time = time

func execute_input(action: String):
	last_input = ""
	last_input_time = -1
	move_delay = 0.25
	if action == "shoot":
		shoot_delay = 0.5
	prev_action = action
	match action:
		"move_forward": try_move_dir(global_transform.basis.z)
		"move_back": try_move_dir(-global_transform.basis.z)
		"strafe_left": try_move_dir(global_transform.basis.x)
		"strafe_right": try_move_dir(-global_transform.basis.x)
		"turn_left": start_turn(1)
		"turn_right": start_turn(-1)
		"shoot": shoot()

func on_move_success():
	if self.slime_count > 0:
		#SFX(Squish/Slime move)
		pass
	else:
		player_move_sfx.play()

func check_input_queue():
	var now = Time.get_ticks_msec() / 1000.0
	var tolerance =  inputQueueTimeTurn if (prev_action.begins_with("turn")) else (inputQueueTimeShoot if prev_action == "shoot" else inputQueueTime)
	if last_input != "" and last_input_time > 0 and (now - last_input_time) < tolerance:
		execute_input(last_input)

func apply_bobbing(delta):
	var camera = $Camera3D
	camera.global_position = global_position
	camera.global_position -= (height + abs(velocity.length()) * bob_size) * visual_gravity
	camera.position += self.camera_offset # Using local positioning
	var target_slime_offset = Vector3.ZERO
	if slime_count > 0:
		target_slime_offset.y = -1
	self.slime_offset = self.slime_offset.lerp(target_slime_offset, 0.05)
	camera.position += self.slime_offset
	if health <= 0:
		self.camera_offset += Vector3(0, -0.25, 0) * delta

func apply_fake_world_rotation(_delta):
	var camera = $Camera3D
	if gravity == Vector3.DOWN:
		var player_rotation = global_transform.basis.get_euler()
		camera.rotation_degrees.z = world_rotation * sin(player_rotation.y+PI/2)
		camera.rotation_degrees.x = world_rotation * cos(player_rotation.y+PI/2)
	else:
		camera.rotation_degrees.z = 0
		camera.rotation_degrees.x = 0

func activate():
	in_cutscene = false

func shoot():
	if not has_gun_upgrade:
		return

	if Globals.within_range_of_enemy:
		Globals.in_combat = true

	if raygun_overheated:
		gun_click_sfx.play()
		return
	

	

	if player_shoot_sfx:
		player_shoot_sfx.play()
		$Camera3D/Raygun.position.z += 0.1
	var particles_nodes = get_node(laser)
	if particles_nodes:
		var particles = particles_nodes as GPUParticles3D
		particles.emitting = true
		particles.restart()

		var target = global_transform.origin + global_transform.basis.z * 10

		var raygun_ray = PhysicsRayQueryParameters3D.new()
		raygun_ray.from = particles.global_transform.origin
		raygun_ray.to = target
		raygun_ray.exclude = [self]

		var hit_pos = target
		var ragun_col = get_world_3d().direct_space_state.intersect_ray(raygun_ray)
		if ragun_col and ragun_col.collider:
			hit_pos = ragun_col.position
			var shootable = ragun_col.collider as Shootable
			if shootable and shootable.has_method("on_shot"):
				shootable.on_shot()

		var length = global_transform.origin.distance_to(hit_pos)
		var process_material: ParticleProcessMaterial = particles.process_material
		process_material.emission_shape_scale = Vector3(0.05, 0.05, length)
		process_material.emission_shape_offset = Vector3(0, 0, -length)
		particles.amount = int(length * 100)

		var screen_res = get_viewport().get_visible_rect().size
		var screen_pos = Vector2(90, 85) / Vector2(128, 128) * screen_res
		var proj_pos = $Camera3D.project_position(screen_pos, 0.3)
		particles.global_position = proj_pos
		particles.look_at(hit_pos, Vector3.UP)
	
	raygun_heat += 40
	if raygun_heat >= 100:
		raygun_overheated = true
		gun_overheat_sfx.play()
		# SFX(Gun overheated) Instead of the normal 
		raygun_heat = 100
		Globals.tutorialize("Raygun overheated!")

func damage(iframes: float = 0.8):
	if invincible:
		return false
	if self.iframes > 0:
		return false
	if Globals.in_combat:
		shield_cooldown = 5.0
	else:
		shield_cooldown = 2.0
	self.iframes = iframes
	if shields > 0:
		shield_hit_sfx.play()
		shields -= 1
		return true
	health -= 1
	if health <= 0:
		# SFX(Death)
		die()
	else:
		player_hit_sfx.play()
		# SFX(hurt)
		pass
	return true

func die():
	in_cutscene = true
	await get_tree().create_timer(1.0).timeout
	var music_manager = get_tree().get_nodes_in_group("MusicManager")[0]
	music_manager.reset_state()
	music_manager.play_music(music_manager.menu_music)
	get_tree().reload_current_scene()
	music_manager.reset_state()
	music_manager.play_music(music_manager.menu_music)


func _on_static_body_3d_shot() -> void:
	damage()

func save():
	var json = {
		"x": target_position.x,
		"y": target_position.y,
		"z": target_position.z,
		"rotation_x_x": target_rotation.x.x,
		"rotation_x_y": target_rotation.x.y,
		"rotation_x_z": target_rotation.x.z,
		"rotation_y_x": target_rotation.y.x,
		"rotation_y_y": target_rotation.y.y,
		"rotation_y_z": target_rotation.y.z,
		"rotation_z_x": target_rotation.z.x,
		"rotation_z_y": target_rotation.z.y,
		"rotation_z_z": target_rotation.z.z,
		"health": health,
		"max_health": max_health,
		"shields": shields,
		"max_shields": max_shields,
		"has_gun_upgrade": has_gun_upgrade,
	}
	return json

func load(json):
	target_position = Vector3(json["x"], json["y"], json["z"])
	target_rotation = Basis(
		Vector3(json["rotation_x_x"], json["rotation_x_y"], json["rotation_x_z"]),
		Vector3(json["rotation_y_x"], json["rotation_y_y"], json["rotation_y_z"]),
		Vector3(json["rotation_z_x"], json["rotation_z_y"], json["rotation_z_z"])
	)
	global_transform.origin = target_position
	global_transform.basis = target_rotation
	health = json["health"]
	max_health = json["max_health"]
	shields = json["shields"]
	max_shields = json["max_shields"]
	has_gun_upgrade = json["has_gun_upgrade"]
