extends BaseState

var deleting_objects_count: int = 0

func enter() -> void:
	super.enter()
	connect_deletable()

func exit() -> void:
	super.exit()
	disconnect_deletable()

func connect_deletable() -> void:
	for line in get_tree().get_nodes_in_group("lines"):
		line.clicked_on.connect(line_deletion)
	for interaction in get_tree().get_nodes_in_group("interactions"):
		interaction.clicked_on.connect(interaction_deletion)

func disconnect_deletable() -> void:
	for line in get_tree().get_nodes_in_group("lines"):
		line.clicked_on.disconnect(line_deletion)
	for interaction in get_tree().get_nodes_in_group("interactions"):
		interaction.clicked_on.disconnect(interaction_deletion)

func input(_event: InputEvent) -> State:
	if Input.is_action_just_released("deleting"):
		return State.Idle
	elif Input.is_action_just_pressed("click"):
		cursor.change_cursor(GLOBALS.CURSOR.snipped)
	elif Input.is_action_just_released("click"):
		cursor.change_cursor(GLOBALS.CURSOR.snip)

	return State.Null

func line_deletion(line: ParticleLine) -> void:
	deleting_objects_count += 1
	
	if deleting_objects_count == 1:
		Diagram.add_diagram_to_history()
		
	Diagram.delete_line(line)
	
	SOUNDBUS.snip()
	
	await get_tree().process_frame
	
	deleting_objects_count -= 1
	

func interaction_deletion(interaction: Interaction) -> void:
	deleting_objects_count += 1
	
	if deleting_objects_count == 1:
		Diagram.add_diagram_to_history()
		
	Diagram.delete_interaction(interaction)
	
	SOUNDBUS.snip()
	
	await get_tree().process_frame
	
	deleting_objects_count -=1
