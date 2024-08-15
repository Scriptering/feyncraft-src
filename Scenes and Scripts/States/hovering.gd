extends BaseState

var start_placing := false
var grabbed_object: Node

func enter() -> void:
	super.enter()
	grabbed_object = null
	EventBus.grabbable_object_clicked.connect(_grabbable_object_clicked)

func exit() -> void:
	super.exit()
	grabbed_object = null
	EventBus.grabbable_object_clicked.disconnect(_grabbable_object_clicked)

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

func _grabbable_object_clicked(object: Node) -> void:
	if !object.can_be_grabbed():
		return
	
	EventBus.change_cursor.emit(Globals.Cursor.hold)
	
	start_placing = true
	object.pick_up()
