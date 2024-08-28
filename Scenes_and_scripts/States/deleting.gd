extends BaseState

func enter() -> void:
	super()
	print("deleting")
	EventBus.deletable_object_clicked.connect(_deletable_object_clicked)

func exit() -> void:
	super()
	print("leaving deleting")
	EventBus.deletable_object_clicked.disconnect(_deletable_object_clicked)

func _deletable_object_clicked(obj: Node) -> void:
	delete(obj)

func input(_event: InputEvent) -> State:
	if Input.is_action_just_released("deleting"):
		return State.Idle
		
	elif Input.is_action_just_pressed("click"):
		EventBus.change_cursor.emit(Globals.Cursor.snipped)
		
	elif Input.is_action_just_released("click"):
		EventBus.change_cursor.emit(Globals.Cursor.snip)

	return State.Null

func delete(obj: Node) -> void:
	SOUNDBUS.snip()
	obj.delete()
