class_name DiagramBase
extends Panel

@onready var StateLines: Array = [$Initial, $Final]
@onready var Interactions: Control = $Interactions
@onready var ParticleLines: Control = $ParticleLines

@export var grid_size: int
@export var InteractionInstance : PackedScene
@export var Line : PackedScene

func clear_diagram() -> void:
	return

func draw_raw_diagram(connection_matrix : ConnectionMatrix) -> void:
	if connection_matrix == null:
		return

	var drawable_matrix := DrawingMatrix.new()
	drawable_matrix.initialise_from_connection_matrix(connection_matrix)

	create_diagram_interaction_positions(drawable_matrix)
	draw_diagram(drawable_matrix)

func get_interactions() -> Array:
	return Interactions.get_children()

func get_particle_lines() -> Array:
	return ParticleLines.get_children()

func draw_diagram(drawing_matrix: DrawingMatrix) -> void:
	for drawing_particle in draw_diagram_particles(drawing_matrix):
		ParticleLines.add_child(drawing_particle)
		
	for interaction_position in drawing_matrix.get_interaction_positions():
		place_interaction(interaction_position * grid_size)

func generate_drawing_matrix_from_diagram() -> DrawingMatrix:
	var generated_matrix := DrawingMatrix.new()

	for interaction in get_interactions():
		generated_matrix.add_interaction_with_position(interaction.position, grid_size, interaction.get_on_state_line())

	for line in get_particle_lines():
		generated_matrix.connect_interactions(
			generated_matrix.get_interaction_positions().find(line.points[ParticleLine.Point.Start] / grid_size),
			generated_matrix.get_interaction_positions().find(line.points[ParticleLine.Point.End] / grid_size),
			line.base_particle
		)

	return generated_matrix

func create_diagram_interaction_positions(drawing_matrix: DrawingMatrix) -> void:

	for state in [StateLine.StateType.Initial, StateLine.StateType.Final]:
		create_state_diagram_interaction_positions(drawing_matrix, state)
	
	create_middle_diagram_interaction_positions(drawing_matrix)

func create_middle_diagram_interaction_positions(drawing_matrix: DrawingMatrix) -> void:
	var degree_pos : Array[float] = []
	var degree_step : float = 2 * PI / (drawing_matrix.get_state_count(StateLine.StateType.None))
	var degree_start : float = randf() * 2 * PI
	
	for i in range(drawing_matrix.get_state_count(StateLine.StateType.None)):
		degree_pos.append(i * degree_step + degree_start)
		
	var radius : float = 5 * grid_size
	var circle_y_start : int = snapped(size.y/2, grid_size)

	for j in range(drawing_matrix.get_state_count(StateLine.StateType.None)):
		drawing_matrix.add_interaction_position(Vector2(
			snapped(
			(StateLines[StateLine.StateType.Initial].position.x + StateLines[StateLine.StateType.Final].position.x
			) / 2 + radius * cos(degree_pos[j]), grid_size),
			snapped(circle_y_start +  + radius * sin(degree_pos[j]), grid_size)
		), grid_size)

func create_state_diagram_interaction_positions(drawing_matrix: DrawingMatrix, state: StateLine.StateType) -> void:
	var current_y : int = 0
	
	for state_id in drawing_matrix.get_state_ids(state):
		if drawing_matrix.get_state_from_id(state_id) == StateLine.StateType.None:
			continue
		
		for hadron in drawing_matrix.split_hadron_ids:
			if state_id not in hadron:
				continue
		
			if hadron.find(state_id) != 0:
				current_y -= grid_size
				
		current_y += 2*grid_size
		drawing_matrix.add_interaction_position(Vector2(StateLines[state].position.x, current_y), grid_size)

func place_interaction(interaction_position: Vector2) -> void:
	var interaction = InteractionInstance.instantiate()
	interaction.position = interaction_position
	Interactions.add_child(interaction)

func draw_diagram_particles(drawing_matrix: DrawingMatrix) -> Array:
	var drawing_lines : Array = []
	for i in range(drawing_matrix.matrix_size):
		for j in range(drawing_matrix.matrix_size):
			if !drawing_matrix.are_interactions_connected(i, j):
				continue
			
			var drawing_line = Line.instantiate()

			drawing_line.base_particle = drawing_matrix.connection_matrix[i][j][0]

			drawing_line.points[ParticleLine.Point.Start] = drawing_matrix.get_interaction_positions()[i] * grid_size
			drawing_line.points[ParticleLine.Point.End] = drawing_matrix.get_interaction_positions()[j] * grid_size

			drawing_lines.append(drawing_line)

	return drawing_lines
