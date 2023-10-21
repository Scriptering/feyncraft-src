extends LineEdit

var previous_placeholder_text: String = ''

func _ready() -> void:
	previous_placeholder_text = placeholder_text
	
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
	caret_blink = true

func _input(_event: InputEvent) -> void:
	if !has_focus():
		return
	
	if Input.is_action_just_pressed("submit"):
		release_focus()
		if editable:
			text_submitted.emit(text)
	
	elif Input.is_action_just_pressed("click") and !get_global_rect().has_point(get_global_mouse_position()):
		release_focus()
		if editable:
			text_submitted.emit(text)

func _on_focus_entered() -> void:
	placeholder_text = ''

func _on_focus_exited() -> void:
	placeholder_text = previous_placeholder_text

func _set(property: StringName, value: Variant) -> bool:
	if property == "editable":
		editable = value
		self.selecting_enabled = value
		return true
	
	return false
