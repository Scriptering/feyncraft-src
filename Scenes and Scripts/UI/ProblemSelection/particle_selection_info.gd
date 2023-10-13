extends InfoPanel

@onready var check_button: CheckButton = $VBoxContainer/VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/CheckButton

func _next() -> void:
	GLOBALS.creating_problem.hide_unavailable_particles = check_button.button_pressed
	
	next.emit()
