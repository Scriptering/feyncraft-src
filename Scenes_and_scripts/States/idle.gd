extends BaseState

@export var minimum_press_time: float

func enter() -> void:
	super()
	EventBus.diagram_finger_pressed.connect(_on_diagram_finger_pressed)
	EventBus.diagram_mouse_pressed.connect(_on_diagram_mouse_pressed)

func exit() -> void:
	EventBus.diagram_finger_pressed.disconnect(_on_diagram_finger_pressed)
	EventBus.diagram_mouse_pressed.disconnect(_on_diagram_mouse_pressed)

func _ready() -> void:
	$minimum_press_timer.wait_time = minimum_press_time

func process(_delta: float) -> State:
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
	elif Input.is_action_just_pressed("click"):
		$minimum_press_timer.start()
		EventBus.change_cursor.emit(Globals.Cursor.press)
	elif !Input.is_action_pressed("click") and $minimum_press_timer.is_stopped():
		EventBus.change_cursor.emit(Globals.Cursor.default)
	
	return State.Null

func _on_diagram_finger_pressed(_index: int) -> void:
	if can_draw():
		change_state.emit(self, State.Drawing)

func _on_diagram_mouse_pressed() -> void:
	if can_draw():
		change_state.emit(self, State.Drawing)

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
