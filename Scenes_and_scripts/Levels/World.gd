extends Node2D

signal save_problem_set
signal problem_submitted
signal initialised

@export var test_initial_state: Array = []
@export var test_final_state: Array = []

@onready var ParticleButtons := $PullOutTabs/ParticleButtons
@onready var GenerationTab := $PullOutTabs/GenerationButton
@onready var PuzzleOptions: Control = $PullOutTabs/PuzzleUI
@onready var ProblemTab := $PullOutTabs/ProblemTab
@onready var MenuTab := $PullOutTabs/MenuTab
@onready var VisionTab := $PullOutTabs/VisionButton
@onready var HealthTab := $PullOutTabs/HealthTab
@onready var Diagram: MainDiagram = $Diagram
@onready var Tutorial := $Tutorial
@onready var ControlsTab := $PullOutTabs/ControlsTab
@onready var ExportTab := $PullOutTabs/ExportTab

var StateManager: Node

var previous_mode: int = Mode.Null
var current_mode: int = Mode.Null: set = _set_current_mode
var current_problem: Problem = null
var creating_problem: Problem = null
var problem_set: ProblemSet
var problem_history: Array[Problem] = []

var creation_info : GrabbableControl = null

var mode_enter_funcs : Dictionary = {
	Mode.ParticleSelection: enter_particle_selection,
	Mode.ProblemCreation: enter_problem_creation,
	Mode.SolutionCreation: enter_solution_creation,
	Mode.Sandbox: enter_sandbox,
	Mode.ProblemSolving: enter_problem_solving,
	Mode.Tutorial: enter_tutorial
}

var mode_exit_funcs : Dictionary = {
	Mode.ParticleSelection: exit_particle_selection,
	Mode.ProblemCreation: exit_problem_creation,
	Mode.SolutionCreation: exit_solution_creation,
	Mode.Sandbox: exit_sandbox,
	Mode.ProblemSolving: null,
	Mode.Tutorial: exit_tutorial
}

func _set_current_mode(new_value: int) -> void:
	exit_current_mode()

	previous_mode = current_mode
	current_mode = new_value
	mode_enter_funcs[current_mode].call()
	set_tab_visibility()

func init(state_manager: Node) -> void:
	StateManager = state_manager

	Tutorial.init(self)
	Diagram.init(StateManager)
	GenerationTab.init(Diagram, $FloatingMenus/GeneratedDiagrams)
	ProblemTab.init(Diagram, Problem.new(), $FloatingMenus/SubmittedDiagrams)

	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	ParticleButtons.particle_selected.connect(_on_particle_selected)

	ControlsTab.clear_diagram.connect(_controls_clear)
	ControlsTab.undo.connect(Diagram.undo)
	ControlsTab.redo.connect(Diagram.redo)

	initialised.emit()

	Diagram.action.connect(_diagram_action_taken)
	
	var diagrams: Array[ConnectionMatrix] = SolutionGeneration.generate_diagrams(
		[[ParticleData.Particle.electron], [ParticleData.Particle.anti_electron]],
		[[ParticleData.Particle.electron], [ParticleData.Particle.anti_electron]],
		4,
		4,
		ProblemGeneration.get_useable_particles_from_interaction_checks([true, false, false, false])
	)

func _ready() -> void:
	Diagram.show_line_labels = !StatsManager.stats.hide_labels
	MenuTab.toggle_show_line_labels(!StatsManager.stats.hide_labels)

func _controls_clear() -> void:
	Diagram.add_diagram_to_history()
	Diagram.clear_diagram()

func _on_particle_selected(particle: ParticleData.Particle) -> void:
	Diagram.drawing_particle = particle

func load_problem(problem: Problem) -> void:
	current_problem = problem

	Diagram.load_problem(problem, current_mode)
	ProblemTab.load_problem(problem)
	ParticleButtons.load_problem(problem)

	if current_mode == Mode.ProblemSolving or current_mode == Mode.Tutorial:
		ProblemTab.toggle_finish_icon(problem_set.current_index == problem_set.problems.size() - 1)

func load_problem_set(p_problem_set: ProblemSet, index: int) -> void:
	problem_set = p_problem_set
	
	if !problem_set.end_reached.is_connected(_on_problem_set_end_reached):
		problem_set.end_reached.connect(_on_problem_set_end_reached)
		
	problem_set.current_index = index

	problem_history.clear()
	ProblemTab.set_prev_problem_disabled(index == 0)
	load_problem(problem_set.current_problem)
	ProblemTab.set_next_problem_disabled(index >= problem_set.highest_index_reached)

func enter_particle_selection() -> void:
	Diagram.load_problem(creating_problem, current_mode)
	ParticleButtons.enter_particle_selection(creating_problem)

func exit_particle_selection() -> void:
	ParticleButtons.exit_particle_selection()

func enter_sandbox() -> void:
	ProblemTab._enter_sandbox()
	load_problem(Problem.new())

	Diagram.clear_diagram()
	Diagram.set_title_editable(false)
	Diagram.set_title_visible(false)

func enter_problem_solving() -> void:
	Diagram.set_title_editable(false)

func enter_problem_creation() -> void:
	ParticleButtons.load_problem(creating_problem)
	
	if creating_problem.state_interactions != [[],[]]:
		var diagram: ConnectionMatrix
		for i: int in range(10):
			diagram = SolutionGeneration.generate_diagrams(
				creating_problem.state_interactions[StateLine.State.Initial],
				creating_problem.state_interactions[StateLine.State.Final],
				creating_problem.degree, creating_problem.degree,
				creating_problem.allowed_particles,
				SolutionGeneration.Find.One
			).front()
			
			if diagram:
				break
		
		EventBus.draw_raw_diagram.emit(diagram)
	
	update_problem_creation()

func enter_solution_creation() -> void:
	ProblemTab.load_problem(creating_problem)
	ProblemTab.in_solution_creation = true

func exit_sandbox() -> void:
	ProblemTab._exit_sandbox()

func exit_problem_creation() -> void:
	pass

func exit_solution_creation() -> void:
	ProblemTab._exit_solution_creation()
	ProblemTab.in_solution_creation = false

func enter_tutorial() -> void:
	Tutorial.reset()
	Tutorial.show()
	load_problem_set(load("res://saves/ProblemSets/tutorial.tres"), 0)

func exit_tutorial() -> void:
	Tutorial.clear()
	Tutorial.hide()

	problem_set.highest_index_reached = 0

func _on_problem_set_end_reached() -> void:
	problem_set.end_reached.disconnect(_on_problem_set_end_reached)

	EventBus.signal_change_scene.emit(Globals.Scene.MainMenu)

func _on_next_problem_pressed() -> void:
	problem_history.push_back(current_problem)

	match current_mode:
		Mode.Tutorial:
			load_problem(problem_set.next_problem())
			ProblemTab.set_next_problem_disabled(problem_set.current_index >= problem_set.highest_index_reached)
		Mode.ProblemSolving:
			load_problem(problem_set.next_problem())
			ProblemTab.set_next_problem_disabled(problem_set.current_index >= problem_set.highest_index_reached)
			save_problem_set.emit()
		Mode.Sandbox:
			var new_problem: Problem = generate_new_problem()

			if !new_problem:
				return

			load_problem(new_problem)

	Diagram.clear_diagram()
	ProblemTab.set_prev_problem_disabled(problem_history.size() == 0)

func _on_prev_problem_pressed() -> void:
	match current_mode:
		Mode.Tutorial:
			load_problem(problem_set.previous_problem())
			ProblemTab.set_prev_problem_disabled(problem_set.current_index == 0)
			ProblemTab.set_next_problem_disabled(false)
		Mode.ProblemSolving:
			load_problem(problem_set.previous_problem())
			ProblemTab.set_prev_problem_disabled(problem_set.current_index == 0)
			ProblemTab.set_next_problem_disabled(false)
		Mode.Sandbox:
			load_problem(problem_history[-1])
			problem_history.pop_back()
			ProblemTab.set_prev_problem_disabled(problem_history.size() == 0)
			ProblemTab.set_next_problem_disabled(false)
	
	Diagram.clear_diagram()

func generate_new_problem() -> Problem:
	return ProblemGeneration.setup_new_problem(ProblemGeneration.generate(
		PuzzleOptions.min_particle_count, PuzzleOptions.max_particle_count, PuzzleOptions.hadron_frequency,
		ProblemGeneration.get_useable_particles_from_interaction_checks(PuzzleOptions.get_checks())
	))

func exit_current_mode() -> void:
	if current_mode == Mode.Null:
		return

	if mode_exit_funcs[current_mode]:
		mode_exit_funcs[current_mode].call()

func _on_tutorial_info_finish_pressed() -> void:
	EventBus.signal_change_scene.emit(Globals.Scene.MainMenu)

func _on_export_tab_export_pressed(join_paths: bool, draw_internal_labels: bool, draw_external_labels: bool) -> void:
	var exporter:= DrawingMatrixExporter.new(
		Diagram.get_current_diagram()
	)

	exporter.join_paths = join_paths
	exporter.draw_internal_labels = draw_internal_labels
	exporter.draw_external_labels = draw_external_labels

	var export_string: String = exporter.generate_export()

	ClipBoard.copy(export_string)

func exit() -> void:
	if is_instance_valid(creation_info):
		creation_info.queue_free()

func add_floating_menu(menu: Control) -> void:
	$FloatingMenus.add_child(menu)

func _diagram_action_taken() -> void:
	HealthTab.update(
		Diagram.is_valid(),
		Diagram.is_fully_connected(true),
		Diagram.is_energy_conserved()
	)

	ProblemTab.update_degree_label()

	update_problem_creation()

func update_problem_creation() -> void:
	if current_mode == Mode.ProblemCreation:
		creation_info.update_problem_creation(
			Diagram.are_quantum_numbers_matching(),
			Diagram.has_state_particles(),
			Diagram.is_energy_conserved()
		)

func start_problem_modification() -> void:
	creation_info = load("res://Scenes_and_scripts/UI/ProblemSelection/creation_information.tscn").instantiate()
	creation_info.problem = creating_problem
	add_floating_menu(creation_info)

	creation_info.next_pressed.connect(_on_creation_info_next)
	creation_info.prev_pressed.connect(_on_creation_info_prev)
	creation_info.submit_pressed.connect(_on_creation_info_submit)
	creation_info.toggle_all.connect(_on_creation_info_toggle_all)
	
	Diagram.set_title_editable(true)

func particle_selection_to_problem_creation() -> void:
	creating_problem.hide_unavailable_particles = creation_info.get_hide_unavailable_particles()
	creating_problem.allowed_particles = ParticleButtons.get_toggled_particles(true)
	
	current_mode = Mode.ProblemCreation
	creation_info.change_mode(current_mode)

func set_problem_creation() -> void:
	creating_problem.custom_degree = creation_info.get_custom_degree()
	
	if creating_problem.custom_degree:
		var degree: int = creation_info.get_degree()
		if creating_problem.degree != degree:
			creating_problem.degree = degree
			creating_problem.solutions.clear()
	else:
		creating_problem.degree = Problem.LOWEST_ORDER
	
	var drawn_diagram: ConnectionMatrix = Diagram.get_current_diagram().reduce_to_connection_matrix()
	var drawn_states: Array = [[], []]
	for state:StateLine.State in StateLine.STATES:
		drawn_states[state] = drawn_diagram.get_state_interactions(state)

	if drawn_states != creating_problem.state_interactions:
		creating_problem.state_interactions = drawn_states

func problem_creation_to_solution_creation() -> void:
	if !ProblemGeneration.setup_new_problem(creating_problem):
		creation_info.no_solutions_found()
		return
	
	creating_problem.solutions = creating_problem.solutions.filter(
		func(solution: DrawingMatrix) -> bool:
			return solution.get_used_base_particles().all(
				func(particle: ParticleData.Particle) -> bool:
					return particle in creating_problem.allowed_particles
			)
	)
	
	creation_info.toggle_no_custom_solutions(creating_problem.solutions.is_empty())

	current_mode = Mode.SolutionCreation
	creation_info.change_mode(current_mode)

func _on_creation_info_next() -> void:
	match current_mode:
		Mode.ParticleSelection:
			particle_selection_to_problem_creation()
		Mode.ProblemCreation:
			set_problem_creation()
			problem_creation_to_solution_creation()

func _on_creation_info_prev() -> void:
	match current_mode:
		Mode.ProblemCreation:
			current_mode = Mode.ParticleSelection
		Mode.SolutionCreation:
			current_mode = Mode.ProblemCreation
	
	creation_info.change_mode(current_mode)

func _on_creation_info_submit() -> void:
	exit_current_mode()

	creating_problem.custom_solutions = creation_info.get_custom_solutions()
	creating_problem.allow_other_solutions = creation_info.get_allow_other_solutions()
	creating_problem.custom_solution_count = creation_info.get_custom_solution_count()

	if creating_problem.custom_solutions:
		creating_problem.solutions = ProblemTab.submitted_diagrams.duplicate(true)

	if creating_problem.custom_solution_count:
		creating_problem.solution_count = creation_info.get_custom_solution_count()

	creating_problem.is_being_modified = false

	problem_submitted.emit()

func _on_creation_info_toggle_all(toggle: bool) -> void:
	ParticleButtons.toggle_buttons(toggle)

func _on_menu_tab_exit_pressed() -> void:
	exit_current_mode()
	EventBus.signal_change_scene.emit(Globals.Scene.MainMenu)

func _on_menu_tab_toggled_line_labels(button_pressed: bool) -> void:
	StatsManager.stats.hide_labels = !button_pressed
	Diagram.show_line_labels = button_pressed

func _on_vision_button_toggled(current_vision: Globals.Vision, toggle: bool) -> void:
	$ShaderControl.toggle_interaction_strength(current_vision == Globals.Vision.Strength)
	Diagram.set_current_vision(current_vision)
	Diagram.vision_button_toggled(current_vision, toggle)

func set_tab_visibility() -> void:
	ControlsTab.visible = Mode.tab_visibility[current_mode]["controls"]
	VisionTab.visible = Mode.tab_visibility[current_mode]["vision"]
	ParticleButtons.visible = Mode.tab_visibility[current_mode]["particles"]
	ProblemTab.visible = Mode.tab_visibility[current_mode]["problem"]
	PuzzleOptions.visible = Mode.tab_visibility[current_mode]["problem_options"]
	MenuTab.visible = Mode.tab_visibility[current_mode]["menu"]
	GenerationTab.visible = Mode.tab_visibility[current_mode]["generation"]
	ExportTab.visible = Mode.tab_visibility[current_mode]["export"]

func _on_diagram_title_submitted(title: String) -> void:
	creating_problem.title = title

func _on_problem_tab_diagram_submitted() -> void:
	if current_mode == Mode.SolutionCreation:
		creation_info.toggle_no_custom_solutions(false)

func _on_problem_tab_diagram_deleted() -> void:
	if current_mode == Mode.SolutionCreation:
		creation_info.toggle_no_custom_solutions(ProblemTab.submitted_diagrams.is_empty())
