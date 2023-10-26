extends GrabbableControl

signal submit_problem
signal toggle_all(toggle: bool)

var active_modes: Array[BaseMode.Mode] = [
	BaseMode.Mode.ParticleSelection,
	BaseMode.Mode.ProblemCreation,
	BaseMode.Mode.SolutionCreation
]

var Diagram: MainDiagram
var Level: Node2D

@onready var InfoContainer: TabContainer = $VBoxContainer/TabContainer

func _process(delta: float) -> void:
	super._process(delta)
	
	if Level.current_mode != BaseMode.Mode.ProblemCreation:
		return
	
	$VBoxContainer/TabContainer/ProblemCreationInfo.toggle_invalid_quantum_numbers(Diagram.are_quantum_numbers_matching())
	$VBoxContainer/TabContainer/ProblemCreationInfo.toggle_no_particles(
		Diagram.StateLines.any(func(state_line: StateLine): return state_line.get_connected_lines().size() > 0)
	)
	$VBoxContainer/TabContainer/ProblemCreationInfo.toggle_energy_not_conserved(Diagram.is_energy_conserved())

func set_title() -> void:
	$VBoxContainer/TitleContainer/Title.text = InfoContainer.get_current_tab_control().title
	
func init(diagram: MainDiagram, level: Node2D, problem_tab: Node) -> void:
	Diagram = diagram
	Level = level
	set_title()
	
	$VBoxContainer/TabContainer/SolutionCreationInfo.init(problem_tab)
	
	Diagram.action_taken.connect(
		$VBoxContainer/TabContainer/ProblemCreationInfo.hide_no_solutions_found
	)

func reset() -> void:
	InfoContainer.current_tab = 0
	set_title()

func change_mode(mode_index: int) -> void:
	InfoContainer.current_tab = mode_index
	Level.current_mode = active_modes[mode_index]
	set_title()

func next_mode() -> void:
	change_mode(active_modes.find(Level.current_mode) + 1)

func prev_mode() -> void:
	change_mode(active_modes.find(Level.current_mode) - 1)

func _on_particle_selection_info_next() -> void:
	next_mode()

func _on_problem_creation_info_next() -> void:
	$VBoxContainer/TabContainer/ProblemCreationInfo.hide_no_solutions_found()
	next_mode()

func _on_solution_creation_info_exit() -> void:
	submit_problem.emit()

func _on_solution_creation_info_previous() -> void:
	prev_mode()

func _on_problem_creation_info_previous() -> void:
	prev_mode()

func no_solutions_found() -> void:
	$VBoxContainer/TabContainer/ProblemCreationInfo.show_no_solutions_found()

func _on_particle_selection_info_toggle_all(toggle: bool) -> void:
	toggle_all.emit(toggle)
