extends Control

var level := preload("res://Scenes and Scripts/Levels/world.tscn")

var placing: bool = false

@onready var palette_control: Control = $FloatingMenus/PaletteControl
@onready var problem_selection: Control = $FloatingMenus/ProblemSelection
@onready var States = $state_manager
@onready var Diagram: MainDiagram = $Diagram
@onready var MenuTab: Control = $MenuTab

func _ready():
	EVENTBUS.signal_enter_game.connect(enter_game)
	EVENTBUS.signal_add_floating_menu.connect(
		func(menu: Node): $FloatingMenus.add_child(menu)
	)
	
	MenuTab.init()
	palette_control.closed.connect(_on_palette_control_closed)
	problem_selection.closed.connect(_on_problem_selection_closed)
	States.init($Diagram, $ControlsTab)
	$Diagram.init($ParticleButtons, $ControlsTab, $VisionButton, $Algorithms/PathFinding, States)
	$Algorithms/PathFinding.init($Diagram, $Diagram.StateLines)
	$Algorithms/ProblemGeneration.init($Algorithms/SolutionGeneration)
	
	Diagram.draw_diagram(ResourceLoader.load("res://saves/title_diagram.tres"))

func enter_game() -> void:
	get_tree().change_scene_to_packed(level)

func _on_sandbox_pressed() -> void:
	GLOBALS.load_mode = BaseMode.Mode.Sandbox
	enter_game()

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

