extends Node
class_name BaseTutorialStep

signal draw_diagram(drawing_matrix: DrawingMatrix)
signal next_step

@export_multiline var text: String
@export var FocusObjects: Array[Node] = []
@export var enable_spotlight: bool = true
@export var focus_controls: bool = false
@export_file var DiagramFilePath: String = ''

var drawing_matrix: DrawingMatrix = null

func init(world: Node2D) -> void:
	if focus_controls:
		FocusObjects.push_back(world.ControlsTab.MovingContainer)
	
	if DiagramFilePath != '':
		drawing_matrix = load(DiagramFilePath)

func enter() -> void:
	if drawing_matrix:
		draw_diagram.emit(drawing_matrix)

func exit() -> void:
	next_step.emit()
