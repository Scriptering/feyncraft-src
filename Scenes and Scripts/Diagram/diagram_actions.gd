class_name DiagramActions
extends Node

var Interactions: Control
var ParticleLines: Control
var ParticleButtons: Control
var StateLines: Array
var line_diagram_actions: bool = true

@onready var Line = preload("res://Scenes and Scripts/Diagram/line.tscn")
@onready var InteractionInstance = preload("res://Scenes and Scripts/Diagram/interaction.tscn")

func init(interactions: Control, particle_lines: Control, particle_buttons: Control, state_lines: Array) -> void:
	Interactions = interactions
	ParticleLines = particle_lines
	ParticleButtons = particle_buttons
	StateLines = state_lines

func place_objects() -> void:
	get_tree().call_group("grabbable", "drop")
	
	for line in ParticleLines.get_children():
		line.place()
	
	check_split_lines()

func get_interactions() -> Array[Interaction]:
	var interactions : Array[Interaction] = []
	for interaction in Interactions.get_children():
		if interaction is Interaction:
			interactions.append(interaction)
	
	return interactions

func get_particle_lines() -> Array[ParticleLine]:
	var particle_lines : Array[ParticleLine] = []
	for particle_line in ParticleLines.get_children():
		if particle_line is ParticleLine:
			particle_lines.append(particle_line)
	return particle_lines

func get_selected_particle() -> GLOBALS.Particle:
	return ParticleButtons.selected_particle

func delete_line(line: ParticleLine) -> void:
	line.queue_free()
	line.deconstructor()
	for interaction in line.connected_interactions:
		if interaction.connected_lines.size() == 0:
			interaction.queue_free()
	
	check_rejoin_lines()

func delete_interaction(interaction: Interaction) -> void:
	interaction.queue_free()
	var connected_lines := interaction.connected_lines.duplicate()
	for line in connected_lines:
		for connected_interaction in line.connected_interactions:
			if connected_interaction.connected_lines.size() == 1:
				connected_interaction.queue_free()
		delete_line(line)
	
	check_rejoin_lines()

func split_line(line_to_split: ParticleLine, split_point: Vector2) -> void:
	var new_line = Line.instantiate()

	new_line.points[ParticleLine.Point.Start] = line_to_split.points[ParticleLine.Point.Start]
	new_line.points[ParticleLine.Point.End] = split_point
	line_to_split.points[ParticleLine.Point.Start] = split_point

	new_line.base_particle = line_to_split.base_particle
	new_line.is_placed = true

	ParticleLines.add_child(new_line)

	line_to_split.update_line()

func check_split_lines() -> void:
	if !line_diagram_actions:
		return

	for interaction in Interactions.get_children():
		for line in get_tree().get_nodes_in_group('lines'):
			if !line.is_placed:
				continue
			if line in interaction.connected_lines:
				continue
			if line.is_position_on_line(interaction.position):
				split_line(line, interaction.position)

func check_rejoin_lines() -> void:
	if !line_diagram_actions:
		return
	
	for interaction in Interactions.get_children():
		if interaction.connected_lines.size() != 2:
			continue
		if interaction.connected_lines.any(func(line): return !is_instance_valid(line)):
			continue
		
		if can_rejoin_lines(interaction.connected_lines[0], interaction.connected_lines[1]):
			rejoin_lines(interaction.connected_lines[0], interaction.connected_lines[1])
			delete_interaction(interaction)

func can_rejoin_lines(line1: ParticleLine, line2: ParticleLine) -> bool:
	if !(line1.is_placed and line2.is_placed):
		return false
	
	if line1.base_particle != line2.base_particle:
		return false
	
	if line1.base_particle in GLOBALS.FERMIONS and line1.particle != line2.particle:
		return false

	if (
		line1.get_line_vector().normalized() == line2.get_line_vector().normalized() or
		line1.get_line_vector().normalized() == -line2.get_line_vector().normalized()
	):
		return true
	
	return false

func rejoin_lines(line_to_extend: ParticleLine, line_to_delete: ParticleLine) -> void:
	var point_to_move : int
	
	if line_to_extend.points[ParticleLine.Point.Start] in line_to_delete.points:
		point_to_move = ParticleLine.Point.Start
	else:
		point_to_move = ParticleLine.Point.End
	
	var point_to_move_to : int
	if line_to_delete.points[ParticleLine.Point.Start] in line_to_extend.points:
		point_to_move_to = ParticleLine.Point.End
	else:
		point_to_move_to = ParticleLine.Point.Start
	
	line_to_extend.points[point_to_move] = line_to_delete.points[point_to_move_to]
	delete_line(line_to_delete)
	line_to_extend.update_line()

func place_interaction(interaction_position: Vector2, bypass_can_place: bool = false) -> void:
	if can_place_interaction(interaction_position) or bypass_can_place:
		var interaction = InteractionInstance.instantiate()
		interaction.position = interaction_position
		Interactions.add_child(interaction)
	
		check_split_lines()
		check_rejoin_lines()

func can_place_interaction(test_position: Vector2) -> bool:
	for interaction in Interactions.get_children():
		if interaction.position == test_position:
			return false
	return true

func place_line(
	start_position: Vector2, end_position: Vector2 = Vector2.ZERO,
	base_particle: GLOBALS.Particle = ParticleButtons.selected_particle
) -> void:
	var line : ParticleLine = Line.instantiate()
	line.points[line.Point.Start] = start_position
	
	if end_position != Vector2.ZERO:
		line.points[line.Point.End] = end_position
		line.is_placed = true
	
	line.base_particle = base_particle
	
	ParticleLines.add_child(line)
	
	check_split_lines()
	check_rejoin_lines()

func clear_diagram() -> void:
	for interaction in Interactions.get_children():
		delete_interaction(interaction)
	for state_line in StateLines:
		state_line.clear_hadrons()

var drawing_matrix: ConnectionMatrix

func draw_raw_diagram(connection_matrix : ConnectionMatrix, make_drawable: bool = false) -> void:
	
	if connection_matrix == null:
		return
	
	var drawable_matrix : ConnectionMatrix = connection_matrix.duplicate()
	drawing_matrix = drawable_matrix
	
	if make_drawable:
		drawable_matrix.seperate_double_connections()
		drawable_matrix.split_hadrons()

	create_diagram_interaction_positions(drawable_matrix)
	draw_diagram(drawable_matrix)

func create_diagram_interaction_positions(connection_matrix: ConnectionMatrix) -> void:

	for state in [StateLine.StateType.Initial, StateLine.StateType.Final]:
		create_state_diagram_interaction_positions(connection_matrix, state)
	
	create_middle_diagram_interaction_positions(connection_matrix)

func create_middle_diagram_interaction_positions(connection_matrix: ConnectionMatrix) -> void:
	var degree_pos : Array[float ] = []
	var degree_step : float = 2 * PI / (connection_matrix.get_state_count(StateLine.StateType.None))
	var degree_start : float = randf() * 2 * PI
	
	for i in range(connection_matrix.get_state_count(StateLine.StateType.None)):
		degree_pos.append(i * degree_step + degree_start)
		
	var radius : float = 90
	var circle_y_start : int = 16 * 11

	for j in range(connection_matrix.get_state_count(StateLine.StateType.None)):
		connection_matrix.interaction_positions.append(Vector2(
			snapped(
			(StateLines[StateLine.StateType.Initial].position.x + StateLines[StateLine.StateType.Final].position.x
			) / 2 + radius * cos(degree_pos[j]), 16) + 1,
			snapped(circle_y_start +  + radius * sin(degree_pos[j]), 16) + 1
		))

func create_state_diagram_interaction_positions(connection_matrix: ConnectionMatrix, state: StateLine.StateType) -> void:
	var current_y : int = snapped(StateLines[StateLine.StateType.Initial].position.y, 16) + 32
	
	for state_id in connection_matrix.get_state_ids(state):
		connection_matrix.interaction_positions.append(Vector2(StateLines[state].position.x, current_y))
		
		current_y += 32
		
		if connection_matrix.get_state_from_id(state_id) == StateLine.StateType.None:
			continue
		
		for hadron in connection_matrix.split_hadron_ids:
			if state_id not in hadron:
				continue
		
			if hadron.find(state_id) != 0:
				current_y -= 16

func draw_diagram_particles(connection_matrix: ConnectionMatrix) -> Array[ParticleLine]:
	var drawing_lines : Array[ParticleLine] = []
	for i in range(connection_matrix.matrix_size):
		for j in range(connection_matrix.matrix_size):
			if !connection_matrix.are_interactions_connected(i, j):
				continue
			
			var drawing_line : ParticleLine = Line.instantiate()

			drawing_line.base_particle = connection_matrix.connection_matrix[i][j][0]

			drawing_line.points[ParticleLine.Point.Start] = connection_matrix.interaction_positions[i]
			drawing_line.points[ParticleLine.Point.End] = connection_matrix.interaction_positions[j]
			
			drawing_lines.append(drawing_line)

	return drawing_lines

func draw_diagram(connection_matrix: ConnectionMatrix) -> void:
	clear_diagram()
	
	line_diagram_actions = false
	
	for drawing_particle in draw_diagram_particles(connection_matrix):
		drawing_particle.is_placed = true
		ParticleLines.add_child(drawing_particle)
		
	for interaction_position in connection_matrix.interaction_positions:
		place_interaction(interaction_position, true)
	
	line_diagram_actions = true


