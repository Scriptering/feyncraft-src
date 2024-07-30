extends BaseState

var grabbed_interaction: Interaction = null

func enter() -> void:
	super.enter()
	
	if is_interaction_grabbed():
		grabbed_interaction = get_grabbed_object()

func exit() -> void:
	super.exit()
	
	grabbed_interaction = null

func input(_event: InputEvent) -> State:
	if Input.is_action_just_released("editing"):
		place_objects()
		return State.Idle
	
	if Input.is_action_just_released("click"):
		place_objects()
		
		if Input.is_action_pressed("editing"):
			return State.Hovering
		else:
			return State.Idle

	return State.Null

func place_objects() -> void:
	if grabbed_interaction:
		Diagram.drop_interaction(grabbed_interaction)
		return
	
	get_tree().call_group("grabbable", "drop")

func get_grabbed_object() -> Node:
	for object:Variant in get_tree().get_nodes_in_group("grabbable"):
		if object.grabbed:
			return object
	
	return null

func is_interaction_grabbed() -> bool:
	return get_tree().get_nodes_in_group("grabbable").any(
		func(object:Variant) -> bool:
			return object.grabbed and object is Interaction
	)
