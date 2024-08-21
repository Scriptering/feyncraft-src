extends Node2D
class_name GrabbableNode2D

signal grab_area_clicked
signal picked_up
signal dropped(object: GrabbableNode2D)

@export
var GrabArea: Node

var start_grab_position: Vector2 = Vector2.ZERO
var grabbed: bool = false: set = _grabbed_changed
var grab_area_hovered: bool = false: set = _grab_area_hovered_changed
var grabbable: bool = true: set = _grabbable_changed
var drag_finger_index: int

func _ready() -> void:
	add_to_group("grabbable")
	GrabArea.mouse_entered.connect(_on_GrabArea_mouse_entered)
	GrabArea.mouse_exited.connect(_on_GrabArea_mouse_exited)
#
#func _input(event: InputEvent) -> void:
	#if grabbed:
		#return
	#elif is_event_clicked_on(event):
		#get_viewport().set_input_as_handled()
		#grab_area_clicked.emit(self)
		#EventBus.grabbable_object_clicked.emit(self)

#func is_event_clicked_on(event: InputEvent) -> bool:
	#if Globals.is_on_mobile():
		#if !(
			#event is InputEventScreenDrag
			#or (event is InputEventScreenTouch and event.pressed)
		#):
			#return false
		#
		#if GrabArea.get_global_rect().has_point(event.position):
			#drag_finger_index = event.index
			#return true
		#
		#return false
		#
	#elif Input.is_action_just_pressed("click") and grab_area_hovered:
		#return true
	#
	#return false

func pick_up() -> void:
	if !grabbed:
		grabbed = true
		start_grab_position = position
		picked_up.emit(self)

func drop() -> void:
	if grabbed:
		grabbed = false
		dropped.emit(self)

func can_be_grabbed() -> bool:
	return grabbable

func _on_GrabArea_mouse_entered() -> void:
	self.grab_area_hovered = true

func _on_GrabArea_mouse_exited() -> void:
	self.grab_area_hovered = false

func _grabbed_changed(new_value: bool) -> void:
	grabbed = new_value

func _grab_area_hovered_changed(new_value: bool) -> void:
	grab_area_hovered = new_value

func _grabbable_changed(new_value: bool) -> void:
	grabbable = new_value
