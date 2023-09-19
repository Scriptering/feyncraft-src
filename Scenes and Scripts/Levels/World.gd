extends Node2D

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

@onready var States = $state_manager

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

	current_mode = new_value
	mode_enter_funcs[current_mode].call()

func _ready():
	self.current_mode = GLOBALS.load_mode
	
	EVENTBUS.signal_add_floating_menu.connect(
		func(menu: Node): $FloatingMenus.add_child(menu)
	)
	
	CreationInformation.init(GLOBALS.creating_problem, $Diagram, self)
	States.init($Diagram, $PullOutTabs/ControlsTab)
	$Diagram.init(ParticleButtons, $PullOutTabs/ControlsTab, VisionTab, $Algorithms/PathFinding)
	$ShaderControl.init($PalletteButtons)
	GenerationTab.init($Diagram, $Algorithms/SolutionGeneration, $FloatingMenus/GeneratedDiagrams)
	ProblemTab.init(
		$Diagram, Problem.new(), $FloatingMenus/SubmittedDiagrams, $Algorithms/ProblemGeneration, $Algorithms/SolutionGeneration
	)
	$Algorithms/PathFinding.init($Diagram, $Diagram.StateLines)
	$Algorithms/ProblemGeneration.init($Algorithms/SolutionGeneration)
	
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _process(_delta):
	FPS.text = str(Engine.get_frames_per_second())

func enter_particle_selection() -> void:
	ParticleButtons.show()
	GenerationTab.hide()
	ProblemTab.hide()
	VisionTab.hide()
	
	ParticleButtons.enter_particle_selection()

func exit_particle_selection() -> void:
	ParticleButtons.exit_particle_selection()

func enter_sandbox() -> void:
	ParticleButtons.show()
	GenerationTab.show()
	ProblemTab.show()
	VisionTab.show()

func enter_problem_solving() -> void:
	ParticleButtons.show()
	GenerationTab.hide()
	ProblemTab.show()
	VisionTab.show()

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

func exit_sandbox() -> void:
	return

func exit_problem_solving() -> void:
	return

func exit_problem_creation() -> void:
	return

func exit_solution_creation() -> void:
	return


