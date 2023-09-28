extends BaseState

@export var minimum_press_time: float

var hovering_disabled_button: bool = false

func _ready() -> void:
	$minimum_press_timer.wait_time = minimum_press_time

func connect_buttons() -> void:
	for button in get_tree().get_nodes_in_group('button'):
		button.button_mouse_entered.connect(_on_button_mouse_entered)
		button.mouse_exited.connect(_on_button_mouse_exited)

func disconnect_buttons() -> void:
	for button in get_tree().get_nodes_in_group('button'):
		if button.button_mouse_entered.is_connected(_on_button_mouse_entered):
			button.button_mouse_entered.disconnect(_on_button_mouse_entered)
		if button.mouse_exited.is_connected(_on_button_mouse_exited):
			button.mouse_exited.disconnect(_on_button_mouse_exited)

func enter() -> void:
	super.enter()
	connect_buttons()

func exit() -> void:
	super.exit()
	disconnect_buttons()

func process(_delta: float) -> State:
	if Controls.Snip.is_just_pressed:
		return State.Deleting
	elif Controls.Grab.is_just_pressed:
		return State.Hovering
	
	return State.Null

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
			emit_signal("change_cursor", GLOBALS.CURSOR.press)
			if can_draw():
				return State.Drawing
		elif !event.pressed and $minimum_press_timer.is_stopped():
			emit_signal("change_cursor", GLOBALS.CURSOR.default)
	elif Input.is_action_just_pressed("clear"):
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
	if Diagram.get_selected_particle() == GLOBALS.Particle.none:
		return false
	return true

func _on_button_mouse_entered(button: PanelButton) -> void:
	if !button.disabled:
		return
	
	emit_signal("change_cursor", GLOBALS.CURSOR.disabled)
	hovering_disabled_button = true

func _on_button_mouse_exited() -> void:
	emit_signal("change_cursor", GLOBALS.CURSOR.default)
	hovering_disabled_button = false

func _on_minimum_press_timer_timeout():
	if state_manager.state == State.Idle and !Input.is_action_pressed("click"):
		emit_signal("change_cursor", GLOBALS.CURSOR.default)
