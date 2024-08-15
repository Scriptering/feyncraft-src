extends Node2D

signal sandbox_pressed
signal tutorial_pressed

var Level := preload("res://Scenes and Scripts/Levels/world.tscn")
var placing: bool = false

@onready var Diagram: MainDiagram = $Diagram

var StateManager: Node

func _ready() -> void:
	EventBus.signal_exit_game.connect(_on_exit_game)

func init(state_manager: Node) -> void:
	StateManager = state_manager

	$Diagram.init($Algorithms/PathFinding, StateManager)
	$Algorithms/PathFinding.init($Diagram, $Diagram.StateLines)
	$Algorithms/ProblemGeneration.init($Algorithms/SolutionGeneration)
	
	Diagram.draw_diagram(Globals.TitleDiagram)

func _on_sandbox_pressed() -> void:
	sandbox_pressed.emit()

func _on_exit_game(_mode: BaseMode.Mode, _problem: Problem) -> void:
	return

func add_floating_menu(menu: Control) -> void:
	$FloatingMenus.add_child(menu)

func _on_tutorial_pressed() -> void:
	tutorial_pressed.emit()

func _on_daily_pressed() -> void:
	pass # Replace with function body.
