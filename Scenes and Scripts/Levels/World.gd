extends Node2D

signal problem_submitted
signal exit_to_main_menu

@onready var FPS = get_node('FPS')
@onready var Pathfinding = $Algorithms/PathFinding
@onready var SolutionGeneration = $Algorithms/SolutionGeneration
@onready var ProblemGeneration = $Algorithms/ProblemGeneration

@onready var ParticleButtons := $PullOutTabs/ParticleButtons
@onready var GenerationTab := $PullOutTabs/GenerationButton
@onready var ProblemTab := $PullOutTabs/ProblemTab
@onready var MenuTab := $PullOutTabs/MenuTab
@onready var VisionTab := $PullOutTabs/VisionButton
@onready var CreationInformation := $FloatingMenus/CreationInformation
@onready var HealthTab := $PullOutTabs/HealthTab

@onready var States = $state_manager

var previous_mode: BaseMode.Mode = BaseMode.Mode.Null
var current_mode: BaseMode.Mode = BaseMode.Mode.Null: set = _set_current_mode
var problem_set: ProblemSet

var mode_enter_funcs : Dictionary = {
	BaseMode.Mode.ParticleSelection: enter_particle_selection,
	BaseMode.Mode.ProblemCreation: enter_problem_creation,
	BaseMode.Mode.SolutionCreation: enter_solution_creation,
	BaseMode.Mode.Sandbox: enter_sandbox,
	BaseMode.Mode.ProblemSolving: enter_problem_solving
}

var mode_exit_funcs : Dictionary = {
	BaseMode.Mode.ParticleSelection: exit_particle_selection,
	BaseMode.Mode.ProblemCreation: exit_problem_creation,
	BaseMode.Mode.SolutionCreation: exit_solution_creation,
	BaseMode.Mode.Sandbox: exit_sandbox,
	BaseMode.Mode.ProblemSolving: exit_problem_solving
}

func _set_current_mode(new_value: BaseMode.Mode):
	if new_value == current_mode:
		return
	
	if current_mode != BaseMode.Mode.Null:
		mode_exit_funcs[current_mode].call()

	previous_mode = current_mode
	current_mode = new_value
	mode_enter_funcs[current_mode].call()

func _ready():
	VisionTab.vision_button_toggled.connect(_vision_button_toggled)
	
	EVENTBUS.signal_add_floating_menu.connect(
		func(menu: Node): $FloatingMenus.add_child(menu)
	)
	
	MenuTab.exit_pressed.connect(
		func() -> void:
			exit_to_main_menu.emit()
	)
	MenuTab.toggled_line_labels.connect(
		func(toggle: bool) -> void:
			$Diagram.show_line_labels = toggle
	)
	
	ProblemTab.next_problem_pressed.connect(_on_next_problem_pressed)
	
	MenuTab.init()
	CreationInformation.init($Diagram, self)
	States.init($Diagram, $PullOutTabs/ControlsTab)
	$Diagram.init(ParticleButtons, $PullOutTabs/ControlsTab, VisionTab, $Algorithms/PathFinding, States)
	GenerationTab.init($Diagram, $Algorithms/SolutionGeneration, $FloatingMenus/GeneratedDiagrams)
	ProblemTab.init(
		$Diagram, Problem.new(), $FloatingMenus/SubmittedDiagrams, $Algorithms/ProblemGeneration, $Algorithms/SolutionGeneration
	)
	HealthTab.init($Diagram)
	$Algorithms/PathFinding.init($Diagram, $Diagram.StateLines)
	$Algorithms/ProblemGeneration.init($Algorithms/SolutionGeneration)
	
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _process(_delta):
	FPS.text = str(Engine.get_frames_per_second())

func _vision_button_toggled(current_vision: GLOBALS.Vision) -> void:
	$ShaderControl.toggle_interaction_strength(current_vision == GLOBALS.Vision.Strength)

func load_problem(problem: Problem) -> void:
	$Diagram.load_problem(problem)
	ProblemTab.load_problem(problem)
	ParticleButtons.load_problem(problem)

func load_problem_set(p_problem_set: ProblemSet, index: int) -> void:
	problem_set = p_problem_set
	problem_set.end_reached.connect(_on_problem_set_end_reached)
	problem_set.current_index = index
	load_problem(problem_set.current_problem)

func enter_particle_selection() -> void:
	ParticleButtons.show()
	GenerationTab.hide()
	ProblemTab.hide()
	VisionTab.hide()
	
	ParticleButtons.enter_particle_selection(GLOBALS.creating_problem)

func exit_particle_selection() -> void:
	GLOBALS.creating_problem.allowed_particles = ParticleButtons.get_toggled_particles(true)
	ParticleButtons.load_problem(GLOBALS.creating_problem)

func enter_sandbox() -> void:
	ParticleButtons.show()
	GenerationTab.show()
	ProblemTab.show()
	VisionTab.show()
	CreationInformation.hide()

func enter_problem_solving() -> void:
	ParticleButtons.show()
	GenerationTab.hide()
	ProblemTab.show()
	VisionTab.show()
	CreationInformation.hide()

func enter_problem_creation() -> void:
	ParticleButtons.show()
	GenerationTab.hide()
	ProblemTab.hide()
	VisionTab.show()

func enter_solution_creation() -> void:
	ParticleButtons.show()
	GenerationTab.show()
	ProblemTab.show()
	VisionTab.show()
	
	ProblemTab.in_solution_creation = true

func exit_sandbox() -> void:
	return

func exit_problem_solving() -> void:
	return

func exit_problem_creation() -> void:
	var creating_problem: Problem = GLOBALS.creating_problem
	var drawn_diagram: DrawingMatrix = $Diagram.generate_drawing_matrix_from_diagram()
	for state in [StateLine.StateType.Initial, StateLine.StateType.Final]:
		GLOBALS.creating_problem.state_interactions[state] = drawn_diagram.get_state_interactions(state)
	
	if !setup_new_problem(creating_problem):
		CreationInformation.no_solutions_found()
		return
	
	ProblemTab.load_problem(GLOBALS.creating_problem, false)

func exit_solution_creation() -> void:
	ProblemTab.in_solution_creation = false

func _on_creation_information_submit_problem() -> void:
	problem_submitted.emit()

func _on_problem_set_end_reached() -> void:
	exit_to_main_menu.emit()

func _on_next_problem_pressed() -> void:
	match current_mode:
		BaseMode.Mode.ProblemSolving:
			ProblemTab.load_problem(problem_set.next_problem())
		BaseMode.Mode.Sandbox:
			ProblemTab.load_problem(ProblemGeneration.generate_problem())

func setup_new_problem(problem: Problem) -> bool:
	var min_degree: int = problem.degree if problem.custom_degree else 1
	var max_degree: int = problem.degree if problem.custom_degree else 6
	
	var generated_solutions: Array[ConnectionMatrix] = SolutionGeneration.generate_diagrams(
		problem.state_interactions[StateLine.StateType.Initial],
		problem.state_interactions[StateLine.StateType.Final],
		min_degree, max_degree,
		SolutionGeneration.get_useable_interactions_from_particles(problem.allowed_particles),
		SolutionGeneration.Find.LowestOrder
	)
	
	if generated_solutions == [null]:
		return false
	
	problem.degree = generated_solutions.front().state_count[StateLine.StateType.None]
	problem.solution_count = ProblemGeneration.calculate_solution_count(
		problem.degree, generated_solutions.size()
	)
	
	return true
