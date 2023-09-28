extends BaseState

func enter() -> void:
	super.enter()
	crosshair.hide()

func exit() -> void:
	super.exit()
	if Diagram.hovering:
		crosshair.show()

func input(_event: InputEvent) -> State:
	if Input.is_action_just_released("editing"):
		Diagram.place_objects()
		return State.Idle
	
	if Input.is_action_just_released("click"):
		Diagram.place_objects()
		return State.Hovering

	return State.Null


