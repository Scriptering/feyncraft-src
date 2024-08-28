extends CheckButton

signal hide_tooltip

func _toggled(button_pressed: bool) -> void:
	hide_tooltip.emit()
	
	match button_pressed:
		true:
			SOUNDBUS.button_down()
		false:
			SOUNDBUS.button_up()
