extends Control

signal submit_problem

var active_modes: Array[BaseMode.Mode] = [
	BaseMode.Mode.ParticleSelection,
	BaseMode.Mode.ProblemCreation,
	BaseMode.Mode.SolutionCreation
]

var Diagram: MainDiagram
var Level: Node2D

func _process(_delta: float) -> void:
	if Level.current_mode != BaseMode.Mode.ProblemCreation:
		return
	
	$TabContainer/ProblemCreationInfo.toggle_invalid_quantum_numbers(Diagram.are_quantum_numbers_matching())
	$TabContainer/ProblemCreationInfo.toggle_no_particles(
		Diagram.StateLines.any(func(state_line: StateLine): return state_line.get_connected_lines().size() > 0)
	)
	
func init(diagram: MainDiagram, level: Node2D) -> void:
	Diagram = diagram
	Level = level

func change_mode(mode_index: int) -> void:
	$TabContainer.current_tab = mode_index
	Level.current_mode = active_modes[mode_index]

func next_mode() -> void:
	change_mode(active_modes.find(Level.current_mode) + 1)

func prev_mode() -> void:
	change_mode(active_modes.find(Level.current_mode) - 1)

func _on_particle_selection_info_next() -> void:
	next_mode()

func _on_problem_creation_info_next() -> void:
	next_mode()

func _on_solution_creation_info_exit() -> void:
	submit_problem.emit()

func _on_solution_creation_info_previous() -> void:
	prev_mode()

func _on_problem_creation_info_previous() -> void:
	prev_mode()
