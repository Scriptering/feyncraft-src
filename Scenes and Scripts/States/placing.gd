extends BaseState

var Line := preload("res://Scenes and Scripts/Diagram/line.tscn")
var Interaction := preload("res://Scenes and Scripts/Diagram/interaction.tscn")

func input(_event: InputEvent) -> State:
	if Input.is_action_just_released("editing"):
		diagram_actions.place_objects()
		return State.Idle
	
	if Input.is_action_just_released("click"):
		diagram_actions.place_objects()
		return State.Hovering

	return State.Null


