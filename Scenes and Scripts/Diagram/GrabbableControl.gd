extends Control
class_name GrabbableControl

signal grab_area_clicked(object: GrabbableControl)
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

func _input(event: InputEvent) -> void:
	if !is_visible_in_tree():
		return
	
	if is_event_clicked_on(event):
		get_viewport().set_input_as_handled()
		grab_area_clicked.emit(self)
		EventBus.grabbable_object_clicked.emit(self)
	
	if grabbed:
		handle_drag(event)

func is_event_clicked_on(event: InputEvent) -> bool:
	if Globals.is_on_mobile():
		if !event is InputEventScreenTouch:
			return false
		
		if !event.is_pressed():
			return false
		
		if GrabAreas.any(
			func(node: Control): 
				return node.get_global_rect().has_point(event.position)
		):
			return true
		
		return false
		
	elif Input.is_action_just_pressed("click") and grab_area_hovered:
		return true
	
	return false

func handle_drag(event: InputEvent) -> void:
	if !follow_cursor:
		return
	
	if Globals.is_on_mobile() and event is InputEventScreenDrag:
		position = event.position + drag_vector_start
	
	elif !Globals.is_on_mobile() and event is InputEventMouseMotion:
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
