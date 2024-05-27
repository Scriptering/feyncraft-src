extends BaseState

var deleting_objects_count: int = 0

func input(_event: InputEvent) -> State:
	if Input.is_action_just_released("deleting"):
		return State.Idle
		
	elif Input.is_action_just_pressed("click"):
		change_cursor.emit(Globals.Cursor.snipped)
		delete()
		
	elif Input.is_action_just_released("click"):
		change_cursor.emit(Globals.Cursor.snip)

	return State.Null

func delete() -> void:
	for interaction:Interaction in Diagram.get_interactions():
		if !interaction.hovering:
			continue
			
		Diagram.delete_interaction(interaction)
		SOUNDBUS.snip()
		return
	
	for particle_line in Diagram.get_particle_lines():
		if !particle_line.is_hovered():
			continue
		
		Diagram.delete_line(particle_line)
		SOUNDBUS.snip()
		return
