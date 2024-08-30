extends SpinBox

var previous_placeholder_text: String = ''
@onready var line_edit: LineEdit = get_line_edit()

func _ready() -> void:
	previous_placeholder_text = line_edit.placeholder_text
	
	value_changed.connect(_on_value_changed)
	
	line_edit.focus_entered.connect(_on_focus_entered)
	line_edit.focus_exited.connect(_on_focus_exited)
	
	line_edit.caret_blink = true
	line_edit.use_parent_material = true

func _input(_event: InputEvent) -> void:
	if !line_edit.has_focus():
		return
	
	if Input.is_action_just_pressed("submit"):
		line_edit.release_focus()
		if editable:
			value_changed.emit(value)
	
	elif Input.is_action_just_pressed("click") and !line_edit.get_global_rect().has_point(get_global_mouse_position()):
		line_edit.release_focus()
		if editable:
			value_changed.emit(value)

func _on_value_changed(_value: int) -> void:
	line_edit.release_focus()

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
