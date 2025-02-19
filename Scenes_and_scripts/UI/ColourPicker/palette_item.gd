extends ListItem

@export var palette: Palette = Palette.new()

@export_group("Children")
@export var UseButton: PanelButton
@export var MoreColoursButton: PanelButton
@export var MoreColoursContainer: Container
@export var ClearButton: PanelContainer
@export var DeleteButton: PanelButton
@export var UploadButton: PanelButton
@export var Title: LineEdit
@export var Shuffle: PanelButton

@export var PrimaryColourButton: ColourButton
@export var GridColourButton: ColourButton
@export var SecondaryColourButton: ColourButton
@export var TextColourButton: ColourButton
@export var GridShadowColourButton: ColourButton
@export var ActiveColourButton: ColourButton
@export var DisabledColourButton: ColourButton
@export var Shadow1ColourButton: ColourButton
@export var Shadow2ColourButton: ColourButton

@onready var ColourButtonDict : Dictionary = {
	Palette.ColourIndex.Primary: PrimaryColourButton,
	Palette.ColourIndex.Grid: GridColourButton,
	Palette.ColourIndex.Secondary: SecondaryColourButton,
	Palette.ColourIndex.Text: TextColourButton,
	Palette.ColourIndex.GridShadow: GridShadowColourButton,
	Palette.ColourIndex.Active: ActiveColourButton,
	Palette.ColourIndex.Disabled: DisabledColourButton,
	Palette.ColourIndex.Shadow1: Shadow1ColourButton,
	Palette.ColourIndex.Shadow2: Shadow2ColourButton
}

var file_path: String
var is_selected: bool = false: set = _set_is_selected
var main_colours: Array[Palette.ColourIndex] = [Palette.ColourIndex.Primary, Palette.ColourIndex.Grid, Palette.ColourIndex.Secondary]

func init() -> void:
	toggle_more_colours(false)
	
	UseButton.button_group = load("res://Resources/ButtonGroups/palette.tres")
	
	for colour_button:ColourButton in ColourButtonDict.values():
		colour_button.colour_changed.connect(_on_colour_button_colour_changed)
	
	set_buttons_disabled(!palette.is_custom)
	update_button_colours(false)
	set_custom_button_visibility()
	Title.text = palette.title
	Title.editable = palette.is_custom

func _on_more_toggled(button_pressed: bool) -> void:
	toggle_more_colours(button_pressed)

func toggle_more_colours(toggle: bool) -> void:
	MoreColoursContainer.visible = toggle

	if toggle:
		MoreColoursButton.icon = load("res://Textures/Buttons/Tabs/arrow_up.png")
	else:
		MoreColoursButton.icon = load("res://Textures/Buttons/Tabs/arrow_down.png")

func update_button_colours(do_save: bool = true) -> void:
	for key:int in ColourButtonDict.keys():
		ColourButtonDict[key].icon_colour = palette.get_colour(key)
	
	if is_selected:
		update_shader()
	
	if do_save:
		save()

func get_button_colours() -> Array[Color]:
	var button_colours: Array[Color] = []
	
	for i:int in Palette.ColourIndex.values():
		if i not in ColourButtonDict.keys():
			button_colours.push_back(Color.BLACK)
			continue
		
		button_colours.push_back(ColourButtonDict[i].icon_colour)
	
	return button_colours

func set_buttons_disabled(disable: bool) -> void:
	for colour_button:ColourButton in ColourButtonDict.values():
		colour_button.set_disabled(disable)
	

func load_data(_palette: Palette) -> void:
	palette = _palette
	
	Title.editable = palette.is_custom
	Title.text = palette.title

func set_custom_button_visibility() -> void:
	DeleteButton.visible = palette.is_custom
	UploadButton.visible = palette.is_custom
	Shuffle.visible = palette.is_custom
	ClearButton.visible = palette.is_custom and palette.advanced_colours

func update_custom_palette() -> void:
	if palette.advanced_colours:
		return
	
	var custom_colours: Array[Color] = palette.get_custom_colours()
	
	for i:int in range(Palette.ColourIndex.size()):
		palette.colours[i] = custom_colours[i]
	
	update_button_colours()

func load_saved_palette() -> void:
	palette = load(file_path)

func update_shader() -> void:
	EventBus.change_palette.emit(palette.generate_palette_texture())

func randomise() -> void:
	palette.colours = palette.get_random_colours()
	update_button_colours()

func _on_randomise_pressed() -> void:
	randomise()

func _on_colour_button_colour_changed(colour_button: ColourButton, new_colour: Color) -> void:
	var colour_index: Palette.ColourIndex = ColourButtonDict.find_key(colour_button)
	palette.colours[colour_index] = new_colour
	
	if colour_index in main_colours:
		update_custom_palette()
	else:
		ClearButton.show()
		palette.advanced_colours = true
	
	update_button_colours()
 
func _set_is_selected(new_value: bool) -> void:
	var prev_value: bool = is_selected
	is_selected = new_value
	
	if prev_value != is_selected:
		UseButton.button_pressed = is_selected
	
	if is_selected:
		update_shader()
	
	StatsManager.stats.palette = load(file_path)

func _on_delete_pressed() -> void:
	deleted.emit(self)

func _on_title_text_changed(new_text: String) -> void:
	palette.title = new_text
	save()

func save() -> void:
	ResourceSaver.save(palette, file_path)

func _on_clear_pressed() -> void:
	palette.advanced_colours = false
	ClearButton.hide()
	update_custom_palette()

func _on_upload_pressed() -> void:
	ClipBoard.copy(FileManager.get_resource_save_data(palette))

func _on_view_toggled(button_pressed: bool) -> void:
	self.is_selected = button_pressed
