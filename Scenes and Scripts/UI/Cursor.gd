extends Sprite2D

@onready var Heart := get_node('Heart')

@export var Scale : float = 1.0
@export var normal_offset: Vector2
@export var normal_heart_offset: Vector2

var angry := false
var glowing := false: set = _set_glowing
var playing := false
var current_cursor : int = Globals.Cursor.default

const CURSOR_FOLDER_PATH : String = 'res://Textures/Cursors/'

var point := load(CURSOR_FOLDER_PATH + 'cursor_point.png')

var cursors: Dictionary = {
	Globals.Cursor.point: load(CURSOR_FOLDER_PATH + 'cursor_point.png'.trim_suffix(".import")),
	Globals.Cursor.hold : load(CURSOR_FOLDER_PATH + 'cursor_hold.png'.trim_suffix(".import")),
	Globals.Cursor.snip : load(CURSOR_FOLDER_PATH + 'cursor_snip.png'.trim_suffix(".import")),
	Globals.Cursor.snipped : load(CURSOR_FOLDER_PATH + 'cursor_snipped.png'.trim_suffix(".import")),
	Globals.Cursor.middle : load(CURSOR_FOLDER_PATH + 'cursor_middle.png'.trim_suffix(".import")),
	Globals.Cursor.hover : load(CURSOR_FOLDER_PATH + 'cursor_hover.png'.trim_suffix(".import")),
	Globals.Cursor.press : load(CURSOR_FOLDER_PATH + 'cursor_press.png'.trim_suffix(".import")),
	Globals.Cursor.disabled : load(CURSOR_FOLDER_PATH + 'cursor_disabled.png'.trim_suffix(".import")),
	Globals.Cursor.loving : load(CURSOR_FOLDER_PATH + 'loving.png'.trim_suffix(".import")),
	Globals.Cursor.confused : load(CURSOR_FOLDER_PATH + 'confused.png'.trim_suffix(".import")),
}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	Heart.visible = false
	
	scale = Vector2(Scale, Scale)
	
	offset = Scale * normal_offset
	Heart.offset = Scale * normal_heart_offset
	
	EventBus.change_cursor.connect(change_cursor)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if check_love():
			self.glowing = !glowing
		
		if check_anger():
			self.angry = !angry
			change_cursor(Globals.Cursor.default)

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

func _process(_delta: float) -> void:
	if visible:
		position = get_global_mouse_position()

func get_default_cursor() -> Globals.Cursor:
	if angry and glowing:
		return Globals.Cursor.confused
	
	if angry:
		return Globals.Cursor.middle

	if glowing:
		return Globals.Cursor.loving
	
	return Globals.Cursor.point

func change_cursor(cursor: Globals.Cursor) -> void:
	if cursor == Globals.Cursor.default:
		cursor = get_default_cursor()
	
	if cursor != current_cursor:
		texture = cursors[cursor]

		current_cursor = cursor
