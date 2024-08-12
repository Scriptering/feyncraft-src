extends GrabbableControl

var palette_file_path: String = "res://saves/Palettes/"
var web_palette_file_path: String = "user://saves/Palettes/"
var palette_item_scene: PackedScene = preload("res://Scenes and Scripts/UI/ColourPicker/palette_list_item.tscn")
signal closed

@export var load_button: PanelButton
@export var item_list: PanelItemList

func _ready() -> void:
	EventBus.save_files.connect(save_palettes)
	
	super._ready()
	load_default_palettes()
	load_palettes()
	load_tea_stain()

func _on_close_pressed() -> void:
	closed.emit()

func get_custom_file_path() -> String:
	return (palette_file_path + 'Custom/') if Globals.is_on_editor else (web_palette_file_path + 'Custom/')

func load_palettes() -> void:
	var seasonal_palette: String = get_seasonal_palette()
	if seasonal_palette != '':
		load_palette("res://saves/Palettes/Seasonal/" + seasonal_palette + '.txt')
	
	for file_path in FileManager.get_files_in_folder(get_custom_file_path()):
		load_palette(file_path)

func load_tea_stain() -> void:
	item_list.get_items().front().is_selected = true

func save_palettes() -> void:
	for palette_item:ListItem in item_list.get_items():
		if !palette_item.palette.is_custom:
			continue
		
		FileManager.save(palette_item.palette, palette_item.file_path)

func _on_add_problem_pressed() -> void:
	$PaletteList.create_new_palette(FileManager.get_unique_file_name(get_custom_file_path()))

func _on_load_button_submitted(submitted_text: String) -> void:
	var file_path: String = FileManager.get_unique_file_name(get_custom_file_path())
	FileManager.create_text_file(submitted_text, file_path)
	load_palette(file_path)

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
	load_default_palette("res://saves/Palettes/teastain.tres")
	load_default_palette("res://saves/Palettes/Default/Mushroom.tres")
	load_default_palette("res://saves/Palettes/Default/GameBoy.tres")

func load_default_palette(default_path: String) -> void:
	var palette_item: ListItem = palette_item_scene.instantiate()
	palette_item.load_data(load(default_path))
	add_palette(palette_item)

func load_palette(palette_path: String) -> void:
	var new_palette_item: ListItem = palette_item_scene.instantiate()
	new_palette_item.file_path = palette_path
	
	var palette: Palette = FileManager.load_txt(palette_path)
	if palette:
		new_palette_item.load_data(palette)
		add_palette(new_palette_item)
	else:
		new_palette_item.queue_free()
		FileManager.delete_file(palette_path)
	
	load_button.load_result(palette != null)

func palette_item_deleted(palette_item: ListItem) -> void:
	FileManager.delete_file(palette_item.file_path)
	
	if palette_item.is_selected:
		load_tea_stain()
	
	item_list.queue_free_item(palette_item)

func create_new_palette() -> void:
	var new_palette_item: ListItem = palette_item_scene.instantiate()
	
	var file_path: String = FileManager.get_unique_file_name(get_custom_file_path())
	new_palette_item.file_path = file_path
	new_palette_item.randomise()
	
	add_palette(new_palette_item)
	
	FileManager.save(new_palette_item.palette, file_path)

func _on_add_button_pressed() -> void:
	create_new_palette()
