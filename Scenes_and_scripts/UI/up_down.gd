extends VBoxContainer

signal up_pressed
signal down_pressed

func _on_up_pressed() -> void:
	up_pressed.emit()

func _on_down_pressed() -> void:
	down_pressed.emit()
