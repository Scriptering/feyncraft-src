@tool

extends PanelButton

func _ready() -> void:
	super._ready()
	toggle_button(!StatsManager.stats.muted)

func _enter_tree() -> void:
	toggle_button(!AudioServer.is_bus_mute(0))

func toggle_button(toggle: bool) -> void:
	if toggle != button_pressed:
		button_pressed = toggle
	if toggle:
		icon = load("res://Textures/Buttons/icons/unmute.png")
	else:
		icon = load("res://Textures/Buttons/icons/mute.png")

func _on_button_toggled(button_pressed_state: bool) -> void:
	super._on_button_toggled(button_pressed_state)
	
	SOUNDBUS.mute(!button_pressed_state)
	
	toggle_button(button_pressed_state)
