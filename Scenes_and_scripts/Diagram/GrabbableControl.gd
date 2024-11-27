extends Control
class_name GrabbableControl

signal grab_area_clicked(object: GrabbableControl)
signal picked_up(object: GrabbableControl)
signal dropped(object: GrabbableControl)

@export var grab_area: Control
@export var follow_cursor: bool = true

var grabbed: bool = false: set = _grabbed_changed
var grab_area_hovered: bool = false: set = _grab_area_hovered_changed
var grabbable: bool = true: set = _grabbable_changed
var drag_vector_start: Vector2
var start_position: Vector2
var drag_finger_index: int = 1

func _ready() -> void:
	add_to_group("grabbable")
	
	grab_area.gui_input.connect(_grab_area_gui_input)
	grab_area.mouse_entered.connect(_on_GrabArea_mouse_entered)
	grab_area.mouse_exited.connect(_on_GrabArea_mouse_exited)

func _input(event: InputEvent) -> void:
	if !grabbed:
		return
	
	handle_drag(event)

func _grab_area_gui_input(event: InputEvent) -> void:
	if grabbed:
		return
	
	if is_event_clicked_on(event):
		#get_viewport().set_input_as_handled()
		grab_area_clicked.emit(self)
		EventBus.grabbable_object_clicked.emit(self)

func is_event_clicked_on(event: InputEvent) -> bool:
	if Globals.is_on_mobile():
		if event is InputEventScreenTouch and event.pressed:
			drag_finger_index=event.index
			drag_vector_start = -(grab_area.position + event.position)
			return true
	elif (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.is_pressed()
	):
		drag_vector_start = position - get_global_mouse_position()
		return true
	
	return false

func handle_drag(event: InputEvent) -> void:
	if !follow_cursor:
		return
	
	if Globals.is_on_mobile():
		if event is InputEventScreenDrag and event.index == drag_finger_index:
			position = event.position + drag_vector_start
	elif event is InputEventMouseMotion:
		position = get_global_mouse_position() + drag_vector_start

func pick_up() -> void:
	grabbed = true
	start_position = position
	picked_up.emit(self)

func drop() -> void:
	grabbed = false
	dropped.emit(self)

func can_be_grabbed() -> bool:
	return grabbable

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
