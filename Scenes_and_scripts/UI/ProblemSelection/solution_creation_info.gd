extends InfoPanel

var custom_solutions: bool = false
var allow_other_solutions: bool = false
var custom_solution_count: bool = false
var solution_count: int = 4

signal custom_solutions_toggled(toggled: bool)
signal allow_other_solutions_toggled(toggled: bool)

@onready var solution_count_spinbox: SpinBox = %SolutionCount

func set_max_solution_count(max_solution_count: int) -> void:
	solution_count_spinbox.max_value = min(6, max_solution_count)

func update_no_custom_solutions(no_solutions: bool) -> void:
	var toggle: bool = no_solutions and custom_solutions
	%NoSolutions.visible = toggle

func _on_custom_solutions_toggled(button_pressed: bool) -> void:
	%AllowOtherSolutions.visible = button_pressed
	custom_solutions = button_pressed
	
	custom_solutions_toggled.emit(button_pressed)

func _on_allow_other_solutions_toggled(toggled_on: bool) -> void:
	allow_other_solutions = toggled_on
	
	allow_other_solutions_toggled.emit(toggled_on)

func _on_custom_solution_count_toggled(toggled_on: bool) -> void:
	%SolutionCountContainer.visible = toggled_on
	custom_solution_count = toggled_on

func _on_solution_count_value_changed(value: float) -> void:
	solution_count = solution_count_spinbox.value

func enter(problem: Problem) -> void:
	%CustomSolutions.button_pressed = problem.custom_solutions
	%AllowOtherSolutions.button_pressed = problem.allow_other_solutions
	%CustomSolutionCount.button_pressed = problem.custom_solution_count
	%SolutionCount.value = problem.solution_count
