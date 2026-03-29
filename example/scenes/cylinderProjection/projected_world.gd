extends Node3D

@export var world_nodes: Array[Node3D] = []
@export var celestial_body_nodes: Array[Node3D] = []
@export var celestial_body_positions: Array[Vector3] = []  # Direction and distance in sky coordinates

var world_grid = [
		[], # X-
		[], # 0
		[], # X+
	]

var grid_spacing: float

func _ready():
	if world_nodes.size() != 9:
		push_error("world_nodes must have exactly 9 elements.")
		return

	# Assert that all nodes have the same Y position
	var first_y = world_nodes[0].global_transform.origin.y
	for node in world_nodes:
		if not is_equal_approx(node.global_transform.origin.y, first_y):
			push_error("All world_nodes must have the same Y position.")
			return

	# Assert that nodes are arranged in a 3x3 grid, with equal spacing between grid points
	# This will mean there is 3 unique X positions and 3 unique Z positions
	var x_positions: Array[float] = []
	var z_positions: Array[float] = []
	for node in world_nodes:
		var pos = node.global_transform.origin
		var found_x = false
		var found_z = false
		for x in x_positions:
			if is_equal_approx(x, pos.x):
				found_x = true
				break
		if not found_x:
			x_positions.append(pos.x)
		for z in z_positions:
			if is_equal_approx(z, pos.z):
				found_z = true
				break
		if not found_z:
			z_positions.append(pos.z)

	if x_positions.size() != 3 or z_positions.size() != 3:
		push_error("world_nodes must be arranged in a 3x3 grid (found %d unique X and %d unique Z positions)." % [x_positions.size(), z_positions.size()])
		return

	# Sort positions to get consistent ordering
	x_positions.sort()
	z_positions.sort()

	# Set grid_spacing based on the distance between the first two unique X positions
	grid_spacing = x_positions[1] - x_positions[0]
	var z_spacing = z_positions[1] - z_positions[0]
	if not is_equal_approx(grid_spacing, z_spacing):
		push_error("Grid spacing must be equal in X and Z directions (X: %f, Z: %f)." % [grid_spacing, z_spacing])
		return
	if not is_equal_approx(x_positions[2] - x_positions[1], grid_spacing):
		push_error("Grid spacing must be consistent between all X positions.")
		return
	if not is_equal_approx(z_positions[2] - z_positions[1], grid_spacing):
		push_error("Grid spacing must be consistent between all Z positions.")
		return

	# Build the world_grid 2D array
	world_grid = [[], [], []]
	for xi in range(3):
		for zi in range(3):
			var target_x = x_positions[xi]
			var target_z = z_positions[zi]
			for node in world_nodes:
				var pos = node.global_transform.origin
				if is_equal_approx(pos.x, target_x) and is_equal_approx(pos.z, target_z):
					world_grid[xi].append(node)
					break

	# Print the world grid for debugging
	print("World grid initialized with spacing: ", grid_spacing)
	for xi in range(3):
		var row_str = ""
		for zi in range(3):
			row_str += world_grid[xi][zi].name + " "
		print("Row %d: %s" % [xi, row_str])

func _process(_delta):
	var player = Globals.getPlayer()
	RenderingServer.global_shader_parameter_set("planet_radius", 30.0)
	RenderingServer.global_shader_parameter_set("curve_origin", player.global_position)
	
	update_grid()
	update_sky()
	update_celestial_bodies()

var last_player_pos: Vector3
var sky_basis: Basis = Basis.IDENTITY


func update_sky():
	var player = Globals.getPlayer()
	if not player:
		return
	var player_pos = player.global_transform.origin

	# First frame initialization
	if last_player_pos == Vector3.ZERO:
		last_player_pos = player_pos
		return

	# Calculate movement delta
	var delta = player_pos - last_player_pos
	last_player_pos = player_pos

	var lat_step = delta.z / (3 * grid_spacing) * TAU
	var lon_step = delta.x / (3 * grid_spacing) * TAU

	# Accumulate rotations onto sky_basis
	if abs(lat_step) > 0.0001:
		sky_basis = Basis(Vector3.LEFT, lat_step) * sky_basis
	if abs(lon_step) > 0.0001:
		sky_basis = Basis(Vector3.BACK, lon_step) * sky_basis

	var environment = %WorldEnvironment.environment
	if environment:
		environment.sky_rotation = sky_basis.get_euler()

func update_celestial_bodies():
	var player = Globals.getPlayer()
	if not player:
		return
	var player_pos = player.global_transform.origin

	for i in range(min(celestial_body_nodes.size(), celestial_body_positions.size())):
		var node = celestial_body_nodes[i]
		var sky_pos = celestial_body_positions[i]
		if node:
			# Transform the sky_position by the current sky rotation (magnitude = distance)
			var rotated_pos = sky_basis * sky_pos
			node.global_transform.origin = player_pos + rotated_pos

func update_grid():
	var player = Globals.getPlayer()
	if not player:
		return
	var player_pos = player.global_transform.origin

	# Determine which grid cell the player is currently in
	# The center cell is at index [1][1], so we check if player moved beyond center bounds
	var center_node = world_grid[1][1]
	var center_pos = center_node.global_transform.origin

	var offset_x = player_pos.x - center_pos.x
	var offset_z = player_pos.z - center_pos.z

	# Determine grid shift needed (how many cells to shift)
	var shift_x = 0
	var shift_z = 0

	if offset_x > grid_spacing / 2.0:
		shift_x = 1  # Player moved to X+ cell, shift grid left
	elif offset_x < -grid_spacing / 2.0:
		shift_x = -1  # Player moved to X- cell, shift grid right

	if offset_z > grid_spacing / 2.0:
		shift_z = 1  # Player moved to Z+ cell, shift grid backward
	elif offset_z < -grid_spacing / 2.0:
		shift_z = -1  # Player moved to Z- cell, shift grid forward

	# If the player has moved to a new grid cell, update the world grid positions
	if shift_x != 0 or shift_z != 0:
		_shift_world_grid(shift_x, shift_z)

func _shift_world_grid(shift_x: int, shift_z: int):
	# The world shifts to follow the player - the player stays in place,
	# and world chunks wrap around to create infinite looping.
	# We also shift non-player GridEntities so they stay fixed relative to the world geometry.

	var player = Globals.getPlayer()

	# Shift world nodes in X direction
	if shift_x == 1:
		# Player moved X+, wrap the X- column to X+ side
		for zi in range(3):
			var node = world_grid[0][zi]
			node.global_transform.origin.x += grid_spacing * 3
		# Rotate columns: [0,1,2] -> [1,2,0]
		var temp = world_grid[0]
		world_grid[0] = world_grid[1]
		world_grid[1] = world_grid[2]
		world_grid[2] = temp
	elif shift_x == -1:
		# Player moved X-, wrap the X+ column to X- side
		for zi in range(3):
			var node = world_grid[2][zi]
			node.global_transform.origin.x -= grid_spacing * 3
		# Rotate columns: [0,1,2] -> [2,0,1]
		var temp = world_grid[2]
		world_grid[2] = world_grid[1]
		world_grid[1] = world_grid[0]
		world_grid[0] = temp

	# Shift world nodes in Z direction
	if shift_z == 1:
		# Player moved Z+, wrap the Z- row to Z+ side
		for xi in range(3):
			var node = world_grid[xi][0]
			node.global_transform.origin.z += grid_spacing * 3
		# Rotate rows: [0,1,2] -> [1,2,0]
		for xi in range(3):
			var temp = world_grid[xi][0]
			world_grid[xi][0] = world_grid[xi][1]
			world_grid[xi][1] = world_grid[xi][2]
			world_grid[xi][2] = temp
	elif shift_z == -1:
		# Player moved Z-, wrap the Z+ row to Z- side
		for xi in range(3):
			var node = world_grid[xi][2]
			node.global_transform.origin.z -= grid_spacing * 3
		# Rotate rows: [0,1,2] -> [2,0,1]
		for xi in range(3):
			var temp = world_grid[xi][2]
			world_grid[xi][2] = world_grid[xi][1]
			world_grid[xi][1] = world_grid[xi][0]
			world_grid[xi][0] = temp

	# # Move all non-player GridEntities to stay fixed relative to world geometry
	# # The player does NOT move - the world moves around them
	# var delta_world = Vector3(shift_x * grid_spacing, 0, shift_z * grid_spacing)
	# for entity in get_tree().get_nodes_in_group("grid_entities"):
	# 	if entity is GridEntity and entity != player:
	# 		var new_pos = entity.global_transform.origin + delta_world
	# 		entity.teleport_to_position(new_pos)
