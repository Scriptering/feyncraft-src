class_name DrawingMatrix
extends ConnectionMatrix

var split_hadron_ids : Array = []
var grid_size : int = 1
var normalised_interaction_positions : PackedVector2Array = []

func initialise_from_connection_matrix(from_connection_matrix: ConnectionMatrix) -> void:
	connection_matrix = from_connection_matrix.connection_matrix.duplicate(true)
	state_count = from_connection_matrix.state_count.duplicate()
	matrix_size = connection_matrix.size()
	
	make_drawable()

func get_interaction_positions() -> PackedVector2Array:
	var interaction_positions := normalised_interaction_positions.duplicate()
	for i in range(interaction_positions.size()):
		interaction_positions[i] *= grid_size
	return interaction_positions

func add_interaction_position(position: Vector2, id: int = normalised_interaction_positions.size()) -> void:
	normalised_interaction_positions.insert(id, position/grid_size)

func add_interaction_with_position(
	interaction_position: Vector2, interaction_state: StateLine.StateType = StateLine.StateType.None,
	id : int = calculate_new_interaction_id(interaction_state)
) -> void:

	add_interaction(interaction_state, id)
	add_interaction_position(interaction_position, id)

func make_drawable() -> void:
	split_hadrons()
	seperate_double_connections()

func seperate_double_connections() -> void:
	for i in range(matrix_size):
		for j in range(matrix_size):
			if i == j:
				continue
			
			if !is_double_connection(i, j):
				continue
			
			var both_hadrons := (
				get_state_from_id(i) != StateLine.StateType.None and
				get_state_from_id(j) != StateLine.StateType.None
			)
			
			if both_hadrons:
				continue
			
			while is_double_connection(i, j):
				divert_connection(i, j)
	return

func divert_connection(
	divert_from_id: int, divert_to_id: int, new_id: int = calculate_new_interaction_id()
) -> void:
	
	var seperating_particle: GLOBALS.Particle = connection_matrix[divert_from_id][divert_to_id][0]
	
	disconnect_interactions(divert_from_id, divert_to_id, seperating_particle)
	add_interaction(StateLine.StateType.None, new_id)
	connect_interactions(divert_from_id, new_id, seperating_particle)
	connect_interactions(new_id, divert_to_id, seperating_particle)

func is_double_connection(from_id: int, to_id: int, bidirectional : bool = false) -> bool:
	if bidirectional:
		return get_connection_size(from_id, to_id) + get_connection_size(to_id, from_id) > 1
	
	return (
		get_connection_size(from_id, to_id) > 1 or
		get_connection_size(from_id, to_id) >= 1 and get_connection_size(to_id, from_id) >= 1
	)

func get_hadron_ids() -> PackedInt32Array:
	var hadron_ids: PackedInt32Array = []
	for state_id in get_state_count(StateLine.StateType.Both):
		if get_connected_count(state_id, true) > 1:
			hadron_ids.append(state_id)
	
	return hadron_ids

func split_hadrons() -> void:
	for i in range(get_hadron_ids().size()):
		var to_split_hadron_id : int = get_hadron_ids()[0]
		
		split_hadron(to_split_hadron_id)

func split_hadron(hadron_id: int) -> void:
	var new_interaction_id := hadron_id + 1
	split_hadron_ids.append([hadron_id])
	
	while get_connected_count(hadron_id, true) > 1:
		var connection_ids := get_connected_ids(hadron_id, true)
		var connection_id := connection_ids[randi() % connection_ids.size()]
		
		add_interaction(get_state_from_id(hadron_id), new_interaction_id)
		split_hadron_ids[-1].append(new_interaction_id)
		
		connection_id += int(connection_id > hadron_id)
		
		if are_interactions_connected(hadron_id, connection_id):
			var connecting_particle : GLOBALS.Particle = get_connection_particles(hadron_id, connection_id)[0]
			disconnect_interactions(hadron_id, connection_id, connecting_particle)
			connect_interactions(new_interaction_id, connection_id, connecting_particle)
		
		else:
			var connecting_particle : GLOBALS.Particle = get_connection_particles(connection_id, hadron_id)[0]
			disconnect_interactions(connection_id, hadron_id, connecting_particle)
			connect_interactions(connection_id, new_interaction_id, connecting_particle)
	
		new_interaction_id += 1
