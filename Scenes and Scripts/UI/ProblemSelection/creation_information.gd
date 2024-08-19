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

@export_group("Children")
@export var tab_container:TabContainer
@export var particle_selection:InfoPanel
@export var problem_creation:InfoPanel
@export var solution_creation:InfoPanel
@export var title:Label


func _process(delta: float) -> void:
	if Level.current_mode != BaseMode.Mode.ProblemCreation:
		return
	
	problem_creation.toggle_invalid_quantum_numbers(Diagram.are_quantum_numbers_matching())
	problem_creation.toggle_no_particles(
		Diagram.StateLines.any(
			func(state_line: StateLine) -> bool:
				return state_line.get_connected_lines().size() > 0)
	)
	problem_creation.toggle_energy_not_conserved(Diagram.is_energy_conserved())

func set_title() -> void:
	title.text = tab_container.get_current_tab_control().title
	
func init(diagram: MainDiagram, level: Node2D, problem_tab: Node) -> void:
	Diagram = diagram
	Level = level
	set_title()
	
	solution_creation.init(problem_tab)
	
	Diagram.action_taken.connect(problem_creation.hide_no_solutions_found)

func reset() -> void:
	tab_container.current_tab = 0
	set_title()

func change_mode(mode_index: int) -> void:
	tab_container.current_tab = mode_index
	Level.current_mode = active_modes[mode_index]
	set_title()

func next_mode() -> void:
	change_mode(active_modes.find(Level.current_mode) + 1)

func prev_mode() -> void:
	change_mode(active_modes.find(Level.current_mode) - 1)

func _on_particle_selection_info_next() -> void:
	next_mode()

func _on_problem_creation_info_next() -> void:
	problem_creation.hide_no_solutions_found()
	next_mode()

func _on_solution_creation_info_exit() -> void:
	submit_problem.emit()

func _on_solution_creation_info_previous() -> void:
	prev_mode()

func _on_problem_creation_info_previous() -> void:
	prev_mode()

func no_solutions_found() -> void:
	problem_creation.show_no_solutions_found()

func _on_particle_selection_info_toggle_all(toggle: bool) -> void:
	toggle_all.emit(toggle)
