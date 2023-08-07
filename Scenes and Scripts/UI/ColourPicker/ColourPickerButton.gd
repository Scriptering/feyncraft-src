extends ColorPickerButton


# Called when the node enters the scene tree for the first time.
func _ready():
	set_picker_properties()

func set_picker_properties() -> void:
	var picker: ColorPicker = get_picker()
	var pop_up: PopupPanel = get_popup()
	
	picker.color_mode = ColorPicker.MODE_RGB
	picker.picker_shape = ColorPicker.SHAPE_HSV_RECTANGLE
	picker.can_add_swatches = false
	picker.sampler_visible = false
	picker.color_modes_visible = false
	picker.sliders_visible = false
	picker.hex_visible = false
	picker.presets_visible = false
	
