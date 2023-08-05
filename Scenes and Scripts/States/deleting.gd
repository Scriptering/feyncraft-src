extends BaseState

func enter() -> void:
	super.enter()
	connect_deletable()

func exit() -> void:
	super.exit()
	disconnect_deletable()

func connect_deletable() -> void:
	for line in get_tree().get_nodes_in_group("lines"):
		line.connect("clicked_on", Callable(self, "line_deletion"))
	for interaction in get_tree().get_nodes_in_group("interactions"):
		interaction.connect("clicked_on", Callable(self, "interaction_deletion"))

func disconnect_deletable() -> void:
	for line in get_tree().get_nodes_in_group("lines"):
		line.disconnect("clicked_on", Callable(self, "line_deletion"))
	for interaction in get_tree().get_nodes_in_group("interactions"):
		interaction.disconnect("clicked_on", Callable(self, "interaction_deletion"))

func input(_event: InputEvent) -> State:
	if Input.is_action_just_released("deleting"):
		return State.Idle
	elif Input.is_action_just_pressed("click"):
		cursor.change_cursor(GLOBALS.CURSOR.snipped)
	elif Input.is_action_just_released("click"):
		cursor.change_cursor(GLOBALS.CURSOR.snip)

	return State.Null

func line_deletion(line: ParticleLine) -> void:
	diagram_actions.add_diagram_to_history()
	diagram_actions.delete_line(line)

func interaction_deletion(interaction: Interaction) -> void:
	diagram_actions.add_diagram_to_history()
	diagram_actions.delete_interaction(interaction)
