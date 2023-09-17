extends Node2D

signal mode_changed

@onready var FPS = get_node('FPS')
@onready var Cursor = get_node('Cursor')
@onready var Pathfinding = $Algorithms/PathFinding
@onready var SolutionGeneration = $Algorithms/SolutionGeneration
@onready var ProblemGeneration = $Algorithms/ProblemGeneration

@onready var ParticleButtons := $PullOutTabs/ParticleButtons
@onready var GenerationTab := $PullOutTabs/GenerationButton
@onready var ProblemTab := $PullOutTabs/ProblemTab
@onready var MenuTab := $PullOutTabs/MenuTab
@onready var VisionTab := $PullOutTabs/VisionButton

@onready var States = $state_manager

var current_mode: GLOBALS.Mode = GLOBALS.Mode.Sandbox: set = _set_mode

func _ready():
	EVENTBUS.signal_add_floating_menu.connect(
		func(menu: Node): $FloatingMenus.add_child(menu)
	)
	
	mode_changed.connect(EVENTBUS.mode_changed)
	
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

func _set_mode(new_value: GLOBALS.Mode) -> void:
	var prev_mode: GLOBALS.Mode = current_mode
	current_mode = new_value
	
	mode_changed.emit(prev_mode, current_mode)

func enter_particle_selection() -> void:
	ParticleButtons.enter_particle_selection()

func exit_particle_selection() -> void:
	ParticleButtons.exit_particle_selection()
