extends ListItem

signal selected

@export var palette: Palette = Palette.new()

@onready var UseButton: PanelButton = $HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Use
@onready var MoreColoursButton: PanelButton = $HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/More
@onready var MoreColoursContainer: Container = $HBoxContainer/PanelContainer/VBoxContainer/MoreContainer
@onready var ClearButton: PanelContainer = $HBoxContainer/PanelContainer/VBoxContainer/MoreContainer/HBoxContainer/Clear

@onready var PrimaryColourButton: ColourButton = $HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Colours/Primary
@onready var GridColourButton: ColourButton = $HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Colours/Grid
@onready var SecondaryColourButton: ColourButton = $HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Colours/Secondary
@onready var TextColourButton: ColourButton = $HBoxContainer/PanelContainer/VBoxContainer/MoreContainer/GridContainer/Text
@onready var GridShadowColourButton: ColourButton = $HBoxContainer/PanelContainer/VBoxContainer/MoreContainer/GridContainer/GridShadow
@onready var ActiveColourButton: ColourButton = $HBoxContainer/PanelContainer/VBoxContainer/MoreContainer/GridContainer/Active
@onready var DisabledColourButton: ColourButton = $HBoxContainer/PanelContainer/VBoxContainer/MoreContainer/GridContainer/Disabled
@onready var Shadow1ColourButton: ColourButton = $HBoxContainer/PanelContainer/VBoxContainer/MoreContainer/GridContainer/Shadow1
@onready var Shadow2ColourButton: ColourButton = $HBoxContainer/PanelContainer/VBoxContainer/MoreContainer/GridContainer/Shadow2

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

func _ready() -> void:
	if !palette.is_custom:
		init()

func init() -> void:
	toggle_more_colours(false)
	
	for colour_button in ColourButtonDict.values():
		colour_button.colour_changed.connect(_on_colour_button_colour_changed)
	
	ClearButton.visible = palette.advanced_colours
	set_buttons_disabled(!palette.is_custom)
	update_button_colours()
	set_custom_button_visibility()
	$HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Title.text = palette.title

func _on_more_toggled(button_pressed: bool) -> void:
	toggle_more_colours(button_pressed)

func toggle_more_colours(toggle: bool) -> void:
	MoreColoursContainer.visible = toggle

	if toggle:
		MoreColoursButton.icon = load("res://Textures/Buttons/Tabs/arrow_up.png")
	else:
		MoreColoursButton.icon = load("res://Textures/Buttons/Tabs/arrow_down.png")

func update_button_colours() -> void:
	for key in ColourButtonDict.keys():
		ColourButtonDict[key].icon_colour = palette.get_colour(key)
	
	if is_selected:
		update_shader()
	
	save()

func get_button_colours() -> Array[Color]:
	var button_colours: Array[Color] = []
	
	for i in Palette.ColourIndex.values():
		if i not in ColourButtonDict.keys():
			button_colours.push_back(Color.BLACK)
			continue
		
		button_colours.push_back(ColourButtonDict[i].icon_colour)
	
	return button_colours

func set_buttons_disabled(disable: bool) -> void:
	for colour_button in ColourButtonDict.values():
		colour_button.disabled = disable

func load_data(_palette: Palette) -> void:
	palette = _palette
	
	$HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Title.editable = palette.is_custom
	$HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Title.text = palette.title

func set_custom_button_visibility() -> void:
	$HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Buttons/Delete.visible = palette.is_custom
	$HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Buttons/Upload.visible = palette.is_custom

func update_custom_palette() -> void:
	if palette.advanced_colours:
		return
	
	var custom_colours: Array[Color] = palette.get_custom_colours()
	
	for i in range(Palette.ColourIndex.size()):
		palette.colours[i] = custom_colours[i]
	
	update_button_colours()

func load_saved_palette() -> void:
	palette = GLOBALS.load_txt(file_path)

func update_shader() -> void:
	EVENTBUS.signal_change_palette.emit(palette.generate_palette_texture())

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
 
func _on_use_toggled(button_pressed: bool) -> void:
	self.is_selected = button_pressed

func _set_is_selected(new_value: bool) -> void:
	var prev_value: bool = is_selected
	is_selected = new_value
	
	if prev_value != is_selected:
		UseButton.button_pressed = is_selected
	
	if is_selected:
		update_shader()

func _on_delete_pressed() -> void:
	deleted.emit(self)

func _on_title_text_changed(new_text: String) -> void:
	palette.title = new_text
	save()

func _on_upload_toggled(button_pressed) -> void:
	if !button_pressed:
		return
	
	await get_tree().process_frame
	
	$HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Buttons/Upload.set_text(GLOBALS.get_resource_save_data(palette))

func save() -> void:
	GLOBALS.save(palette, file_path)

func _on_clear_pressed() -> void:
	palette.advanced_colours = false
	ClearButton.hide()
	update_custom_palette()
