class_name DiagramBase
extends Panel

@onready var StateLines: Array = [$DiagramArea/Initial, $DiagramArea/Final]
@onready var Interactions: Control = $DiagramArea/Interactions
@onready var ParticleLines: Node2D = $DiagramArea/ParticleLines
@onready var HadronJoints: Control = $DiagramArea/HadronJoints

@export var grid_size: int
@export var InteractionInstance : PackedScene
@export var particle_line_scene : PackedScene

var grid_width: int:
	get:
		return snapped(StateLines[StateLine.StateType.Final].position.x - StateLines[StateLine.StateType.Initial].position.x, grid_size)

var grid_height: int:
	get:
		return int(size.y)

var grid_centre: int:
	get:
		return snapped(
			(StateLines[StateLine.StateType.Initial].position.x + StateLines[StateLine.StateType.Final].position.x) / 2, grid_size
		)

func clear_diagram() -> void:
	return

func draw_raw_diagram(connection_matrix : ConnectionMatrix) -> void:
	if connection_matrix == null:
		return

	var drawable_matrix := DrawingMatrix.new()
	drawable_matrix.initialise_from_connection_matrix(connection_matrix)
	
	for id:int in drawable_matrix.get_state_ids(StateLine.StateType.Both):
		if drawable_matrix.get_connected_count(id) > 1:
			breakpoint

	create_diagram_interaction_positions(drawable_matrix)
	draw_diagram(drawable_matrix)

func get_interactions() -> Array:
	return Interactions.get_children().filter(
		func(interaction:Variant) -> bool:
			return (!interaction.is_queued_for_deletion() and
					interaction.is_inside_tree())
	)

func get_particle_lines() -> Array:
	return ParticleLines.get_children().filter(
		func(particle_line:Variant) -> bool:
			return (!particle_line.is_queued_for_deletion() and
					particle_line.is_inside_tree())
	)

func get_hadron_joints() -> Array:
	return HadronJoints.get_children().filter(
		func(hadron_joint:Variant) -> bool:
			return (!hadron_joint.is_queued_for_deletion() and
			hadron_joint.is_inside_tree())
	)

func draw_diagram(drawing_matrix: DrawingMatrix) -> void:
	clear_diagram()
	
	for state:StateLine.StateType in StateLine.STATES:
		StateLines[state].position.x = drawing_matrix.state_line_positions[state] * grid_size

	for drawing_particle:ParticleLine in draw_diagram_particles(drawing_matrix):
		ParticleLines.add_child(drawing_particle)
	
	for interaction_position:Vector2 in drawing_matrix.get_interaction_positions():
		place_interaction(interaction_position * grid_size)

func get_on_stateline(test_position: Vector2) -> StateLine.StateType:
	return ArrayFuncs.find_var(
		StateLines,
		func(state_line: StateLine) -> bool:
			return is_zero_approx(state_line.position.x - test_position.x)
	) as StateLine.StateType
	
func generate_drawing_matrix_from_diagram() -> DrawingMatrix:
	var generated_matrix := DrawingMatrix.new()
	var interactions: Array = get_interactions()

	for interaction:Interaction in interactions:
		generated_matrix.add_interaction_with_position(interaction.position, grid_size, interaction.get_on_state_line())

	for particle_line:ParticleLine in get_particle_lines():
		generated_matrix.connect_interactions(
			generated_matrix.get_interaction_positions().find(particle_line.points[ParticleLine.Point.Start] / grid_size),
			generated_matrix.get_interaction_positions().find(particle_line.points[ParticleLine.Point.End] / grid_size),
			particle_line.base_particle
		)
	
	for state:StateLine.StateType in StateLine.STATES:
		generated_matrix.state_line_positions[state] = StateLines[state].position.x / grid_size
	
	var hadron_ids: Array[PackedInt32Array] = []
	for hadron_joint:HadronJoint in get_hadron_joints():
		var hadron_id: PackedInt32Array = []
		for interaction:Interaction in interactions.filter(
			func(interaction: Interaction) -> bool:
				return interaction in hadron_joint.get_hadron_interactions()
		):
			hadron_id.push_back(
				ArrayFuncs.find_var(
					generated_matrix.get_interaction_positions(grid_size),
					func(interaction_position: Vector2) -> bool:
						return interaction.position == interaction_position
			))
		hadron_ids.push_back(hadron_id)
	generated_matrix.split_hadron_ids = hadron_ids
	
	return generated_matrix

func create_diagram_interaction_positions(drawing_matrix: DrawingMatrix) -> void:

	for state:StateLine.StateType in StateLine.STATES:
		create_state_diagram_interaction_positions(drawing_matrix, state)
	
	create_middle_diagram_interaction_positions(drawing_matrix)

func create_middle_diagram_interaction_positions(drawing_matrix: DrawingMatrix) -> void:
	var degree_pos : Array[float] = []
	var degree_step : float = 2 * PI / (drawing_matrix.get_state_count(StateLine.StateType.None))
	var degree_start : float = randf() * 2 * PI
	
	for i:int in range(drawing_matrix.get_state_count(StateLine.StateType.None)):
		degree_pos.append(i * degree_step + degree_start)
		
	var radius : float = snapped(min(grid_width, grid_height) / 2 - grid_size, grid_size)
	var circle_y_start : int = snapped(grid_height / 2.0, grid_size)
	var circle_x : int = grid_centre

	for j:int in range(drawing_matrix.get_state_count(StateLine.StateType.None)):
		drawing_matrix.add_interaction_position(Vector2(
			snapped(circle_x + radius * cos(degree_pos[j]), grid_size),
			snapped(circle_y_start + radius * sin(degree_pos[j]), grid_size)
		), grid_size)

func create_state_diagram_interaction_positions(drawing_matrix: DrawingMatrix, state: StateLine.StateType) -> void:
	var current_y : int = 0
	
	for state_id:int in drawing_matrix.get_state_ids(state):
		if drawing_matrix.get_state_from_id(state_id) == StateLine.StateType.None:
			continue
		
		for hadron:Array[int] in drawing_matrix.split_hadron_ids:
			if state_id not in hadron:
				continue
		
			if hadron.find(state_id) != 0:
				current_y -= grid_size
				
		current_y += 2*grid_size
		drawing_matrix.add_interaction_position(
			Vector2(StateLines[state].position.x, current_y), grid_size
		)

func place_interaction(interaction_position: Vector2, interaction: Node = InteractionInstance.instantiate()) -> void:
	interaction.position = interaction_position
	interaction.init(self)
	Interactions.add_child(interaction)

func create_particle_line() -> ParticleLine:
	var particle_line := particle_line_scene.instantiate()
	particle_line.init(self)
	return particle_line

func draw_diagram_particles(drawing_matrix: DrawingMatrix) -> Array:
	var drawing_lines : Array = []
	for i:int in drawing_matrix.matrix_size:
		for j:int in drawing_matrix.matrix_size:
			if !drawing_matrix.are_interactions_connected(i, j):
				continue
			
			var drawing_line := create_particle_line()

			drawing_line.base_particle = drawing_matrix.connection_matrix[i][j][0]

			drawing_line.points[ParticleLine.Point.Start] = drawing_matrix.get_interaction_positions()[i] * grid_size
			drawing_line.points[ParticleLine.Point.End] = drawing_matrix.get_interaction_positions()[j] * grid_size

			drawing_lines.append(drawing_line)

	return drawing_lines
