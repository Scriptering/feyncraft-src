extends GrabbableControl

var palette_file_path: String = "res://saves/Palettes/"
var web_palette_file_path: String = "user://saves/Palettes/"
signal closed

@export var load_button: PanelButton
@export var scroll_container: ScrollContainer

func _ready() -> void:
	EventBus.save_files.connect(save_palettes)
	
	$PaletteList.load_result.connect(_on_load_result)
	$PaletteList.selected_palette_deleted.connect(load_tea_stain)
	
	super._ready()
	load_palettes()
	load_tea_stain()
	scroll_container.scroll_vertical = 0

func _on_close_pressed() -> void:
	closed.emit()

func get_custom_file_path() -> String:
	return (palette_file_path + 'Custom/') if Globals.is_on_editor else (web_palette_file_path + 'Custom/')

func load_palettes() -> void:
	var seasonal_palette: String = get_seasonal_palette()
	if seasonal_palette != '':
		$PaletteList.load_palette("res://saves/Palettes/Seasonal/" + seasonal_palette + '.txt')
	
	for file_path in FileManager.get_files_in_folder(get_custom_file_path()):
		$PaletteList.load_palette(file_path)

func load_tea_stain() -> void:
	$PaletteList.get_items().front().is_selected = true

func save_palettes() -> void:
	$PaletteList.save_palettes()

func _on_add_problem_pressed() -> void:
	$PaletteList.create_new_palette(FileManager.get_unique_file_name(get_custom_file_path()))

func _on_load_button_submitted(submitted_text: String) -> void:
	var file_path: String = FileManager.get_unique_file_name(get_custom_file_path())
	FileManager.create_text_file(submitted_text, file_path)
	$PaletteList.load_palette(file_path)

func _on_load_result(valid: bool) -> void:
	load_button.load_result(valid)

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
	
