extends BaseState

var Line := preload("res://Scenes and Scripts/Diagram/line.tscn")
var Interaction := preload("res://Scenes and Scripts/Diagram/interaction.tscn")

func enter() -> void:
	super.enter()
	Diagram.toggle_crosshair_above_interactions()

func exit() -> void:
	super.exit()
	Diagram.toggle_crosshair_above_interactions()

func input(_event: InputEvent) -> State:
	if Input.is_action_just_released("editing"):
		Diagram.place_objects()
		return State.Idle
	
	if Input.is_action_just_released("click"):
		Diagram.place_objects()
		return State.Hovering

	return State.Null


