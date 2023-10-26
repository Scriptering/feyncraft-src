extends Control

signal sandbox_pressed
signal tutorial_pressed

@export var PaletteMenu: GrabbableControl

var Level = preload("res://Scenes and Scripts/Levels/world.tscn")
var placing: bool = false

@onready var problem_selection: Control = $FloatingMenus/ProblemSelection
@onready var Diagram: MainDiagram = $Diagram
@onready var MenuTab: Control = $MenuTab

var ControlsTab: Control
var StateManager: Node
var PaletteList: GrabbableControl

func _ready():
	EVENTBUS.signal_exit_game.connect(_on_exit_game)

func reload_problem_selection() -> void:
	problem_selection.reload()

func init(state_manager: Node, controls_tab: Control, palette_list: GrabbableControl):
	StateManager = state_manager
	ControlsTab = controls_tab
	PaletteList = palette_list

	MenuTab.init(PaletteMenu)
	PaletteList.closed.connect(_on_PaletteList_closed)
	problem_selection.closed.connect(_on_problem_selection_closed)
	$Diagram.init($ParticleButtons, ControlsTab, $VisionButton, $Algorithms/PathFinding, StateManager)
	$Algorithms/PathFinding.init($Diagram, $Diagram.StateLines)
	$Algorithms/ProblemGeneration.init($Algorithms/SolutionGeneration)
	
	Diagram.draw_diagram(GLOBALS.TitleDiagram)
	Diagram.can_draw_diagrams = false

func _on_sandbox_pressed() -> void:
	sandbox_pressed.emit()

func _on_palettes_toggled(button_pressed) -> void:
	PaletteList.visible = button_pressed
	
	PaletteList.set_anchors_preset(Control.PRESET_CENTER)

func _on_problem_sets_toggled(button_pressed) -> void:
	problem_selection.visible = button_pressed
	
	problem_selection.set_anchors_preset(Control.PRESET_CENTER)

func _on_PaletteList_closed() -> void:
	$Center/VBoxContainer/HBoxContainer/Palettes.button_pressed = false

func _on_problem_selection_closed() -> void:
	$Center/VBoxContainer/ProblemSets.button_pressed = false

func _on_exit_game(_mode: BaseMode.Mode, _problem: Problem) -> void:
	return

func _on_tutorial_pressed() -> void:
	tutorial_pressed.emit()
