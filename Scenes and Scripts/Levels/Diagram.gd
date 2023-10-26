extends BaseTutorialStep

@export var World: Node2D

func _ready() -> void:
	await World.initialised
	FocusObjects.push_back(World.ControlsTab.MovingContainer)
