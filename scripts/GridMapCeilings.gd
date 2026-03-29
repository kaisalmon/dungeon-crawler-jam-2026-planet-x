extends GridMap

@export var source: GridMap

func _ready():
	if source != null:
		self.global_position = source.global_position + Vector3(0, source.cell_size.y, 0)
		self.mesh_library = source.mesh_library
		update_from_source()
		source.changed.connect(update_from_source)

func update_from_source():
	var cells = source.get_used_cells()
	for cell in cells:
		var cell_item = source.get_cell_item(cell)
		var cell_name = source.mesh_library.get_item_name(cell_item)
		var orientation = source.get_cell_item_orientation(cell)
		var replacement_name = cell_name + "__Ceiling"
		var replacement_item = source.mesh_library.find_item_by_name(replacement_name)
		if replacement_item != -1:
			set_cell_item(cell, replacement_item, orientation)
