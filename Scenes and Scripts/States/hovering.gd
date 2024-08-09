extends BaseState

signal split_interaction(interaction: Interaction)

var start_placing := false
var grabbed_object: Node
var grab_start_position: Vector2 = Vector2.ZERO

func enter() -> void:
	super.enter()
	grabbed_object = null
	connect_grabbable()

func exit() -> void:
	super.exit()
	grabbed_object = null
	disconnect_grabbable()

func input(_event: InputEvent) -> State:
	if Input.is_action_just_released("editing"):
		return State.Idle
	
	if Input.is_action_just_released("click"):
		EventBus.change_cursor.emit(Globals.Cursor.hover)
		grabbed_object = null

	return State.Null

func process(_delta: float) -> State:
	if start_placing:
		start_placing = false
		return State.Placing
	return State.Null

func crosshair_moved(_old_position: Vector2, _new_position: Vector2) -> void:
	if grabbed_object and Input.is_action_pressed("click"):
		if grabbed_object is Interaction:
			interaction_grabbed_and_moved()
			grabbed_object = null

func connect_grabbable() -> void:
	for object in get_tree().get_nodes_in_group("grabbable"):
		object.grab_area_clicked.connect(_grabbable_object_clicked)

func disconnect_grabbable() -> void:
	for object in get_tree().get_nodes_in_group("grabbable"):
		if object.grab_area_clicked.is_connected(_grabbable_object_clicked):
			object.grab_area_clicked.disconnect(_grabbable_object_clicked)

func _grabbable_object_clicked(object: Node) -> void:
	if !object.can_be_grabbed():
		return
	
	EventBus.change_cursor.emit(Globals.Cursor.hold)
	
	if object is Interaction:
		grab_start_position = object.position
		grabbed_object = object
	else:
		start_placing = true
		object.pick_up()

func interaction_grabbed_and_moved() -> void:
	Diagram.add_diagram_to_history()
	
	if Input.is_action_pressed("split_interaction"):
		Diagram.split_interaction(grabbed_object)
	
	start_placing = true
	grabbed_object.pick_up()
	grabbed_object.start_grab_position = grab_start_position
