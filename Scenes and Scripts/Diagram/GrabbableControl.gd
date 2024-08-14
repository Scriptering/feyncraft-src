extends Control
class_name GrabbableControl

signal grab_area_clicked
signal picked_up(object: GrabbableControl)
signal dropped(object: GrabbableControl)

@export var GrabAreas: Array[Node]
@export var follow_cursor: bool = true

var grabbed: bool = false: set = _grabbed_changed
var grab_area_hovered: bool = false: set = _grab_area_hovered_changed
var grabbable: bool = true: set = _grabbable_changed
var drag_vector_start: Vector2
var start_position: Vector2

func _ready() -> void:
	add_to_group("grabbable")
	
	for GrabArea in GrabAreas:
		GrabArea.mouse_entered.connect(_on_GrabArea_mouse_entered)
		GrabArea.mouse_exited.connect(_on_GrabArea_mouse_exited)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("click") and grab_area_hovered:
		grab_area_clicked.emit(self)

func _process(_delta:float) -> void:
	if grabbed and follow_cursor:
		position = get_global_mouse_position() + drag_vector_start

func pick_up() -> void:
	grabbed = true
	drag_vector_start = position - get_global_mouse_position()
	start_position = position
	picked_up.emit(self)

func drop() -> void:
	grabbed = false
	dropped.emit(self)

func can_be_grabbed() -> bool:
	return grabbable and grab_area_hovered

func _on_GrabArea_mouse_entered() -> void:
	grab_area_hovered = true

func _on_GrabArea_mouse_exited() -> void:
	grab_area_hovered = false

func _grabbed_changed(new_value: bool) -> void:
	grabbed = new_value

func _grab_area_hovered_changed(new_value: bool) -> void:
	grab_area_hovered = new_value

func _grabbable_changed(new_value: bool) -> void:
	grabbable = new_value
