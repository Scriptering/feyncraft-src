class_name MainDiagram
extends DiagramBase

@onready var Crosshair := $DiagramArea/Crosshair
@onready var DiagramArea := $DiagramArea

var ParticleButtons: Control

var line_diagram_actions: bool = true

var crosshair_above_interactions: bool = false

const MAX_DIAGRAM_HISTORY_SIZE : int = 10
var diagram_history: Array[DrawingMatrix] = []
var diagram_future: Array[DrawingMatrix] = []
var current_diagram: DrawingMatrix = null

func _ready() -> void:
	Crosshair.moved.connect(_crosshair_moved)
	connect("mouse_entered", Callable(Crosshair, "DiagramMouseEntered"))
	connect("mouse_exited", Callable(Crosshair, "DiagramMouseExited"))
	EVENTBUS.connect("signal_draw_diagram", Callable(self, "draw_diagram"))
	EVENTBUS.connect("signal_draw_raw_diagram", Callable(self, "draw_raw_diagram"))
	
	for state_line in StateLines:
		state_line.init(self)
	
	Crosshair.init(self, StateLines, grid_size)

func init(particle_buttons: Control) -> void:
	ParticleButtons = particle_buttons

func _process(_delta: float) -> void:
	for stateline in StateLines:
		if stateline.grabbed:
			move_stateline(stateline)

func _crosshair_moved(new_position: Vector2, old_position: Vector2) -> void:
	for particle_line in get_particle_lines():
		particle_line.crosshair_moved(new_position, old_position)
	
	for interaction in get_interactions():
		interaction.crosshair_moved(new_position, old_position)
	
	update_statelines()

func move_stateline(stateline: StateLine) -> void:
	var non_state_interactions := get_interactions().filter(
		func(interaction: Interaction):
			return interaction.get_on_state_line() == StateLine.StateType.None
	)
	
	var state_interactions : Array[Interaction] = get_interactions().filter(
		func(interaction: Interaction):
			return interaction.get_on_state_line() == stateline.state
	)
	
	var interaction_x_positions := non_state_interactions.map(
		func(interaction: Interaction):
			return interaction.position.x
	)
	
	stateline.position.x = get_movable_state_line_position(stateline.state, interaction_x_positions)
	
	for interaction in state_interactions:
		var interaction_position: Vector2 = interaction.position
		interaction.position.x = stateline.position.x
		
		for particle_line in interaction.connected_lines:
			particle_line.points[particle_line.get_point_at_position(interaction_position)].x = stateline.position.x
			particle_line.update_line()
		
		interaction.update_interaction()
	

func get_movable_state_line_position(state: StateLine.StateType, interaction_x_positions: Array) -> int:
	var test_position : int = snapped(get_local_mouse_position().x - DiagramArea.position.x, grid_size)
	
	match state:
		StateLine.StateType.Initial:
			test_position = min(test_position, StateLines[StateLine.StateType.Final].position.x - grid_size)
			
			if interaction_x_positions.size() != 0:
				test_position = min(test_position, interaction_x_positions.min() - grid_size)
		
		StateLine.StateType.Final:
			test_position = max(test_position, StateLines[StateLine.StateType.Initial].position.x + grid_size)
			
			if interaction_x_positions.size() != 0:
				test_position = max(test_position, interaction_x_positions.max() + grid_size)
	
	test_position = clamp(test_position, 0, DiagramArea.size.x)
	
	return test_position

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
	for interaction in super.get_interactions():
		if interaction is Interaction:
			interactions.append(interaction)
	
	return interactions

func get_particle_lines() -> Array[ParticleLine]:
	var particle_lines : Array[ParticleLine] = []
	for particle_line in super.get_particle_lines():
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
	var new_line := create_particle_line()

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
		super.place_interaction(interaction_position)
	
		check_split_lines()
		check_rejoin_lines()

func can_place_interaction(test_position: Vector2) -> bool:
	for interaction in Interactions.get_children():
		if interaction.is_queued_for_deletion():
			continue
		
		if interaction.position == test_position:
			return false

	return true

func place_line(
	start_position: Vector2, end_position: Vector2 = Vector2.ZERO,
	base_particle: GLOBALS.Particle = ParticleButtons.selected_particle
) -> void:
	var line : ParticleLine = create_particle_line()
	line.init(self)
	
	line.points[line.Point.Start] = start_position
	
	if end_position != Vector2.ZERO:
		line.points[line.Point.End] = end_position
		line.is_placed = true
		
	
	line.base_particle = base_particle
	
	ParticleLines.add_child(line)
	
	check_split_lines()
	check_rejoin_lines()

func draw_raw_diagram(connection_matrix : ConnectionMatrix) -> void:
	add_diagram_to_history()
	
	super.draw_raw_diagram(connection_matrix)

func clear_diagram() -> void:
	for interaction in Interactions.get_children():
		delete_interaction(interaction)
	for state_line in StateLines:
		state_line.clear_hadrons()

func draw_diagram_particles(drawing_matrix: DrawingMatrix) -> Array:
	var drawing_lines : Array = super.draw_diagram_particles(drawing_matrix)
	
	for drawing_line in drawing_lines:
		drawing_line.is_placed = true

	return drawing_lines

func draw_diagram(drawing_matrix: DrawingMatrix) -> void:
	line_diagram_actions = false
	
	clear_diagram()

	super.draw_diagram(drawing_matrix)

	line_diagram_actions = true

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

func is_valid() -> bool:
	return get_interactions().all(func(interaction: Interaction): return interaction.valid)

func is_fully_connected(bidirectional: bool) -> bool:
	return generate_drawing_matrix_from_diagram().is_fully_connected(bidirectional)
