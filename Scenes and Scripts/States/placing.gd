extends BaseState

var grabbed_object: Node = null

func enter() -> void:
	super.enter()
	
	grabbed_object = get_grabbed_object()

func exit() -> void:
	super.exit()
	
	grabbed_object = null

func input(event: InputEvent) -> State:
	if Input.is_action_just_released("editing"):
		place_objects()
		return State.Idle
	
	if Globals.is_on_mobile():
		if (
			event is InputEventScreenTouch
			and event.is_released()
			and event.index == grabbed_object.drag_finger_index
		):
			place_objects()
			if Input.is_action_pressed("editing"):
				return State.Hovering
			else:
				return State.Idle

	elif Input.is_action_just_released("click"):
		place_objects()
		if Input.is_action_pressed("editing"):
			return State.Hovering
		else:
			return State.Idle
		

	return State.Null

func place_objects() -> void:
	grabbed_object.drop()

func get_grabbed_object() -> Node:
	for object:Variant in get_tree().get_nodes_in_group("grabbable"):
		if object.grabbed:
			return object
	
	return null
