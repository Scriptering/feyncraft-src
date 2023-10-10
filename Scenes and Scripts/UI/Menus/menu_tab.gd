extends PullOutTab

signal exit_pressed

@onready var exit: PanelContainer = $MovingContainer/ContentContainer/HBoxContainer/Exit
@onready var mute: PanelContainer = $MovingContainer/ContentContainer/HBoxContainer/Mute
@onready var palettes: PanelContainer = $MovingContainer/ContentContainer/HBoxContainer/Palettes

var palette_menu: GrabbableControl

func init() -> void:
	palette_menu = preload("res://Scenes and Scripts/UI/ColourPicker/palette_list.tscn").instantiate()
	
	palette_menu.hide()
	palette_menu.closed.connect(_on_palette_menu_closed)
	EVENTBUS.add_floating_menu(palette_menu)
	
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
