extends CheckButton

signal hide_tooltip

func _toggled(_button_pressed: bool) -> void:
	emit_signal("hide_tooltip")
