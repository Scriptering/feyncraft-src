extends GrabbableControl

@export var message_id : int = 2

func _on_close_pressed() -> void:
	hide()

func _on_dog_mouse_entered() -> void:
	EventBus.toggle_cursor_heart.emit(true)

func _on_dog_mouse_exited() -> void:
	EventBus.toggle_cursor_heart.emit(false)
