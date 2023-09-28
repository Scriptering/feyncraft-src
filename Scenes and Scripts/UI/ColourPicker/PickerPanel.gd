extends GrabbableControl

signal colour_changed(colour: Color)
signal closed
signal sampler_toggled(button_pressed: bool)

@onready var ColourPicker: ColorPicker = $VBoxContainer/PanelContainer/VBoxContainer/MarginContainer/ColorPicker

var starting_colour: Color = Color.BLACK
var title: String = "": set = _set_title

var sampling: bool = false
var screen_image: Image

func _ready() -> void:
	super._ready()
	
	colour = starting_colour

var colour: Color:
	set(new_value):
		colour = new_value
		ColourPicker.color = colour
		colour_changed.emit(colour)

func _set_title(new_value: String) -> void:
	title = new_value
	$VBoxContainer/TitleContainer/HBoxContainer/Title.text = title

func _on_color_picker_color_changed(color: Color) -> void:
	colour_changed.emit(color)

func _on_close_pressed() -> void:
	closed.emit()
	hide()

func _on_sampler_toggled(button_pressed: bool) -> void:
	sampler_toggled.emit(button_pressed)
	self.sampling = button_pressed

func _on_line_edit_text_submitted(new_text: String) -> void:
	if new_text.is_valid_hex_number():
		self.colour = Color(new_text)

func _on_colour_sampler_sample_submitted(submitted_colour: Color) -> void:
	self.colour = submitted_colour
