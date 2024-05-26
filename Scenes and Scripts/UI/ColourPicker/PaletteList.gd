extends PanelContainer

signal load_result(valid: bool)
signal selected_palette_deleted

@export var Item: PackedScene
@export var ItemContainer: BoxContainer
@export var Title: Label

@export var title: String = '':
	set(new_value):
		title = new_value
		
		if Title:
			Title.text = title

@export var scroll_container: ScrollContainer

var items_data: Array

func _ready() -> void:
	scroll_container.get_v_scroll_bar().use_parent_material = true

func load_items(_items_data: Array) -> void:
	items_data = _items_data
	
	clear_items()
	
	for item_data in items_data:
		load_item(item_data)

func load_item(item_data = null, new_item: ListItem = Item.instantiate()) -> void:
	ItemContainer.add_child(new_item)
	
	if item_data:
		new_item.load_data(item_data)

	new_item.init()
	new_item.index = ItemContainer.get_child_count() + 1
	new_item.deleted.connect(_item_deleted)

func create_new_item() -> void:
	load_item()

func _item_deleted(item: ListItem) -> void:
	var deleted_path: String = item.file_path
	
	print(deleted_path)
	
	print(GLOBALS.delete_file(deleted_path))
	
	print(GLOBALS.get_files_in_folder("user://saves/Palettes/Custom/"))
	
	items_data.remove_at(get_items().find(item))
	item.queue_free()
	
	if item.is_selected:
		selected_palette_deleted.emit()
	
	print(GLOBALS.get_files_in_folder("user://saves/Palettes/Custom/"))

func get_items() -> Array[ListItem]:
	var items: Array[ListItem] = []
	
	for item in ItemContainer.get_children():
		items.push_back(item)
	
	return items

func clear_items() -> void:
	for item in ItemContainer.get_children():
		item.queue_free()

func update_index_labels() -> void:
	for i in range(ItemContainer.get_child_count()):
		var item: ListItem = ItemContainer.get_child(i)
		
		if item.is_queued_for_deletion():
			continue
		
		item.index = i

func load_palette(palette_path: String) -> void:
	var new_palette: ListItem = preload("res://Scenes and Scripts/UI/ColourPicker/palette_list_item.tscn").instantiate()
	new_palette.file_path = palette_path
	
	var palette: Palette = GLOBALS.load_txt(palette_path)
	if palette:
		load_item(palette, new_palette)
		load_result.emit(true)
	else:
		new_palette.queue_free()
		GLOBALS.delete_file(palette_path)
		load_result.emit(false)

func save_palettes() -> void:
	for palette in get_items():
		if !palette.palette.is_custom:
			continue
		
		palette.save()

func create_new_palette(palette_path: String) -> void:
	var new_palette: ListItem = Item.instantiate()
	new_palette.file_path = palette_path
	load_item(Palette.new(), new_palette)
	new_palette.randomise()
	
	GLOBALS.save(new_palette.palette, palette_path)
