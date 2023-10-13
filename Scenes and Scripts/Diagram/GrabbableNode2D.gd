extends Node2D
class_name GrabbableNode2D

signal grab_area_clicked
signal picked_up
signal dropped(object: GrabbableNode2D)

@export
var GrabArea: Node

var grabbed: bool = false: set = _grabbed_changed
var grab_area_hovered: bool = false: set = _grab_area_hovered_changed
var grabbable: bool = true: set = _grabbable_changed

func _ready():
	add_to_group("grabbable")
	GrabArea.mouse_entered.connect(_on_GrabArea_mouse_entered)
	GrabArea.mouse_exited.connect(_on_GrabArea_mouse_exited)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("click") and grab_area_hovered:
		grab_area_clicked.emit(self)

func pick_up() -> void:
	if !grabbed:
		grabbed = true
		picked_up.emit(self)

func drop() -> void:
	if grabbed:
		grabbed = false
		dropped.emit(self)

func can_be_grabbed() -> bool:
	return grabbable and grab_area_hovered

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
