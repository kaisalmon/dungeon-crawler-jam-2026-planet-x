@tool
extends GridMap

@export var randomize: bool = false

func _ready():
    self.changed.connect(update)

func _process(_delta):
    if randomize:
        randomize = false
        update()

func update():
    var cells = get_used_cells()
    for cell in cells:
        var cell_item = get_cell_item(cell)
        var cell_name = mesh_library.get_item_name(cell_item)
        var orientation = get_cell_item_orientation(cell)
        var replacement_name = cell_name.replace("__5", "").replace("__20", "")
        var rand = randf()
        if rand > 0.95:
             replacement_name = replacement_name + "__5"
        elif rand > 0.75:
            replacement_name = replacement_name + "__20"

        if replacement_name != cell_name:
            var replacement_item = mesh_library.find_item_by_name(replacement_name)
            if replacement_item != -1:
                super.set_cell_item(cell, replacement_item, orientation)