extends GrabbableControl

var palette_file_path: String = "res://saves/Palettes/"
signal closed

func _ready() -> void:
	super._ready()
	load_palettes()

func _on_close_pressed() -> void:
	closed.emit()

func load_palettes() -> void:
	for file_path in GLOBALS.get_files_in_folder(palette_file_path + 'Default/'):
		$PaletteList.load_palette(file_path)
	for file_path in GLOBALS.get_files_in_folder(palette_file_path + 'Custom/'):
		$PaletteList.load_palette(file_path)

func _on_tree_exited() -> void:
	$PaletteList.save_palettes()

func _on_add_problem_pressed() -> void:
	$PaletteList.create_new_palette(GLOBALS.get_unique_file_name(palette_file_path + 'Custom/'))
