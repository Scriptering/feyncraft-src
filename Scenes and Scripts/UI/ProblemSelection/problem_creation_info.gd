extends InfoPanel

var has_particles: bool = false
var quantum_numbers_matching: bool = true
var energy_conserved: bool = true

@onready var Degree: SpinBox = $VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/DegreeContainer/DegreeContainer/Degree
@onready var check_button: CheckButton = $VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/CheckButton

func disable_next_button() -> void:
	$VBoxContainer/Buttons/NextStep.disabled = !(quantum_numbers_matching and has_particles and energy_conserved)

func toggle_invalid_quantum_numbers(valid: bool) -> void:
	quantum_numbers_matching = valid
	
	$VBoxContainer/VBoxContainer/InvalidQuantumNumbers.visible = !quantum_numbers_matching
	disable_next_button()

func toggle_no_particles(_has_particles: bool) -> void:
	has_particles = _has_particles
	
	$VBoxContainer/VBoxContainer/NoParticles.visible = !has_particles
	disable_next_button()

func toggle_energy_not_conserved(_energy_conserved: bool) -> void:
	energy_conserved = _energy_conserved
	
	$VBoxContainer/VBoxContainer/EnergyNotConserved.visible = !energy_conserved
	disable_next_button()

func _on_check_button_toggled(button_pressed: bool) -> void:
	$VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/DegreeContainer.visible = button_pressed

func _next() -> void:
	GLOBALS.creating_problem.custom_degree = check_button.button_pressed
	
	if check_button.button_pressed:
		GLOBALS.creating_problem.degree = int(Degree.value)
	else:
		GLOBALS.creating_problem.degree = Problem.LOWEST_ORDER
	
	next.emit()

func show_no_solutions_found() -> void:
	$VBoxContainer/VBoxContainer/NoSolutions.show()

func hide_no_solutions_found() -> void:
	$VBoxContainer/VBoxContainer/NoSolutions.hide()

func _on_degree_value_changed(_value: float) -> void:
	hide_no_solutions_found()
