extends CheckButton

signal hide_tooltip

func _toggled(button_pressed: bool) -> void:
	emit_signal("hide_tooltip")
	
	match button_pressed:
		true:
			SOUNDBUS.button_down()
		false:
			SOUNDBUS.button_up()
