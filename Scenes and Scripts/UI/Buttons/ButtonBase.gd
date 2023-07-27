extends PanelContainer

enum ACTIVE {INACTIVE, ACTIVE}
enum BUTTON_STATE {NORMAL, PRESSED, HOVER, DISABLED}
enum {LEFT, TOP, RIGHT, BOTTOM}

const DISABLED_ALPHA := 0.5

@export var Text : String
@export var Icon : CompressedTexture2D
@export var disabled : bool
@export var active : bool: set = set_active

@onready var button = get_node('Button')
@onready var NormalCentre := get_node('NormalCentre')
@onready var PressedCentre := get_node('PressedCentre')

@onready var NormalContainer := get_node('NormalContainer')
@onready var PressedContainer := get_node('PressedContainer')

const COLOURS = [['e6cd9c', 'd1bd97', 'e3d3c0', 'e6cd9c'], ['ffc654', 'd1bd97', 'ffd47f', 'ffc654']]

var button_state : int = BUTTON_STATE.NORMAL
var hovering : bool = false

signal pressed
signal update_cursor

func _ready():
	set_disabled(button.disabled)
	
	if Text != null:
		button.text = Text
	if Icon != null:
		change_icon(Icon)
	
	handle_button_state(button.get_draw_mode())

func _process(_delta):
	handle_button_state(button.get_draw_mode())

func set_active(new_active : bool) -> void:
	active = new_active

func handle_button_state(state : int) -> void:
	button_state = state
	
	if button_state == BUTTON_STATE.PRESSED:
		NormalCentre.visible = false
		NormalContainer.visible = false
		PressedCentre.visible = true
		PressedContainer.visible = true
		
	
	else:
		NormalCentre.visible = true
		NormalContainer.visible = true
		PressedCentre.visible = false
		PressedContainer.visible = false
		set_colour(COLOURS[int(active)][button_state])

func change_text(text : String) -> void:
	button.text = text

func change_icon(icon : CompressedTexture2D) -> void:
	NormalContainer.get_node('NormalIcon').texture = icon
	PressedContainer.get_node('PressedIcon').texture = icon

func set_colour(colour : String) -> void:
	NormalCentre.modulate = Color(colour)

func set_disabled(disable : bool) -> void:
	disabled = disable
	button.disabled = disabled
	
	if disable:
		self.modulate.a = DISABLED_ALPHA
	else:
		self.modulate.a = 1.0

func is_hovered():
	return button.is_hovered()

func _on_Button_pressed():
	emit_signal('pressed')
	
func _make_custom_tooltip(for_text):
	print('Tooltip')
	var tooltip : Control = preload("res://Scenes and Scripts/UI/Tooltip.tscn").instantiate()
	
	tooltip.get_node('Label').text = for_text
	
	return tooltip
