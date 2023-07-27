extends HBoxContainer

signal palette_changed

@onready var PaletteButtonGroup : ButtonGroup = load("res://Resources/ButtonGroups/palette.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
	for pallete_button in get_children():
		pallete_button.connect("on_pressed", Callable(self, "_on_palette_button_pressed"))
		pallete_button.button_group = PaletteButtonGroup

func _on_palette_button_pressed(button: PanelButton):
	emit_signal("palette_changed", button.icon)
