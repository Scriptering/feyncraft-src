extends List

func load_palette(palette_path: String) -> void:
	var new_palette: ListItem = Item.instantiate()
	new_palette.file_path = palette_path
	
	super.load_item(GLOBALS.load_data(palette_path), new_palette)

func _item_deleted(item: ListItem) -> void:
	var deleted_path: String = item.file_path
	GLOBALS.delete_file(deleted_path)
	
	super._item_deleted(item)

func save_palettes() -> void:
	var save_error: Error
	for palette in get_items():
		if !palette.palette.is_custom:
			continue

		save_error = GLOBALS.save_data(palette.palette, palette.file_path)
	
	print(save_error)
	
	
func create_new_palette(palette_path: String) -> void:
	var new_palette: ListItem = Item.instantiate()
	new_palette.file_path = palette_path
	GLOBALS.create_file(palette_path)
	GLOBALS.save_data(new_palette.palette, palette_path)
	super.load_item(Palette.new(), new_palette)
