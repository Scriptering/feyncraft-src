extends BaseState

@export var minimum_press_time: float

func enter() -> void:
	super.enter()
	crosshair.drawing_ended()

func _ready() -> void:
	$minimum_press_timer.wait_time = minimum_press_time

func input(event: InputEvent) -> State:
	if Input.is_action_just_pressed("draw_history"):
		diagram_actions.draw_history()
	elif Input.is_action_just_pressed("deleting"):
		return State.Deleting
	elif Input.is_action_just_pressed("editing"):
		return State.Hovering
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			$minimum_press_timer.start()
			cursor.change_cursor(GLOBALS.CURSOR.press)
			if can_draw():
				return State.Drawing
		elif !event.pressed and $minimum_press_timer.is_stopped():
			cursor.change_cursor(GLOBALS.CURSOR.default)
	elif Input.is_action_just_pressed("clear"):
		diagram_actions.add_diagram_to_history()
		diagram_actions.clear_diagram()
	elif Input.is_action_just_pressed("redo"):
		diagram_actions.redo()
	elif Input.is_action_just_pressed("undo"):
		diagram_actions.undo()
	
	return State.Null

func can_draw() -> bool:
	if !crosshair.can_draw:
		return false
	if diagram_actions.get_selected_particle() == GLOBALS.Particle.none:
		return false
	return true

func _on_minimum_press_timer_timeout():
	if state_manager.state == State.Idle and !Input.is_action_pressed("click"):
		cursor.change_cursor(GLOBALS.CURSOR.default)
