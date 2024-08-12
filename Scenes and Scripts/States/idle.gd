extends BaseState

@export var minimum_press_time: float

var hovering_disabled_button: bool = false

func _ready() -> void:
	$minimum_press_timer.wait_time = minimum_press_time

func connect_buttons() -> void:
	for button in get_tree().get_nodes_in_group('button'):
		if button is PanelButton:
			continue

func input(event: InputEvent) -> State:
	if Input.is_action_just_pressed("draw_history"):
		Diagram.draw_history()
	elif Input.is_action_just_pressed("deleting"):
		return State.Deleting
	elif Input.is_action_just_pressed("editing"):
		return State.Hovering
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and !hovering_disabled_button:
		if event.pressed:
			$minimum_press_timer.start()
			EventBus.change_cursor.emit(Globals.Cursor.press)
			if can_draw():
				return State.Drawing
		elif !event.pressed and $minimum_press_timer.is_stopped():
			EventBus.change_cursor.emit(Globals.Cursor.default)
	elif Input.is_action_just_pressed("clear") and !Globals.in_main_menu:
		Diagram.add_diagram_to_history()
		Diagram.clear_diagram()
	elif Input.is_action_just_pressed("redo"):
		Diagram.redo()
	elif Input.is_action_just_pressed("undo"):
		Diagram.undo()
	
	return State.Null

func can_draw() -> bool:
	if !crosshair.can_draw:
		return false
	if Diagram.get_selected_particle() == ParticleData.Particle.none:
		return false
	return true

func _on_button_mouse_entered(button: PanelButton) -> void:
	if !button.disabled or state_manager.state != State.Idle:
		return
	
	EventBus.change_cursor.emit(Globals.Cursor.disabled)
	hovering_disabled_button = true

func _on_button_mouse_exited() -> void:
	if state_manager.state != State.Idle:
		return
	
	EventBus.change_cursor.emit(Globals.Cursor.default)
	hovering_disabled_button = false

func _on_minimum_press_timer_timeout() -> void:
	if state_manager.state == State.Idle and !Input.is_action_pressed("click"):
		EventBus.change_cursor.emit(Globals.Cursor.default)
