extends Node

@onready var TitleDiagram : DrawingMatrix = ResourceLoader.load("res://saves/Diagrams/title_diagram.tres")

enum Scene {Level, MainMenu}
enum Vision {Colour, Shade, Strength, None}

var in_main_menu: bool = true
var load_mode: int = Mode.Sandbox
var creating_problem: Problem = Problem.new()
var creating_problem_set_file: String = ''
var load_problem_set: ProblemSet = ProblemSet.new()
var problem_selection_menu_position: Vector2
var problem_selection_menu_showing: bool

enum STATE_LINE {INITIAL, FINAL}

enum Cursor {default, point, hold, snip, snipped, middle, hover, press, disabled, confused, loving}

const vision_colours : Array = [
	[Color('c13e3e'), Color('3ec13e'), Color('4057be')],
	[Color('fff7ed'), Color('000000'), Color('727272')]
]

@onready var particle_textures := {}

var is_on_editor: bool
var is_using_finger: bool = false:
	set(new_using_finger):
		if is_using_finger == new_using_finger:
			return
		is_using_finger = new_using_finger
		EventBus.using_touchscreen_changed.emit(is_using_finger)

var has_used_mouse_this_frame: bool = false
var has_used_touch_this_frame: bool = false

func _ready() -> void:
	is_on_editor = OS.has_feature("editor")

func _process(delta: float) -> void:
	if !(has_used_touch_this_frame or has_used_mouse_this_frame):
		return
	
	self.is_using_finger = has_used_touch_this_frame
	has_used_mouse_this_frame = false
	has_used_touch_this_frame = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		has_used_touch_this_frame = true
		if event.pressed:
			EventBus.press.emit(event.position)
	
	elif event is InputEventScreenDrag:
		has_used_touch_this_frame = true
	elif event is InputEventMouse:
		has_used_mouse_this_frame = true
		
		if (
			!is_on_mobile()
			and event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
		):
			EventBus.press.emit(event.position)

func is_on_mobile() -> bool:
	return is_using_finger
