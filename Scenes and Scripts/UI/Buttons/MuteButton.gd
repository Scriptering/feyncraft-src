@tool

extends PanelButton

func _ready() -> void:
	super._ready()
	self.button_pressed = !AudioServer.is_bus_mute(0)

func _on_button_toggled(button_pressed_state: bool) -> void:
	super._on_button_toggled(button_pressed_state)
	
	SOUNDBUS.mute(!button_pressed_state)
	
	if button_pressed_state:
		icon = load("res://Textures/Buttons/icons/unmute.png")
	else:
		icon = load("res://Textures/Buttons/icons/mute.png")
