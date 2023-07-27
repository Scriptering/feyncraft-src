extends BaseState

var Line := preload("res://Scenes and Scripts/Diagram/line.tscn")
var Interaction := preload("res://Scenes and Scripts/Diagram/interaction.tscn")

func input(_event: InputEvent) -> State:
	if Input.is_action_just_released("editing"):
		place_objects()
		return State.Idle
	
	if Input.is_action_just_released("click"):
		place_objects()
		return State.Hovering

	return State.Null

func place_objects() -> void:
	get_tree().call_group("grabbable", "drop")
	
	for line in get_tree().get_nodes_in_group("lines"):
		line.place()
	
	diagram_actions.check_split_lines()
	diagram_actions.check_rejoin_lines()


