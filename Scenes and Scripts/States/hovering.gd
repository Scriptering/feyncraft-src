extends BaseState

var start_placing := false

func enter() -> void:
	super.enter()
	connect_grabbable()

func exit() -> void:
	super.exit()
	disconnect_grabbable()

func input(_event: InputEvent) -> State:
	if Input.is_action_just_released("editing"):
		return State.Idle

	return State.Null

func process(_delta: float) -> State:
	if start_placing:
		start_placing = false
		return State.Placing
	return State.Null

func connect_grabbable() -> void:
	for object in get_tree().get_nodes_in_group("grabbable"):
		object.grab_area_clicked.connect(_grabbable_object_clicked)

func disconnect_grabbable() -> void:
	for object in get_tree().get_nodes_in_group("grabbable"):
		if object.grab_area_clicked.connected(_grabbable_object_clicked):
			object.grab_area_clicked.disconnect(_grabbable_object_clicked)

func _grabbable_object_clicked(object: Node) -> void:
	if !object.can_be_grabbed():
		return

	start_placing = true
	
	if object is Interaction:
		Diagram.add_diagram_to_history()
		
		if Input.is_action_pressed("split_interaction"):
			Diagram.split_interaction(object)

	object.pick_up()
