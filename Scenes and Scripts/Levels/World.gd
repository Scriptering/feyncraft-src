extends Node2D

signal problem_submitted
signal initialised

@onready var FPS = get_node('FPS')
@onready var Pathfinding = $Algorithms/PathFinding
@onready var SolutionGeneration = $Algorithms/SolutionGeneration
@onready var ProblemGeneration = $Algorithms/ProblemGeneration

@onready var ParticleButtons := $PullOutTabs/ParticleButtons
@onready var GenerationTab := $PullOutTabs/GenerationButton
@onready var PuzzleOptions: Control = $PullOutTabs/PuzzleUI
@onready var ProblemTab := $PullOutTabs/ProblemTab
@onready var MenuTab := $PullOutTabs/MenuTab
@onready var VisionTab := $PullOutTabs/VisionButton
@onready var CreationInformation := $FloatingMenus/CreationInformation
@onready var HealthTab := $PullOutTabs/HealthTab
@onready var Diagram: DiagramBase = $Diagram
@onready var Tutorial := $Tutorial

var ControlsTab: Control
var StateManager: Node
var PaletteMenu: GrabbableControl

var previous_mode: BaseMode.Mode = BaseMode.Mode.Null
var current_mode: BaseMode.Mode = BaseMode.Mode.Null: set = _set_current_mode
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

func _set_current_mode(new_value: BaseMode.Mode):
	exit_current_mode()

	previous_mode = current_mode
	current_mode = new_value
	mode_enter_funcs[current_mode].call()

func init(state_manager: Node, controls_tab: Control, palette_list: GrabbableControl):
	StateManager = state_manager
	ControlsTab = controls_tab
	PaletteMenu = palette_list
	VisionTab.vision_button_toggled.connect(_vision_button_toggled)
	MenuTab.toggled_line_labels.connect(
		func(toggle: bool) -> void:
			Diagram.show_line_labels = toggle
	)
	MenuTab.exit_pressed.connect(_on_menu_exit_pressed)
	
	ProblemTab.next_problem_pressed.connect(_on_next_problem_pressed)
	ProblemTab.prev_problem_pressed.connect(_on_prev_problem_pressed)
	Tutorial.load_hadron_problem.connect(_load_tutorial_hadron_problem)
	
	Tutorial.init(self)
	MenuTab.init(PaletteMenu)
	CreationInformation.init(Diagram, self, ProblemTab)
	Diagram.init(ParticleButtons, ControlsTab, VisionTab, $Algorithms/PathFinding, StateManager)
	GenerationTab.init(Diagram, $Algorithms/SolutionGeneration, $FloatingMenus/GeneratedDiagrams)
	ProblemTab.init(
		Diagram, Problem.new(), $FloatingMenus/SubmittedDiagrams, $Algorithms/ProblemGeneration, $Algorithms/SolutionGeneration
	)
	HealthTab.init(Diagram)
	$Algorithms/PathFinding.init(Diagram, Diagram.StateLines)
	$Algorithms/ProblemGeneration.init($Algorithms/SolutionGeneration)
	
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	initialised.emit()

func _process(_delta):
	FPS.text = str(Engine.get_frames_per_second())

func _vision_button_toggled(current_vision: GLOBALS.Vision) -> void:
	$ShaderControl.toggle_interaction_strength(current_vision == GLOBALS.Vision.Strength)

func load_problem(problem: Problem) -> void:
	Diagram.load_problem(problem, current_mode)
	ProblemTab.load_problem(problem)
	ParticleButtons.load_problem(problem)

	if current_mode == BaseMode.Mode.ProblemSolving:
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
	
	Diagram.load_problem(GLOBALS.creating_problem, current_mode)
	ParticleButtons.enter_particle_selection(GLOBALS.creating_problem)
	CreationInformation.reset()

func exit_particle_selection() -> void:
	GLOBALS.creating_problem.allowed_particles = ParticleButtons.get_toggled_particles(true)
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
	
	Diagram.set_title_editable(false)
	Diagram.set_title_visible(false)

	load_problem(generate_new_problem())

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
	
	ParticleButtons.load_problem(GLOBALS.creating_problem)

func enter_solution_creation() -> void:
	ParticleButtons.show()
	GenerationTab.show()
	ProblemTab.show()
	VisionTab.show()
	CreationInformation.show()
	
	var creating_problem: Problem = GLOBALS.creating_problem
	var drawn_diagram: DrawingMatrix = Diagram.generate_drawing_matrix_from_diagram()
	for state in [StateLine.StateType.Initial, StateLine.StateType.Final]:
		GLOBALS.creating_problem.state_interactions[state] = drawn_diagram.reduce_to_connection_matrix().get_state_interactions(state)
	
	if !ProblemGeneration.setup_new_problem(creating_problem):
		CreationInformation.no_solutions_found()
		return
	
	ProblemTab.load_problem(GLOBALS.creating_problem)
	
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
	Tutorial.show()

func exit_tutorial() -> void:
	Tutorial.clear()
	Tutorial.hide()

func _on_creation_information_submit_problem() -> void:
	exit_current_mode()
	
	GLOBALS.creating_problem.solutions = ProblemTab.submitted_diagrams
	
	problem_submitted.emit()

func _on_problem_set_end_reached() -> void:
	problem_set.end_reached.disconnect(_on_problem_set_end_reached)
	
	EVENTBUS.signal_change_scene.emit(GLOBALS.Scene.MainMenu)

func _on_next_problem_pressed() -> void:
	match current_mode:
		BaseMode.Mode.ProblemSolving:
			load_problem(problem_set.next_problem())
			ProblemTab.set_next_problem_disabled(problem_set.current_index >= problem_set.highest_index_reached)
		BaseMode.Mode.Sandbox:
			load_problem(generate_new_problem())
	
	Diagram.clear_diagram()
	ProblemTab.set_prev_problem_disabled(false)

func _on_prev_problem_pressed() -> void:
	match current_mode:
		BaseMode.Mode.ProblemSolving:
			load_problem(problem_set.previous_problem())
			ProblemTab.set_prev_problem_disabled(problem_set.current_index == 0)
		BaseMode.Mode.Sandbox:
			load_problem(problem_history[-1])
			problem_history.pop_back()
			ProblemTab.set_prev_problem_disabled(problem_history.size() == 0)
	
	Diagram.clear_diagram()

func generate_new_problem() -> Problem:
	return ProblemGeneration.setup_new_problem(ProblemGeneration.generate(
		PuzzleOptions.min_particle_count, PuzzleOptions.max_particle_count, PuzzleOptions.hadron_frequency,
		ProblemGeneration.get_useable_particles_from_interaction_checks(PuzzleOptions.get_checks())
	))

func _on_creation_information_toggle_all(toggle: bool) -> void:
	ParticleButtons.toggle_buttons(toggle)

func _load_tutorial_hadron_problem() -> void:
	return

func exit_current_mode() -> void:
	if current_mode != BaseMode.Mode.Null:
		mode_exit_funcs[current_mode].call()

func _on_menu_exit_pressed() -> void:
	exit_current_mode()
	EVENTBUS.signal_change_scene.emit(GLOBALS.Scene.MainMenu)
