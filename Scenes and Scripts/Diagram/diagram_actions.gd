class_name DiagramBase
extends Panel

var ParticleButtons: Control

var line_diagram_actions: bool = true

@export var grid_size: int = 16

const MAX_DIAGRAM_HISTORY_SIZE : int = 10
var diagram_history: Array[DrawingMatrix] = []
var diagram_future: Array[DrawingMatrix] = []
var current_diagram: DrawingMatrix = null

@onready var Line = preload("res://Scenes and Scripts/Diagram/line.tscn")
@onready var InteractionInstance = preload("res://Scenes and Scripts/Diagram/interaction.tscn")

@onready var StateLines: Array = [$Initial, $Final]
@onready var Interactions: Control = $Interactions
@onready var ParticleLines: Control = $ParticleLines

func _ready() -> void:
	connect("mouse_entered", Callable($Crosshair, "DiagramMouseEntered"))
	connect("mouse_exited", Callable($Crosshair, "DiagramMouseExited"))

func init(particle_buttons: Control) -> void:
	ParticleButtons = particle_buttons

func update_statelines() -> void:
	for state_line in StateLines:
		state_line.update_stateline()

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
		line1.line_vector.normalized() == line2.line_vector.normalized() or
		line1.line_vector.normalized() == -line2.line_vector.normalized()
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

func draw_raw_diagram(connection_matrix : ConnectionMatrix) -> void:
	add_diagram_to_history()
	
	if connection_matrix == null:
		return
	
	var drawable_matrix := DrawingMatrix.new()
	drawable_matrix.grid_size = grid_size
	drawable_matrix.initialise_from_connection_matrix(connection_matrix)

	create_diagram_interaction_positions(drawable_matrix)
	draw_diagram(drawable_matrix)

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
		
	var radius : float = 90
	var circle_y_start : int = snapped(size.y/2, grid_size)

	for j in range(drawing_matrix.get_state_count(StateLine.StateType.None)):
		drawing_matrix.add_interaction_position(Vector2(
			snapped(
			(StateLines[StateLine.StateType.Initial].position.x + StateLines[StateLine.StateType.Final].position.x
			) / 2 + radius * cos(degree_pos[j]), grid_size),
			snapped(circle_y_start +  + radius * sin(degree_pos[j]), grid_size)
		))

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
		drawing_matrix.add_interaction_position(Vector2(StateLines[state].position.x, current_y))

func draw_diagram_particles(drawing_matrix: DrawingMatrix) -> Array[ParticleLine]:
	var drawing_lines : Array[ParticleLine] = []
	for i in range(drawing_matrix.matrix_size):
		for j in range(drawing_matrix.matrix_size):
			if !drawing_matrix.are_interactions_connected(i, j):
				continue
			
			var drawing_line : ParticleLine = Line.instantiate()

			drawing_line.base_particle = drawing_matrix.connection_matrix[i][j][0]

			drawing_line.points[ParticleLine.Point.Start] = drawing_matrix.get_interaction_positions()[i]
			drawing_line.points[ParticleLine.Point.End] = drawing_matrix.get_interaction_positions()[j]
			
			drawing_lines.append(drawing_line)

	return drawing_lines

func draw_diagram(drawing_matrix: DrawingMatrix) -> void:
	clear_diagram()
	
	line_diagram_actions = false
	
	for drawing_particle in draw_diagram_particles(drawing_matrix):
		drawing_particle.is_placed = true
		ParticleLines.add_child(drawing_particle)
		
	for interaction_position in drawing_matrix.get_interaction_positions():
		place_interaction(interaction_position, true)
	
	line_diagram_actions = true

func generate_drawing_matrix_from_diagram() -> DrawingMatrix:
	var generated_matrix := DrawingMatrix.new()
	generated_matrix.grid_size = grid_size

	for interaction in get_interactions():
		generated_matrix.add_interaction_with_position(interaction.position, interaction.get_on_state_line())

	for line in get_particle_lines():
		generated_matrix.connect_interactions(
			generated_matrix.get_interaction_positions().find(line.points[ParticleLine.Point.Start]),
			generated_matrix.get_interaction_positions().find(line.points[ParticleLine.Point.End]),
			line.base_particle
		)

	return generated_matrix

func undo() -> void:
	move_backward_in_history()

func redo() -> void:
	move_forward_in_history()

func add_diagram_to_history(clear_future: bool = true, diagram: DrawingMatrix = generate_drawing_matrix_from_diagram()) -> void:
	diagram_history.append(diagram)
	
	if clear_future:
		diagram_future.clear()
	
	if diagram_history.size() > MAX_DIAGRAM_HISTORY_SIZE:
		diagram_history.pop_front()

func add_diagram_to_future(diagram: DrawingMatrix = generate_drawing_matrix_from_diagram()) -> void:
	diagram_future.push_back(diagram)
	
func remove_last_diagram_from_history() -> void:
	diagram_history.pop_back()

func move_forward_in_history() -> void:
	if diagram_future.size() == 0:
		return
		
	add_diagram_to_history(false, current_diagram)
	current_diagram = diagram_future.back()
	diagram_future.pop_back()
	
	draw_diagram(current_diagram)

func move_backward_in_history() -> void:
	if diagram_history.size() == 0:
		return
	elif diagram_future.size() == 0:
		add_diagram_to_future()
	else:
		add_diagram_to_future(current_diagram)
	
	current_diagram = diagram_history.back()
	diagram_history.pop_back()
	draw_diagram(current_diagram)

func print_history_sizes() -> void:
	print("Diagram history size = " + str(diagram_history.size()))
	print("Diagram future  size  = " + str(diagram_future.size()))

func draw_history() -> void:
	for diagram in diagram_history:
		draw_diagram(diagram)
		await get_tree().create_timer(0.5).timeout
	
	for diagram in diagram_future:
		draw_diagram(diagram)
		await get_tree().create_timer(0.5).timeout
	

	


