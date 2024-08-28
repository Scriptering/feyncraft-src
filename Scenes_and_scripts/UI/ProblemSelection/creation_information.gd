extends GrabbableControl

signal submit_problem
signal toggle_all(toggle: bool)
signal next
signal prev

var active_modes: Array[Mode.] = [
	Mode.ParticleSelection,
	Mode.ProblemCreation,
	Mode.SolutionCreation
]

var Level: Node2D
var problem: Problem

@export_group("Children")
@export var tab_container:TabContainer
@export var particle_selection:InfoPanel
@export var problem_creation:InfoPanel
@export var solution_creation:InfoPanel
@export var title:Label
@export var submit:PanelButton
@export var next_button:PanelButton
@export var prev_button:PanelButton

var submitted_diagrams: Array[DrawingMatrix] = []

func set_title() -> void:
	title.text = tab_container.get_current_tab_control().title
	
func init(level: Node2D, problem_tab: Node) -> void:
	Level = level
	set_title()
	
	solution_creation.init(problem_tab)

func reset() -> void:
	tab_container.current_tab = Mode.ParticleSelection
	set_title()

func change_mode(mode_index: int) -> void:
	tab_container.current_tab = mode_index
	Level.current_mode = active_modes[mode_index]
	
	prev_button.visible = mode_index != Mode.ParticleSelection
	next_button.visible = mode_index != Mode.SolutionCreation
	submit.visible = mode_index == Mode.SolutionCreation
	
	set_title()

func next_mode() -> void:
	next.emit()
	change_mode(active_modes.find(Level.current_mode) + 1)

func prev_mode() -> void:
	change_mode(active_modes.find(Level.current_mode) - 1)

func _on_problem_creation_info_next() -> void:
	problem_creation.hide_no_solutions_found()

	Globals.creating_problem.custom_degree = problem_creation.custom_degree
	
	if problem_creation.custom_degree:
		Globals.creating_problem.degree = problem_creation.degree
	else:
		Globals.creating_problem.degree = Problem.LOWEST_ORDER

	next.emit()

func _on_solution_creation_info_exit() -> void:
	problem.custom_solutions = solution_creation.custom_solutions
	problem.allow_other_solutions = solution_creation.allow_other_solutions
	problem.custom_solution_count = solution_creation.custom_solution_count

	if solution_creation.custom_solutions:
		problem.solutions = submitted_diagrams

	if solution_creation.custom_solution_count:
		problem.solution_count = solution_creation.solution_count
	
	submit_problem.emit()

func _on_solution_creation_info_previous() -> void:
	prev_mode()

func _on_problem_creation_info_previous() -> void:
	prev_mode()

func no_solutions_found() -> void:
	problem_creation.show_no_solutions_found()

func _on_particle_selection_info_toggle_all(toggle: bool) -> void:
	toggle_all.emit(toggle)

func update_problem_creation(
	quantum_numbers_matching: bool,
	has_particles: bool,
	energy_is_conserved: bool
) -> void:
	
	next_button.disabled = !(
		quantum_numbers_matching and
		has_particles and
		energy_is_conserved
	)

	problem_creation.hide_no_solutions_found()
	problem_creation.toggle_invalid_quantum_numbers(quantum_numbers_matching)
	problem_creation.toggle_no_particles(has_particles)
	problem_creation.toggle_energy_not_conserved(energy_is_conserved)

func _on_diagram_submitted(diagram: DrawingMatrix, submitted_diagrams: Array[DrawingMatrix]) -> void:
	if solution_creation.custom_solutions:
		solution_creation.solution_count_spinbox.max_value = submitted_diagrams.size()
	else:
		solution_creation.solution_count_spinbox.max_value = 5
	
	var no_solutions: bool = submitted_diagrams.size() == 0
	solution_creation.update_no_solutions(no_solutions)
	submit.disabled = no_solutions
