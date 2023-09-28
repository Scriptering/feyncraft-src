extends PullOutTab

@export var palette_menu_offset: Vector2 = Vector2(-100, -100)

@onready var exit: PanelContainer = $MovingContainer/ContentContainer/HBoxContainer/Exit
@onready var mute: PanelContainer = $MovingContainer/ContentContainer/HBoxContainer/Mute
@onready var palettes: PanelContainer = $MovingContainer/ContentContainer/HBoxContainer/Palettes

var PaletteMenu: PackedScene = preload("res://Scenes and Scripts/UI/ColourPicker/palette_list.tscn")
var palette_menu: GrabbableControl

func _ready() -> void:
	super._ready()
	mute.button_pressed = !AudioServer.is_bus_mute(0)
	
	await get_tree().process_frame
	palette_menu = PaletteMenu.instantiate()
	EVENTBUS.add_floating_menu(palette_menu)
	palette_menu.hide()
	

func _on_exit_pressed() -> void:
	pass # Replace with function body.

func _on_mute_toggled(button_pressed: bool) -> void:
	SOUNDBUS.mute(!button_pressed)
	
	if button_pressed:
		mute.icon = load("res://Textures/Buttons/icons/unmute.png")
	else:
		mute.icon = load("res://Textures/Buttons/icons/mute.png")

func _on_palettes_toggled(button_pressed: bool) -> void:
	if !button_pressed:
		palette_menu.hide()
		return
	
	palette_menu.show()
	palette_menu.position = get_global_position() + palette_menu_offset
	
	
	
	
