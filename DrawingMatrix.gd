class_name DrawingMatrix
extends ConnectionMatrix

@export var split_hadron_ids : Array = []
@export var normalised_interaction_positions : Array[Vector2] = []
@export var state_line_positions : Array[int] = [0, 20]

func initialise_from_connection_matrix(from_connection_matrix: ConnectionMatrix) -> void:
	connection_matrix = from_connection_matrix.connection_matrix.duplicate(true)
	state_count = from_connection_matrix.state_count.duplicate()
	matrix_size = connection_matrix.size()
	
	make_drawable()

func get_interaction_positions(grid_size: int = 1) -> PackedVector2Array:
	if grid_size == 1:
		return normalised_interaction_positions
	
	var interaction_positions: PackedVector2Array = normalised_interaction_positions.duplicate()
	
	for i in range(interaction_positions.size()):
		interaction_positions[i] *= grid_size
	
	return interaction_positions

func add_interaction_position(position: Vector2, grid_size: int, id: int = normalised_interaction_positions.size()) -> void:
	normalised_interaction_positions.insert(id, position/grid_size)

func add_interaction_with_position(
	interaction_position: Vector2, grid_size: int, interaction_state: StateLine.StateType = StateLine.StateType.None,
	id : int = calculate_new_interaction_id(interaction_state)
) -> void:

	add_interaction(interaction_state, id)
	add_interaction_position(interaction_position, grid_size, id)

func make_drawable() -> void:
	split_hadrons()
	seperate_double_connections()
	reorder_hadrons()

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
	
	var seperating_particle: ParticleData.Particle = connection_matrix[divert_from_id][divert_to_id][0]
	
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

func reach_ids(id: int, reached_ids: PackedInt32Array, bidirectional: bool) -> PackedInt32Array:
	reached_ids.push_back(id)
	
	for jd in matrix_size:
		if jd in reached_ids:
			continue
		
		if are_interactions_connected(id, jd, bidirectional) or are_ids_in_same_hadron(id, jd):
			reached_ids = reach_ids(jd, reached_ids, bidirectional)
		
	return reached_ids

func are_ids_in_same_hadron(id: int, jd: int) -> bool:
	return split_hadron_ids.any(
		func(hadron: PackedInt32Array) -> bool:
			return id in hadron and jd in hadron
	)

func are_interactions_connected(
	from_id: int, to_id: int, bidirectional: bool = false, particle: ParticleData.Particle = ParticleData.Particle.none, reverse: bool = false
) -> bool:
	if reverse:
		var temp_id: int = from_id
		from_id = to_id
		to_id = temp_id
	
	if particle == ParticleData.Particle.none:
		return connection_matrix[from_id][to_id].size() != 0 or (bidirectional and connection_matrix[to_id][from_id].size() != 0)
	else:
		return particle in connection_matrix[from_id][to_id] or (bidirectional and particle in connection_matrix[to_id][from_id])

func split_hadron(hadron_id: int) -> void:
	var new_interaction_id := hadron_id + 1
	split_hadron_ids.append([hadron_id])
	
	while get_connected_count(hadron_id, true) > 1:
		var connection_ids := get_connected_ids(hadron_id, true)
		var connection_id := connection_ids[0]
		
		add_interaction(get_state_from_id(hadron_id), new_interaction_id)
		split_hadron_ids[-1].append(new_interaction_id)
		
		connection_id += int(connection_id > hadron_id)
		
		if are_interactions_connected(hadron_id, connection_id):
			var connecting_particle : ParticleData.Particle = get_connection_particles(hadron_id, connection_id)[0]
			disconnect_interactions(hadron_id, connection_id, connecting_particle)
			connect_interactions(new_interaction_id, connection_id, connecting_particle)
		
		else:
			var connecting_particle : ParticleData.Particle = get_connection_particles(connection_id, hadron_id)[0]
			disconnect_interactions(connection_id, hadron_id, connecting_particle)
			connect_interactions(connection_id, new_interaction_id, connecting_particle)
	
		new_interaction_id += 1

func get_directly_connected_ids() -> PackedInt32Array:
	var directly_connected_ids: PackedInt32Array = []
	
	for from_id in get_state_ids(StateLine.StateType.Both):
		for to_id in get_connected_ids(from_id):
			if get_state_from_id(to_id) == StateLine.StateType.None:
				continue
			
			directly_connected_ids.push_back(from_id)
	
	return directly_connected_ids

func get_id_hadron_index(id: int) -> int:
	for hadron_ids in split_hadron_ids:
		if id not in hadron_ids:
			continue
		
		return hadron_ids.find(id)
	
	return -1

func reorder_hadrons() -> void:
	var directly_connected_ids: PackedInt32Array = get_directly_connected_ids()
	
	for id in get_state_ids(StateLine.StateType.Both):
		if get_connected_count(id, true) > 1:
			breakpoint
	
	for i in range(directly_connected_ids.size()):
		var from_id: int = directly_connected_ids[i]
		var to_id: int = get_connected_ids(from_id)[0]
		
		var from_hadron_index: int = get_id_hadron_index(from_id)
		var to_hadron_index: int = get_id_hadron_index(to_id)
		
		var swap_id: int
		if from_hadron_index == to_hadron_index:
			continue
		elif from_hadron_index < to_hadron_index:
			swap_id = from_id
		else:
			swap_id = to_id
		
		swap_ids(swap_id, swap_id + abs(from_hadron_index - to_hadron_index))
	
	for id in get_state_ids(StateLine.StateType.Both):
		if get_connected_count(id, true) > 1:
			breakpoint

func add_interaction(
	interaction_state: StateLine.StateType = StateLine.StateType.None,
	id : int = calculate_new_interaction_id(interaction_state)
) -> void:
	super.add_interaction(interaction_state, id)
	
	for i in range(split_hadron_ids.size()):
		for j in range(split_hadron_ids[i].size()):
			split_hadron_ids[i][j] += int(split_hadron_ids[i][j] >= id)

func remove_interaction(id: int) -> void:
	super.remove_interaction(id)
	
	for i in range(split_hadron_ids.size()):
		for j in range(split_hadron_ids[i].size()):
			split_hadron_ids[i][j] -= int(split_hadron_ids[i][j] >= id)

func remove_empty_rows() -> void:
	for id in range(matrix_size - 1, -1, -1):
		if get_connected_count(id, true) == 0:
			remove_interaction(id)

func rejoin_double_connections() -> void:
	for id in get_state_ids(StateLine.StateType.None):
		if !(get_connected_count(id) == 1 and get_connected_count(id, false, true) == 1):
			continue
		
		var from_id: int = get_connected_ids(id, false, ParticleData.Particle.none, true)[0]
		var to_id: int = get_connected_ids(id)[0]
		
		if get_connection_particles(from_id, to_id) != get_connection_particles(id, to_id):
			continue
			
		var connection_particle: ParticleData.Particle = get_connection_particles(from_id, to_id).front()
		
		disconnect_interactions(from_id, id, connection_particle)
		disconnect_interactions(id, to_id, connection_particle)
		
		connect_interactions(from_id, to_id, connection_particle)
	
	remove_empty_rows()

func rejoin_hadrons() -> void:
	for i in split_hadron_ids.size():
		rejoin_hadron(split_hadron_ids[i])
	
	split_hadron_ids.clear()
	remove_empty_rows()

func rejoin_hadron(hadron_ids: PackedInt32Array) -> void:
	var to_id := hadron_ids[0]
	var from_ids := hadron_ids.slice(1)
	
	from_ids.sort()
	from_ids.reverse()
	
	for hadron_id in from_ids:
		var connected_id: int = get_connected_ids(hadron_id, true)[0]
		var reverse: bool = !are_interactions_connected(hadron_id, connected_id)
		
		var connection_particle: ParticleData.Particle = get_connection_particles(
			hadron_id, connected_id, true
		).front()
		
		disconnect_interactions(hadron_id, connected_id, connection_particle, false, reverse)
		connect_interactions(to_id, connected_id, connection_particle, false, reverse)

func reduce_to_connection_matrix() -> ConnectionMatrix:
	var reduced_drawing_matrix : DrawingMatrix = duplicate(true)
	
	reduced_drawing_matrix.rejoin_hadrons()
	reduced_drawing_matrix.rejoin_double_connections()
	
	return reduced_drawing_matrix.get_connection_matrix()

func get_connection_matrix() -> ConnectionMatrix:
	var new_connection_matrix := ConnectionMatrix.new()
	
	new_connection_matrix.connection_matrix = connection_matrix.duplicate(true)
	new_connection_matrix.state_count = state_count.duplicate()
	new_connection_matrix.matrix_size = self.matrix_size
	
	return new_connection_matrix

func get_reduced_matrix(particle_test_function: Callable):
	var reduced_matrix: DrawingMatrix = duplicate(true)
	
	for id in range(matrix_size):
		for connection in get_connections(id) + get_connections(id, true):
			if particle_test_function.call(connection[Connection.particle]):
				continue
			
			reduced_matrix.remove_connection(connection)
	
	return reduced_matrix

func get_extreme_baryons(entry_factor: EntryFactor) -> Array:
	return get_baryons().filter(
		func(baryon: Array): return baryon.front() in get_extreme_points(entry_factor)
	)

func get_entry_baryons() -> Array:
	return get_extreme_baryons(EntryFactor.Entry)

func get_exit_baryons() -> Array:
	return get_extreme_baryons(EntryFactor.Exit)

func get_baryons() -> Array:
	return split_hadron_ids.filter(
		func(hadron_ids: Array): return hadron_ids.size() == 3
	)

func get_mesons() -> Array:
	return split_hadron_ids.filter(
		func(hadron_ids: Array): return hadron_ids.size() == 2
	)

func is_lonely_extreme_point(id: int, entry_factor: EntryFactor = EntryFactor.Both) -> bool:
	if get_state_from_id(id) != StateLine.StateType.None or get_connected_ids(id, true).size() != 1:
		return false
	
	if entry_factor == EntryFactor.Both:
		return true
	
	return get_connected_count(id, false, entry_factor == EntryFactor.Exit) != 0

func get_lonely_extreme_points(entry_factor: EntryFactor) -> PackedInt32Array:
	var lonely_extreme_points: PackedInt32Array = []
	
	for id in get_state_ids(StateLine.StateType.None):
		if is_lonely_extreme_point(id, entry_factor):
			lonely_extreme_points.push_back(id)
	
	return lonely_extreme_points

func get_lonely_entry_points() -> PackedInt32Array:
	return get_lonely_extreme_points(EntryFactor.Entry)

func get_lonely_exit_points() -> PackedInt32Array:
	return get_lonely_extreme_points(EntryFactor.Exit)

