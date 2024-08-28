extends SpinBox

var previous_placeholder_text: String = ''
@onready var line_edit: LineEdit = get_line_edit()

func _ready() -> void:
	previous_placeholder_text = line_edit.placeholder_text
	
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
	line_edit.caret_blink = true
	line_edit.use_parent_material = true

func _input(_event: InputEvent) -> void:
	if !has_focus():
		return
	
	if Input.is_action_just_pressed("submit"):
		release_focus()
		if editable:
			value_changed.emit()
	
	elif Input.is_action_just_pressed("click") and !get_global_rect().has_point(get_global_mouse_position()):
		release_focus()
		if editable:
			value_changed.emit()

func _on_focus_entered() -> void:
	line_edit.placeholder_text = ''

func _on_focus_exited() -> void:
	line_edit.placeholder_text = previous_placeholder_text

func _set(property: StringName, new_value: Variant) -> bool:
	if property == "editable":
		editable = new_value
		self.selecting_enabled = new_value
		return true
	
	return false
