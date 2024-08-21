extends GrabbableControl

var palette_item_scene: PackedScene = preload("res://Scenes and Scripts/UI/ColourPicker/palette_list_item.tscn")

@export var load_button: PanelButton
@export var item_list: PanelItemList

signal close

func _ready() -> void:
	EventBus.save_files.connect(save_palettes)
	
	super._ready()
	load_default_palettes()
	load_palettes()
	load_last_palette()

func load_last_palette() -> void:
	for palette_item:ListItem in item_list.get_items():
		if palette_item.palette == StatsManager.stats.palette:
			palette_item.is_selected = true
			return

func _on_close_pressed() -> void:
	close.emit()

func palette_folder() -> String:
	return FileManager.get_file_prefix() + "saves/Palettes/"

func get_custom_file_path() -> String:
	return palette_folder() + 'Custom/'

func load_palettes() -> void:
	var seasonal_palette: String = get_seasonal_palette()
	if seasonal_palette != '':
		load_palette(palette_folder() + "Seasonal/" + seasonal_palette + '.tres')

	for file_path in FileManager.get_files_in_folder(get_custom_file_path()):
		load_palette(file_path)

func load_tea_stain() -> void:
	item_list.get_items().front().is_selected = true

func save_palettes() -> void:
	for palette_item:ListItem in item_list.get_items():
		if !palette_item.palette.is_custom:
			continue
		
		ResourceSaver.save(palette_item.palette, palette_item.file_path)

func _on_add_problem_pressed() -> void:
	$PaletteList.create_new_palette(FileManager.get_unique_file_name(get_custom_file_path()))

func get_seasonal_palette() -> String:
	var datetime: Dictionary = Time.get_datetime_dict_from_system()
	
	var day: int = datetime["day"]
	var month: int = datetime["month"]
	
	if month == Time.MONTH_OCTOBER:
		return "halloween"
	
	if month == Time.MONTH_DECEMBER and day == 25:
		return "christmas"
	
	if month == Time.MONTH_DECEMBER:
		return "winter"
	
	if month == Time.MONTH_FEBRUARY and day < 15:
		return "valentine"
	
	if (
		(month == Time.MONTH_JANUARY and day < 25) or 
		(month == Time.MONTH_MAY and day > 18) or
		(month == Time.MONTH_JUNE and day < 7)
	):
		return "exam"
	
	return ''

func add_palette(palette_item: ListItem) -> void:
	item_list.add_item(palette_item)
	palette_item.init()
	palette_item.deleted.connect(palette_item_deleted)

func load_default_palettes() -> void:
	load_palette("res://saves/Palettes/Default/teastain.tres")
	load_palette("res://saves/Palettes/Default/Mushroom.tres")
	load_palette("res://saves/Palettes/Default/GameBoy.tres")

func load_palette(palette_path: String) -> void:
	var new_palette_item: ListItem = palette_item_scene.instantiate()
	new_palette_item.file_path = palette_path

	new_palette_item.load_data(load(palette_path))
	add_palette(new_palette_item)

func palette_item_deleted(palette_item: ListItem) -> void:
	FileManager.delete_file(palette_item.file_path)
	
	if palette_item.is_selected:
		load_tea_stain()
	
	item_list.queue_free_item(palette_item)

func create_new_palette_item(palette: Palette = null, file_path: String = '') -> void:
	var new_palette_item: ListItem = palette_item_scene.instantiate()
	
	if file_path == '':
		file_path = FileManager.get_unique_file_name(get_custom_file_path(), ".tres")
	
	new_palette_item.file_path = file_path
	
	if palette:
		new_palette_item.palette = palette
	else:
		new_palette_item.randomise()
	
	add_palette(new_palette_item)
	
	ResourceSaver.save(new_palette_item.palette, file_path)

func _on_add_button_pressed() -> void:
	create_new_palette_item()

func _on_load_button_pressed() -> void:
	var palette: Palette = str_to_var(ClipBoard.paste())
	if palette:
		create_new_palette_item(palette)
	else:
		EventBus.show_feedback.emit("Load invalid.")
