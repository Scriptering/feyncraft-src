extends Control

signal sandbox_pressed

@export var PaletteMenu: GrabbableControl

var Level = preload("res://Scenes and Scripts/Levels/world.tscn")
var placing: bool = false

@onready var palette_control: Control = $FloatingMenus/PaletteControl
@onready var problem_selection: Control = $FloatingMenus/ProblemSelection
@onready var States = $state_manager
@onready var Diagram: MainDiagram = $Diagram
@onready var MenuTab: Control = $MenuTab

func _ready():
	EVENTBUS.signal_exit_game.connect(_on_exit_game)
	
	MenuTab.init(PaletteMenu)
	palette_control.closed.connect(_on_palette_control_closed)
	problem_selection.closed.connect(_on_problem_selection_closed)
	States.init($Diagram, $ControlsTab)
	$Diagram.init($ParticleButtons, $ControlsTab, $VisionButton, $Algorithms/PathFinding, States)
	$Algorithms/PathFinding.init($Diagram, $Diagram.StateLines)
	$Algorithms/ProblemGeneration.init($Algorithms/SolutionGeneration)
	
	Diagram.draw_diagram(GLOBALS.TitleDiagram)

func _on_sandbox_pressed() -> void:
	sandbox_pressed.emit()

func _on_palettes_toggled(button_pressed) -> void:
	palette_control.visible = button_pressed
	
	palette_control.set_anchors_preset(Control.PRESET_CENTER)

func _on_problem_sets_toggled(button_pressed) -> void:
	problem_selection.visible = button_pressed
	
	problem_selection.set_anchors_preset(Control.PRESET_CENTER)

func _on_palette_control_closed() -> void:
	$Center/VBoxContainer/HBoxContainer/Palettes.button_pressed = false

func _on_problem_selection_closed() -> void:
	$Center/VBoxContainer/ProblemSets.button_pressed = false

func _on_exit_game(_mode: BaseMode.Mode, _problem: Problem) -> void:
	return
