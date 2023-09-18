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
@onready var ModeManager = $mode_manager

var starting_mode: BaseMode.Mode = BaseMode.Mode.Sandbox
var current_mode: BaseMode.Mode: get = _get_current_mode
var problem_set: ProblemSet

func _get_current_mode() -> BaseMode.Mode:
	return ModeManager.mode

func _ready():
	EVENTBUS.signal_add_floating_menu.connect(
		func(menu: Node): $FloatingMenus.add_child(menu)
	)
	
	CreationInformation.init(problem_set.limited_particles, problem_set.custom_solutions, $Diagram)
	States.init($Diagram, $PullOutTabs/ControlsTab)
	ModeManager.init(self, starting_mode)
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
	ParticleButtons.enter_particle_selection()

func exit_particle_selection() -> void:
	ParticleButtons.exit_particle_selection()
