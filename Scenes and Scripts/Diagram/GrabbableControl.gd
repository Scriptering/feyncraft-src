extends Control
class_name GrabbableControl

signal grab_area_clicked
signal picked_up
signal dropped

@export
var GrabAreas: Array[Node]

var grabbed: bool = false: set = _grabbed_changed
var grab_area_hovered: bool = false: set = _grab_area_hovered_changed
var grabbable: bool = true: set = _grabbable_changed

func _ready():
	add_to_group("grabbable")
	
	for GrabArea in GrabAreas:
		GrabArea.mouse_entered.connect(_on_GrabArea_mouse_entered)
		GrabArea.mouse_exited.connect(_on_GrabArea_mouse_exited)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("click") and grab_area_hovered:
		emit_signal("grab_area_clicked", self)

func pick_up() -> void:
	grabbed = true
	emit_signal("picked_up", self)

func drop() -> void:
	grabbed = false
	emit_signal("dropped", self)

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

