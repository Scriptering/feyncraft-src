extends PullOutTab

@export var palette_menu_offset: Vector2 = Vector2(-100, -100)

@onready var exit: PanelContainer = $MovingContainer/ContentContainer/HBoxContainer/Exit
@onready var mute: PanelContainer = $MovingContainer/ContentContainer/HBoxContainer/Mute
@onready var palettes: PanelContainer = $MovingContainer/ContentContainer/HBoxContainer/Palettes

var PaletteMenu: PackedScene = preload("res://Scenes and Scripts/UI/ColourPicker/palette_list.tscn")
var palette_menu: GrabbableControl

func _ready() -> void:
	super._ready()
	
	await get_tree().process_frame
	palette_menu = PaletteMenu.instantiate()
	EVENTBUS.add_floating_menu(palette_menu)
	palette_menu.hide()
	palette_menu.closed.connect(_on_palette_menu_closed)
	
func _on_exit_pressed() -> void:
	pass # Replace with function body.

func toggle_palette_menu(toggle: bool) -> void:
	if !toggle:
		palette_menu.hide()
		return
	
	palette_menu.show()
	palette_menu.position = get_global_position() + palette_menu_offset
	
func _on_palettes_toggled(button_pressed: bool) -> void:
	toggle_palette_menu(button_pressed)

func _on_palette_menu_closed() -> void:
	palettes.button_pressed = false
