extends BaseState

func enter() -> void:
	super.enter()

func exit() -> void:
	super.exit()

func input(_event: InputEvent) -> State:
	if Input.is_action_just_released("editing"):
		place_objects()
		return State.Idle
	
	if Input.is_action_just_released("click"):
		place_objects()
		return State.Hovering

	return State.Null

func place_objects() -> void:
	var interaction_grabbed: bool = is_interaction_grabbed()
	
	if interaction_grabbed:
		Diagram.place_objects()
		return
	
	get_tree().call_group("grabbable", "drop")

func is_interaction_grabbed() -> bool:
	return get_tree().get_nodes_in_group("grabbable").any(
		func(object):
			return object.grabbed and object is Interaction
	)

