extends InfoPanel

var custom_degree: bool = false
var degree: int

func toggle_invalid_quantum_numbers(toggle: bool) -> void:
	%InvalidQuantumNumbers.visible = toggle

func toggle_no_particles(toggle: bool) -> void:
	%NoParticles.visible = toggle

func toggle_energy_not_conserved(toggle: bool) -> void:
	%EnergyNotConserved.visible = toggle

func show_no_solutions_found() -> void:
	%NoSolutions.show()

func hide_no_solutions_found() -> void:
	%NoSolutions.hide()

func _on_degree_value_changed(value: float) -> void:
	hide_no_solutions_found()
	degree = value

func _on_custom_degree_toggled(toggled_on: bool) -> void:
	%DegreeContainer.visible = toggled_on
	custom_degree = toggled_on

func enter(problem: Problem) -> void:
	%CustomDegree.button_pressed = problem.custom_degree
	%Degree.value = degree
