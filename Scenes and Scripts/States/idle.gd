extends BaseState

@export var minimum_press_time: float

func _ready() -> void:
	$minimum_press_timer.wait_time = minimum_press_time

func input(event: InputEvent) -> State:
	if Input.is_action_just_pressed("draw_history"):
		Diagram.draw_history()
	elif Input.is_action_just_pressed("deleting"):
		return State.Deleting
	elif Input.is_action_just_pressed("editing"):
		return State.Hovering
	elif Input.is_action_just_pressed("clear") and !Globals.in_main_menu:
		Diagram.add_diagram_to_history()
		Diagram.clear_diagram()
	elif Input.is_action_just_pressed("redo"):
		Diagram.redo()
	elif Input.is_action_just_pressed("undo"):
		Diagram.undo()
	elif Globals.is_on_mobile():
		return handle_mobile_event(event)
	elif !Globals.is_on_mobile() and Input.is_action_just_pressed("click"):
		if event.pressed:
			$minimum_press_timer.start()
			EventBus.change_cursor.emit(Globals.Cursor.press)
			if can_draw():
				return State.Drawing
		elif !event.pressed and $minimum_press_timer.is_stopped():
			EventBus.change_cursor.emit(Globals.Cursor.default)
	
	return State.Null

func handle_mobile_event(event: InputEvent) -> BaseState.State:
	crosshair.handle_mobile_event(event)
	
	if event is InputEventScreenTouch and event.pressed and can_draw():
		print("Drawing")
		return State.Drawing
	
	return State.Null

func can_draw() -> bool:
	if !crosshair.last_input_inside_area:
		return false
	if !crosshair.is_start_drawing_position_valid():
		return false
	if Diagram.drawing_particle == ParticleData.Particle.none:
		return false
	return true

func _on_minimum_press_timer_timeout() -> void:
	if state_manager.state == State.Idle and !Input.is_action_pressed("click"):
		EventBus.change_cursor.emit(Globals.Cursor.default)
