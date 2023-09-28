extends ListItem

signal selected

@onready var UseButton: PanelButton = $HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Use
@onready var MoreColoursButton: PanelButton = $HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/More
@onready var MoreColoursContainer: Container = $HBoxContainer/PanelContainer/VBoxContainer/MoreContainer

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

var is_selected: bool = false: set = _set_is_selected
var palette: Palette = Palette.new()
var changed_colours: Array[Palette.ColourIndex] = []
var main_colours: Array[Palette.ColourIndex] = [Palette.ColourIndex.Primary, Palette.ColourIndex.Grid, Palette.ColourIndex.Secondary]

func _ready() -> void:
	toggle_more_colours(false)
	
	for colour_button in ColourButtonDict.values():
		colour_button.colour_changed.connect(_on_colour_button_colour_changed)
	
	var temp_palette: Palette = Palette.new()
	temp_palette.colours = get_button_colours()
	
	load_data(temp_palette)
	
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
		if key in changed_colours:
			continue
		
		ColourButtonDict[key].icon_colour = palette.get_colour(key)

func get_button_colours() -> PackedColorArray:
	var button_colours: PackedColorArray = []
	
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
	
	set_buttons_disabled(!palette.is_custom)
	update_button_colours()

func update_custom_palette() -> void:
	var custom_colours: PackedColorArray = palette.get_custom_colours()
	
	for i in range(Palette.ColourIndex.size()):
		if i in changed_colours:
			continue
		
		palette.colours[i] = custom_colours[i]

func _on_reset_pressed() -> void:
	changed_colours.clear()
	update_custom_palette()
	update_button_colours()

func update_shader() -> void:
	EVENTBUS.change_palette(palette.generate_palette_texture())

func _on_randomise_pressed() -> void:
	palette.colours = palette.get_random_colours()
	update_button_colours()
	
	if is_selected:
		update_shader()

func _on_colour_button_colour_changed(colour_button: ColourButton, new_colour: Color) -> void:
	var colour_index: Palette.ColourIndex = ColourButtonDict.find_key(colour_button)
	
	if colour_index not in changed_colours:
		changed_colours.push_back(colour_index)
	
	palette.colours[colour_index] = new_colour
	
	if colour_index in main_colours:
		update_custom_palette()
		update_button_colours()
	
	if is_selected:
		update_shader()
 
func _on_use_toggled(button_pressed: bool) -> void:
	self.is_selected = button_pressed

func _set_is_selected(new_value: bool) -> void:
	is_selected = new_value
	
	if is_selected:
		update_shader()
