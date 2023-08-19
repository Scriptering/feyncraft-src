extends Sprite2D

#temp

@onready var Level = get_tree().get_nodes_in_group('level')[0]
@onready var Heart = get_node('Heart')

@export var Scale : float = 1.0
@export var normal_offset: Vector2
@export var normal_heart_offset: Vector2

var angry := false
var glowing := false: set = _set_glowing
var playing := false
var current_cursor := GLOBALS.CURSOR.default
var override = false

var connected_buttons := []
var connected_scrollcontainers := []
var connected_sliders := []

var scrolling : bool = false
var deleting : bool = false
var scroll_hovering := false

var point := load('res://Textures/Cursors/cursor_point.png')
var hold := load('res://Textures/Cursors/cursor_hold.png')
var snip := load('res://Textures/Cursors/cursor_snip.png')
var snipped := load('res://Textures/Cursors/cursor_snipped.png')
var middle := load('res://Textures/Cursors/cursor_middle.png')
var hover := load('res://Textures/Cursors/cursor_hover.png')
var press := load('res://Textures/Cursors/cursor_press.png')
var disabled := load('res://Textures/Cursors/cursor_disabled.png')

var cursors := [0, point, hold, snip, snipped, middle, hover, press, disabled]

func _ready():
	Heart.visible = false
	
	scale = Vector2(Scale, Scale)
	
	offset = Scale * normal_offset
	Heart.offset = Scale * normal_heart_offset
	
#	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _input(event: InputEvent) -> void:
#	if Input.mouse_mode != Input.MOUSE_MODE_HIDDEN:
#		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	if event is InputEventKey:
		if check_love():
			self.glowing = !glowing
		
		if check_anger():
			self.angry = !angry
			change_cursor(GLOBALS.CURSOR.default)

func check_anger() -> bool:
	if !(
		Input.is_action_just_pressed("F") or
		Input.is_action_just_pressed("U") or
		Input.is_action_just_pressed("C") or 
		Input.is_action_just_pressed("K")
	): return false
	
	return (
		Input.is_action_pressed("F") and
		Input.is_action_pressed("U") and
		Input.is_action_pressed("C") and
		Input.is_action_pressed("K") 
	)

func check_love() -> bool:
	if !(
		Input.is_action_just_pressed("L") or
		Input.is_action_just_pressed("O") or
		Input.is_action_just_pressed("V") or 
		Input.is_action_just_pressed("E")
	): return false
	
	return (
		Input.is_action_pressed("L") and
		Input.is_action_pressed("O") and
		Input.is_action_pressed("V") and
		Input.is_action_pressed("E") 
	)

func _set_glowing(new_value : bool) -> void:
	glowing = new_value
	Heart.visible = new_value

func _process(_delta):
	position = get_global_mouse_position()

func change_cursor(cursor: GLOBALS.CURSOR):
	if cursor == GLOBALS.CURSOR.default:
		if hovering_disabled_button():
			cursor = GLOBALS.CURSOR.disabled
		elif angry:
			cursor = GLOBALS.CURSOR.middle
		else:
			cursor = GLOBALS.CURSOR.point
	
	if cursor != current_cursor:
		texture = cursors[cursor]
		Input.set_custom_mouse_cursor(cursors[cursor], Input.CURSOR_ARROW, Vector2(12, 6))
		current_cursor = cursor

func hovering_disabled_button() -> bool:
	var buttons = get_tree().get_nodes_in_group('UIbuttons')
	
	for button in buttons:
		if button.is_hovered() and button.disabled:
			return true
	
	return false
