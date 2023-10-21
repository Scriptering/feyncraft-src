extends InfoPanel

signal toggle_all(toggle: bool)

@onready var check_button: CheckButton = $VBoxContainer/VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/CheckButton

func _next() -> void:
	GLOBALS.creating_problem.hide_unavailable_particles = check_button.button_pressed
	
	next.emit()

func _on_toggle_on_pressed() -> void:
	toggle_all.emit(true)

func _on_toggle_off_pressed() -> void:
	toggle_all.emit(false)
