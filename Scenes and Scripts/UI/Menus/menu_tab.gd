extends PullOutTab

signal exit_pressed
signal toggled_line_labels(button_pressed: bool)

@onready var exit: PanelContainer = $MovingContainer/ContentContainer/HBoxContainer/Exit
@onready var mute: PanelContainer = $MovingContainer/ContentContainer/HBoxContainer/Mute
@onready var palettes: PanelContainer = $MovingContainer/ContentContainer/HBoxContainer/Palettes

var palette_menu: GrabbableControl

func init(_palette_menu: GrabbableControl) -> void:
	palette_menu = _palette_menu
	palette_menu.hide()
	palette_menu.closed.connect(_on_palette_menu_closed)
	
func _on_exit_pressed() -> void:
	exit_pressed.emit()

func toggle_palette_menu(toggle: bool) -> void:
	if !toggle:
		palette_menu.hide()
		return
	
	palette_menu.show()
	palette_menu.position = get_viewport_rect().size / 2
	
func _on_palettes_toggled(button_pressed: bool) -> void:
	toggle_palette_menu(button_pressed)

func _on_palette_menu_closed() -> void:
	palettes.button_pressed = false

func _on_show_labels_toggled(button_pressed: bool) -> void:
	toggled_line_labels.emit(button_pressed)
