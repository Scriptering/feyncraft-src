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
@onready var CreationInformation := $FloatingMenus/CreationInformation
@onready var HealthTab := $PullOutTabs/HealthTab
@onready var Diagram: MainDiagram = $Diagram
@onready var Tutorial := $Tutorial
@onready var ControlsTab := $PullOutTabs/ControlsTab

var StateManager: Node

var previous_mode: BaseMode.Mode = BaseMode.Mode.Null
var current_mode: BaseMode.Mode = BaseMode.Mode.Null: set = _set_current_mode
var current_problem: Problem = null
var problem_set: ProblemSet
var problem_history: Array[Problem] = []

var mode_enter_funcs : Dictionary = {
	BaseMode.Mode.ParticleSelection: enter_particle_selection,
	BaseMode.Mode.ProblemCreation: enter_problem_creation,
	BaseMode.Mode.SolutionCreation: enter_solution_creation,
	BaseMode.Mode.Sandbox: enter_sandbox,
	BaseMode.Mode.ProblemSolving: enter_problem_solving,
	BaseMode.Mode.Tutorial: enter_tutorial
}

var mode_exit_funcs : Dictionary = {
	BaseMode.Mode.ParticleSelection: exit_particle_selection,
	BaseMode.Mode.ProblemCreation: exit_problem_creation,
	BaseMode.Mode.SolutionCreation: exit_solution_creation,
	BaseMode.Mode.Sandbox: exit_sandbox,
	BaseMode.Mode.ProblemSolving: enter_problem_solving,
	BaseMode.Mode.Tutorial: exit_tutorial
}

func _set_current_mode(new_value: BaseMode.Mode) -> void:
	exit_current_mode()

	previous_mode = current_mode
	current_mode = new_value
	mode_enter_funcs[current_mode].call()

func init(state_manager: Node) -> void:
	StateManager = state_manager
	VisionTab.vision_button_toggled.connect(_vision_button_toggled)
	MenuTab.toggled_line_labels.connect(
		func(toggle: bool) -> void:
			Diagram.show_line_labels = toggle
	)
	MenuTab.exit_pressed.connect(_on_menu_exit_pressed)
	
	ProblemTab.next_problem_pressed.connect(_on_next_problem_pressed)
	ProblemTab.prev_problem_pressed.connect(_on_prev_problem_pressed)
	
	Tutorial.init(self)
	CreationInformation.init(Diagram, self, ProblemTab)
	Diagram.init(StateManager)
	GenerationTab.init(Diagram, $FloatingMenus/GeneratedDiagrams)
	ProblemTab.init(Diagram, Problem.new(), $FloatingMenus/SubmittedDiagrams)

	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	ParticleButtons.particle_selected.connect(_on_particle_selected)
	
	ControlsTab.clear_diagram.connect(_controls_clear)
	ControlsTab.undo.connect(Diagram.undo)
	ControlsTab.redo.connect(Diagram.redo)
	
	initialised.emit()
	
	Diagram.action_taken.connect(_diagram_action_taken)

func _controls_clear() -> void:
	Diagram.add_diagram_to_history()
	Diagram.clear_diagram()

func _on_particle_selected(particle: ParticleData.Particle) -> void:
	Diagram.drawing_particle = particle

func _vision_button_toggled(current_vision: Globals.Vision, toggle: bool) -> void:
	$ShaderControl.toggle_interaction_strength(current_vision == Globals.Vision.Strength)
	Diagram.set_current_vision(current_vision)
	Diagram.vision_button_toggled(current_vision, toggle)

func load_test_problem() -> void:
	var test_problem: Problem = Problem.new()
	
	test_initial_state = [[-4], [12]]
	test_final_state = [[12], [12], [-8]]
	
	test_problem.allowed_particles = ParticleData.Particle.values()
	test_problem.state_interactions = [test_initial_state, test_final_state]
	
	load_problem(ProblemGeneration.setup_new_problem(test_problem))

func load_problem(problem: Problem) -> void:
	current_problem = problem
	
	Diagram.load_problem(problem, current_mode)
	ProblemTab.load_problem(problem)
	ParticleButtons.load_problem(problem)

	if current_mode == BaseMode.Mode.ProblemSolving or current_mode == BaseMode.Mode.Tutorial:
		ProblemTab.toggle_finish_icon(problem_set.current_index == problem_set.problems.size() - 1)

func load_problem_set(p_problem_set: ProblemSet, index: int) -> void:
	problem_set = p_problem_set
	problem_set.end_reached.connect(_on_problem_set_end_reached)
	problem_set.current_index = index
	
	problem_history.clear()
	ProblemTab.set_prev_problem_disabled(index == 0)
	load_problem(problem_set.current_problem)
	ProblemTab.set_next_problem_disabled(index >= problem_set.highest_index_reached)

func enter_particle_selection() -> void:
	ParticleButtons.show()
	CreationInformation.show()
	GenerationTab.hide()
	ProblemTab.hide()
	VisionTab.hide()
	
	Diagram.load_problem(Globals.creating_problem, current_mode)
	ParticleButtons.enter_particle_selection(Globals.creating_problem)
	CreationInformation.reset()

func exit_particle_selection() -> void:
	Globals.creating_problem.allowed_particles = ParticleButtons.get_toggled_particles(true)
	ParticleButtons.exit_particle_selection()
	CreationInformation.hide()

func enter_sandbox() -> void:
	ParticleButtons.show()
	GenerationTab.show()
	ProblemTab.show()
	VisionTab.show()
	CreationInformation.hide()
	PuzzleOptions.show()
	
	ProblemTab._enter_sandbox()
	load_problem(Problem.new())
	
	Diagram.clear_diagram()
	Diagram.set_title_editable(false)
	Diagram.set_title_visible(false)

func enter_problem_solving() -> void:
	ParticleButtons.show()
	GenerationTab.hide()
	ProblemTab.show()
	VisionTab.show()
	CreationInformation.hide()
	
	Diagram.set_title_editable(false)

func enter_problem_creation() -> void:
	ParticleButtons.show()
	GenerationTab.hide()
	ProblemTab.hide()
	VisionTab.show()
	CreationInformation.show()
	
	ParticleButtons.load_problem(Globals.creating_problem)
	
	if Globals.creating_problem.state_interactions != [[],[]]:
		EventBus.draw_diagram_raw(
			SolutionGeneration.generate_diagrams(
				Globals.creating_problem.state_interactions[StateLine.State.Initial],
				Globals.creating_problem.state_interactions[StateLine.State.Final],
				Globals.creating_problem.degree, Globals.creating_problem.degree,
				SolutionGeneration.get_useable_interactions_from_particles(Globals.creating_problem.allowed_particles),
				SolutionGeneration.Find.One
		).front()
		)

func enter_solution_creation() -> void:
	ParticleButtons.show()
	GenerationTab.show()
	ProblemTab.show()
	VisionTab.show()
	CreationInformation.show()
	
	var creating_problem: Problem = Globals.creating_problem
	var drawn_diagram: DrawingMatrix = Diagram.get_current_diagram()
	for state:StateLine.State in StateLine.STATES:
		Globals.creating_problem.state_interactions[state] = drawn_diagram.reduce_to_connection_matrix().get_state_interactions(state)
	
	if !ProblemGeneration.setup_new_problem(creating_problem):
		CreationInformation.no_solutions_found()
		CreationInformation.prev_mode()
		return
	
	Globals.creating_problem.custom_solutions = false
	
	ProblemTab.load_problem(Globals.creating_problem)
	ProblemTab.in_solution_creation = true

func exit_sandbox() -> void:
	ProblemTab._exit_sandbox()
	PuzzleOptions.hide()

func exit_problem_solving() -> void:
	return

func exit_problem_creation() -> void:
	pass

func exit_solution_creation() -> void:
	ProblemTab._exit_solution_creation()
	ProblemTab.in_solution_creation = false
	CreationInformation.hide()

func enter_tutorial() -> void:
	ParticleButtons.show()
	GenerationTab.hide()
	ProblemTab.show()
	VisionTab.hide()
	CreationInformation.hide()
	PuzzleOptions.hide()
	Tutorial.show()
	
	Tutorial.reset()
	load_problem_set(load("res://saves/ProblemSets/tutorial.tres"), 0)

func exit_tutorial() -> void:
	Tutorial.clear()
	Tutorial.hide()
	
	problem_set.highest_index_reached = 0

func _on_creation_information_submit_problem() -> void:
	exit_current_mode()
	problem_submitted.emit()

func _on_problem_set_end_reached() -> void:
	problem_set.end_reached.disconnect(_on_problem_set_end_reached)
	
	EventBus.signal_change_scene.emit(Globals.Scene.MainMenu)

func _on_next_problem_pressed() -> void:
	problem_history.push_back(current_problem)
	
	match current_mode:
		BaseMode.Mode.Tutorial:
			load_problem(problem_set.next_problem())
			ProblemTab.set_next_problem_disabled(problem_set.current_index >= problem_set.highest_index_reached)
		BaseMode.Mode.ProblemSolving:
			load_problem(problem_set.next_problem())
			ProblemTab.set_next_problem_disabled(problem_set.current_index >= problem_set.highest_index_reached)
			save_problem_set.emit()
		BaseMode.Mode.Sandbox:
			var new_problem: Problem = generate_new_problem()
			
			if !new_problem:
				return
			
			load_problem(new_problem)
	
	Diagram.clear_diagram()
	ProblemTab.set_prev_problem_disabled(problem_history.size() == 0)

func _on_prev_problem_pressed() -> void:
	match current_mode:
		BaseMode.Mode.Tutorial:
			load_problem(problem_set.previous_problem())
			ProblemTab.set_prev_problem_disabled(problem_set.current_index == 0)
			ProblemTab.set_next_problem_disabled(false)
		BaseMode.Mode.ProblemSolving:
			load_problem(problem_set.previous_problem())
			ProblemTab.set_prev_problem_disabled(problem_set.current_index == 0)
			ProblemTab.set_next_problem_disabled(false)
		BaseMode.Mode.Sandbox:
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

func _on_creation_information_toggle_all(toggle: bool) -> void:
	ParticleButtons.toggle_buttons(toggle)

func exit_current_mode() -> void:
	if current_mode != BaseMode.Mode.Null:
		mode_exit_funcs[current_mode].call()

func _on_menu_exit_pressed() -> void:
	exit_current_mode()
	EventBus.signal_change_scene.emit(Globals.Scene.MainMenu)

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

func add_floating_menu(menu: Control) -> void:
	$FloatingMenus.add_child(menu)

func _diagram_action_taken() -> void:
	HealthTab.update(
		Diagram.is_valid(),
		Diagram.is_fully_connected(true),
		Diagram.is_energy_conserved()
	)
