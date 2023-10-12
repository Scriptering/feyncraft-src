extends GrabbableControl

var palette_file_path: String = "res://saves/Palettes/"
signal closed

func _ready() -> void:
	tree_exited.connect(_on_tree_exited)
	$PaletteList.load_result.connect(_on_load_result)
	$PaletteList.selected_palette_deleted.connect(load_tea_stain)
	
	super._ready()
	load_palettes()
	load_tea_stain()
	$PaletteList/VBoxContainer/PanelContainer/MarginContainer/ScrollContainer.scroll_vertical = 0

func _on_close_pressed() -> void:
	closed.emit()

func load_palettes() -> void:
	for file_path in GLOBALS.get_files_in_folder(palette_file_path + 'Custom/'):
		$PaletteList.load_palette(file_path)

func load_tea_stain() -> void:
	$PaletteList.get_items().front().is_selected = true

func _on_tree_exited() -> void:
	$PaletteList.save_palettes()

func _on_add_problem_pressed() -> void:
	$PaletteList.create_new_palette(GLOBALS.get_unique_file_name(palette_file_path + 'Custom/'))

func _on_load_button_submitted(submitted_text) -> void:
	var file_path: String = GLOBALS.get_unique_file_name(palette_file_path + 'Custom/')
	GLOBALS.create_text_file(submitted_text, file_path)
	$PaletteList.load_palette(file_path)

func _on_load_result(valid: bool) -> void:
	($PaletteList/VBoxContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/HBoxContainer/LoadButton
	.load_result(valid))
