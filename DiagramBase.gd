class_name DiagramBase
extends Panel

@onready var StateLines: Array = [$DiagramArea/Initial, $DiagramArea/Final]
@onready var Interactions: Node2D = $DiagramArea/Interactions
@onready var ParticleLines: Node2D = $DiagramArea/ParticleLines
@onready var HadronJoints: Control = $DiagramArea/HadronJoints

@export var grid_size: int
@export var InteractionInstance : PackedScene
@export var particle_line_scene : PackedScene

var grid_width: int:
	get:
		return snapped(StateLines[StateLine.State.Final].position.x - StateLines[StateLine.State.Initial].position.x, grid_size)

var grid_height: int:
	get:
		return int(size.y)

var grid_centre: int:
	get:
		return snapped(
			(StateLines[StateLine.State.Initial].position.x + StateLines[StateLine.State.Final].position.x) / 2, grid_size
		)

func clear_diagram() -> void:
	return

func draw_raw_diagram(connection_matrix : ConnectionMatrix) -> void:
	if connection_matrix == null:
		return

	var drawable_matrix := DrawingMatrix.new()
	drawable_matrix.initialise_from_connection_matrix(connection_matrix)
	
	for id:int in drawable_matrix.get_state_ids(StateLine.State.Both):
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
	
	for state:StateLine.State in StateLine.STATES:
		StateLines[state].position.x = drawing_matrix.state_line_positions[state] * grid_size

	for drawing_particle:Variant in draw_diagram_particles(drawing_matrix):
		ParticleLines.add_child(drawing_particle)
	
	for interaction_position:Vector2 in drawing_matrix.get_interaction_positions():
		place_interaction(interaction_position * grid_size)

func get_on_stateline(test_position: Vector2) -> StateLine.State:
	return ArrayFuncs.find_var(
		StateLines,
		func(state_line: StateLine) -> bool:
			return is_zero_approx(state_line.position.x - test_position.x)
	) as StateLine.State
	
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
	
	for state:StateLine.State in StateLine.STATES:
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

	for state:StateLine.State in StateLine.STATES:
		create_state_diagram_interaction_positions(drawing_matrix, state)
	
	for pos: Vector2 in generate_spring_layout_positions(drawing_matrix):
		var snapped_pos: Vector2i = Vector2(
			snapped(clamp(pos.x, grid_size, grid_width - grid_size), grid_size),
			snapped(clamp(pos.y, grid_size, grid_height - grid_size), grid_size)
		)
		
		while snapped_pos in drawing_matrix.get_interaction_positions(grid_size):
			if snapped_pos.x < (grid_width - grid_size):
				snapped_pos.x += grid_size
				continue
			elif snapped_pos.y < (grid_height - grid_size):
				snapped_pos.y += grid_size
				continue
		
		drawing_matrix.add_interaction_position(snapped_pos, grid_size)
	#create_middle_diagram_interaction_positions(drawing_matrix)

func create_middle_diagram_interaction_positions(drawing_matrix: DrawingMatrix) -> Array[Vector2]:
	var degree_pos : Array[float] = []
	var degree_step : float = 2 * PI / (drawing_matrix.get_state_count(StateLine.State.None))
	var degree_start : float = randf() * 2 * PI
	
	for i:int in range(drawing_matrix.get_state_count(StateLine.State.None)):
		degree_pos.append(i * degree_step + degree_start)
		
	var radius : float = snapped(min(grid_width, grid_height) / 2 - grid_size, grid_size)
	var circle_y_start : int = snapped(grid_height / 2.0, grid_size)
	var circle_x : int = grid_centre
	
	var positions: Array[Vector2] = []
	for j: int in range(drawing_matrix.get_state_count(StateLine.State.None)):
		positions.push_back(Vector2(
			circle_x + radius * cos(degree_pos[j]),
			circle_y_start + radius * sin(degree_pos[j])
		))
	return positions

	#for j:int in range(drawing_matrix.get_state_count(StateLine.State.None)):
		#drawing_matrix.add_interaction_position(Vector2(
			#snapped(circle_x + radius * cos(degree_pos[j]), grid_size),
			#snapped(circle_y_start + radius * sin(degree_pos[j]), grid_size)
		#), grid_size)

func generate_start_positions(drawing_matrix: DrawingMatrix) -> Array[Vector2]:
	var positions: Array[Vector2]
	positions.assign(drawing_matrix.get_interaction_positions(grid_size))
	positions.append_array(create_middle_diagram_interaction_positions(drawing_matrix))
	
	#for id:int in drawing_matrix.get_state_ids(StateLine.State.None):
		#positions.push_back(
			#Vector2(
				#randf_range(grid_size, grid_width - grid_size),
				#randf_range(grid_size, grid_height - grid_size)
			#)
		#)
	
	return positions

func generate_spring_layout_positions(
	drawing_matrix: DrawingMatrix,
	loop_count: int = 200,
	c1: float = 4,
	c2: float = 200,
	c3: float = 750,
	c4: float = .1,
	c5: float = 10
) -> Array[Vector2]:

	var positions: Array[Vector2] = generate_start_positions(drawing_matrix)
	var mid_ids: PackedInt32Array = drawing_matrix.get_state_ids(StateLine.State.None)
	
	var forces: Array[Vector2] = []
	forces.resize(drawing_matrix.matrix_size)
	
	for loop:int in loop_count:
		for id:int in mid_ids:
			forces[id] = Vector2.ZERO
			for jd:int in drawing_matrix.matrix_size:
				if id == jd:
					continue
				
				forces[id] += Vector2((
					 c5 / positions[id].x
				) if positions[id].x < grid_width/2 else (
					c5 / (-(grid_width - positions[id].x))
				), 0)

				forces[id] += (
					calc_force(
						id, jd,
						positions[id], positions[jd],
						drawing_matrix,
						c1, c2, c3
						)
				)
		
		for id:int in mid_ids:
			positions[id] += c4*forces[id]
			
			if positions[id].x > grid_width - grid_size:
				positions[id].x -= 5*(positions[id].x - (grid_width - grid_size))
			elif positions[id].x < grid_size:
				positions[id].x += 5*(grid_size - positions[id].x)
			
			if positions[id].y > grid_height - grid_size:
				positions[id].y -= 5*(positions[id].y - (grid_height - grid_size))
			elif positions[id].y < grid_size:
				positions[id].y += 5*(grid_size - positions[id].y)
	
	var mid_positions: Array[Vector2] = []
	for i:int in positions.size():
		if i in drawing_matrix.get_state_ids(StateLine.State.None):
			mid_positions.push_back(positions[i])
	
	return mid_positions

func calc_force(
	A: int, B:int,
	pos_A: Vector2, pos_B: Vector2,
	matrix: DrawingMatrix,
	c1: float, c2: float, c3: float
) -> Vector2:

	var A_to_B: Vector2 = pos_B - pos_A
	var d: float = A_to_B.length() / grid_size
	var norm: Vector2 = A_to_B.normalized()
	
	var force: float = 0
	if matrix.are_interactions_connected(A, B, true):
		force += c1 * d
	else:
		force += -(c2 / (d*d))
		
	force += -(c3 / (d*d*d))
	
	return norm * force

func create_state_diagram_interaction_positions(drawing_matrix: DrawingMatrix, state: StateLine.State) -> void:
	var particle_count: int = 0
	for state_id:int in drawing_matrix.get_state_ids(state):
		var hadron_id: int = ArrayFuncs.find_var(
			drawing_matrix.split_hadron_ids,
			func(hadron: PackedInt32Array) -> bool:
				return state_id in hadron
		)
		
		if hadron_id == drawing_matrix.split_hadron_ids.size():
			particle_count += 1
			continue
		
		var hadron_pos: int = drawing_matrix.split_hadron_ids[hadron_id].find(state_id)
		
		if hadron_pos == 0:
			particle_count += 1
			continue
	
	var gap: int = floor(grid_height / (particle_count + 1))
	var current_y: int = 0
	
	for state_id:int in drawing_matrix.get_state_ids(state):
		var hadron_id: int = ArrayFuncs.find_var(
			drawing_matrix.split_hadron_ids,
			func(hadron: PackedInt32Array) -> bool:
				return state_id in hadron
		)
		
		if hadron_id == drawing_matrix.split_hadron_ids.size():
			current_y += gap
			drawing_matrix.add_interaction_position(
				Vector2(StateLines[state].position.x, current_y), grid_size
			)
			continue
		
		var hadron_pos: int = drawing_matrix.split_hadron_ids[hadron_id].find(state_id)
		
		if hadron_pos == 0:
			current_y += gap
			if gap > 2*grid_size:
				current_y -= grid_size
			drawing_matrix.add_interaction_position(
				Vector2(StateLines[state].position.x, current_y), grid_size
			)
			continue
		
		current_y += grid_size
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
