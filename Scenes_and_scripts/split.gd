extends TouchScreenButtonBase

func _on_pressed() -> void:
	Input.action_press("split_interaction")

func _on_released() -> void:
	Input.action_release("split_interaction")
