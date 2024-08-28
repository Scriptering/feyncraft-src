extends InfoPanel

signal toggle_all(toggle: bool)

@export var check_button: CheckButton

func _next() -> void:
	Globals.creating_problem.hide_unavailable_particles = check_button.button_pressed
	
	next.emit()

func _on_toggle_on_pressed() -> void:
	toggle_all.emit(true)

func _on_toggle_off_pressed() -> void:
	toggle_all.emit(false)
