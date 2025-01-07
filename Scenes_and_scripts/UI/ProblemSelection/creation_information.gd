extends GrabbableControl

signal toggle_all(toggle: bool)
signal next_pressed
signal prev_pressed
signal submit_pressed

var active_modes: Array[int] = [
	Mode.ParticleSelection,
	Mode.ProblemCreation,
	Mode.SolutionCreation
]

var problem: Problem

var no_custom_solutions: bool = false

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

func _ready() -> void:
	super()
	reset()
	update_buttons()

func set_title() -> void:
	title.text = tab_container.get_current_tab_control().title
	
func reset() -> void:
	tab_container.current_tab = Mode.ParticleSelection
	set_title()

func change_mode(mode_index: int) -> void:
	tab_container.current_tab = mode_index
	tab_container.get_current_tab_control().enter(problem)

	update_buttons()
	set_title()

func update_buttons() -> void:
	var index:int = $PanelContainer/VBoxContainer/TabContainer.current_tab
	
	prev_button.visible = index != Mode.ParticleSelection
	next_button.visible = index != Mode.SolutionCreation
	
	if index != Mode.ProblemCreation:
		next_button.disabled = false
	
	submit.visible = index == Mode.SolutionCreation

func no_solutions_found() -> void:
	problem_creation.show_no_solutions_found()

func no_particles() -> void:
	problem_creation.toggle_no_particles(true)

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
	problem_creation.toggle_invalid_quantum_numbers(!quantum_numbers_matching)
	problem_creation.toggle_no_particles(!has_particles)
	problem_creation.toggle_energy_not_conserved(!energy_is_conserved)

func update_no_custom_solutions() -> void:
	if problem.custom_solutions:
		solution_creation.update_no_custom_solutions(no_custom_solutions)
		submit.disabled = no_custom_solutions
	else:
		solution_creation.update_no_custom_solutions(false)
		submit.disabled = false

func toggle_no_custom_solutions(toggle: bool) -> void:
	no_custom_solutions = toggle
	update_no_custom_solutions()

func _on_prev_step_pressed() -> void:
	prev_pressed.emit()

func _on_next_step_pressed() -> void:
	next_pressed.emit()

func _on_submit_pressed() -> void:
	submit_pressed.emit()

func get_custom_solutions() -> bool:
	return solution_creation.custom_solutions

func get_allow_other_solutions() -> bool:
	return solution_creation.allow_other_solutions

func get_has_custom_solution_count() -> bool:
	return solution_creation.custom_solution_count

func get_custom_solution_count() -> int:
	return solution_creation.solution_count

func get_custom_degree() -> bool:
	return problem_creation.custom_degree

func get_degree() -> int:
	return problem_creation.degree

func get_hide_unavailable_particles() -> bool:
	return particle_selection.hide_unavailable_particles
