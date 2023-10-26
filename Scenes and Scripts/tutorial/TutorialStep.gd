extends Node
class_name BaseTutorialStep

signal next_step

@export_multiline var text: String
@export var FocusObjects: Array[Node] = []
@export var enable_spotlight: bool = true
@export var focus_controls: bool = false

func init(world: Node2D) -> void:
	if focus_controls:
		FocusObjects.push_back(world.ControlsTab.MovingContainer)

func enter() -> void:
	pass

func exit() -> void:
	pass
