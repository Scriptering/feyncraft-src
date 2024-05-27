extends Sprite2D

@onready var Heart = get_node('Heart')

@export var Scale : float = 1.0
@export var normal_offset: Vector2
@export var normal_heart_offset: Vector2

var angry := false
var glowing := false: set = _set_glowing
var playing := false
var current_cursor : int = GLOBALS.Cursor.default

const CURSOR_FOLDER_PATH : String = 'res://Textures/Cursors/'

var point := load(CURSOR_FOLDER_PATH + 'cursor_point.png')

var cursors: Dictionary = {
	GLOBALS.Cursor.point: load(CURSOR_FOLDER_PATH + 'cursor_point.png'.trim_suffix(".import")),
	GLOBALS.Cursor.hold : load(CURSOR_FOLDER_PATH + 'cursor_hold.png'.trim_suffix(".import")),
	GLOBALS.Cursor.snip : load(CURSOR_FOLDER_PATH + 'cursor_snip.png'.trim_suffix(".import")),
	GLOBALS.Cursor.snipped : load(CURSOR_FOLDER_PATH + 'cursor_snipped.png'.trim_suffix(".import")),
	GLOBALS.Cursor.middle : load(CURSOR_FOLDER_PATH + 'cursor_middle.png'.trim_suffix(".import")),
	GLOBALS.Cursor.hover : load(CURSOR_FOLDER_PATH + 'cursor_hover.png'.trim_suffix(".import")),
	GLOBALS.Cursor.press : load(CURSOR_FOLDER_PATH + 'cursor_press.png'.trim_suffix(".import")),
	GLOBALS.Cursor.disabled : load(CURSOR_FOLDER_PATH + 'cursor_disabled.png'.trim_suffix(".import")),
	GLOBALS.Cursor.loving : load(CURSOR_FOLDER_PATH + 'loving.png'.trim_suffix(".import")),
	GLOBALS.Cursor.confused : load(CURSOR_FOLDER_PATH + 'confused.png'.trim_suffix(".import")),
}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	Heart.visible = false
	
	scale = Vector2(Scale, Scale)
	
	offset = Scale * normal_offset
	Heart.offset = Scale * normal_heart_offset
	
	EVENTBUS.signal_change_cursor.connect(change_cursor)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if check_love():
			self.glowing = !glowing
		
		if check_anger():
			self.angry = !angry
			change_cursor(GLOBALS.Cursor.default)

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
	if visible:
		position = get_global_mouse_position()

func get_default_cursor() -> GLOBALS.Cursor:
	if angry and glowing:
		return GLOBALS.Cursor.confused
	
	if angry:
		return GLOBALS.Cursor.middle

	if glowing:
		return GLOBALS.Cursor.loving
	
	return GLOBALS.Cursor.point

func change_cursor(cursor: GLOBALS.Cursor):
	if cursor == GLOBALS.Cursor.default:
		cursor = get_default_cursor()
	
	if cursor != current_cursor:
		texture = cursors[cursor]
		
#		Input.set_custom_mouse_cursor(cursors[cursor], Input.CURSOR_ARROW, Vector2(12, 6))
		current_cursor = cursor
