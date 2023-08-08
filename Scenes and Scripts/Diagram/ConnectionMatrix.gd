class_name ConnectionMatrix

signal interaction_added(point_id)
signal interaction_removed(point_id)

enum {INVALID}
enum Connection {from_id, to_id, particle}

const state_factor : Dictionary = {
	StateLine.StateType.Initial: +1,
	StateLine.StateType.Final: -1
}

const States : Array[StateLine.StateType] = [StateLine.StateType.Initial, StateLine.StateType.Final]

var connection_matrix : Array = []
var state_count: PackedInt32Array = [0, 0, 0]
var matrix_size : int = 0
var last_added_id: int

const PREVIOUS_POINT: int = -2

func init(new_size : int = 0, new_state_count: Array[int] = [0, 0, 0]) -> void:
	if new_size < new_state_count[StateLine.StateType.Initial] + new_state_count[StateLine.StateType.Final]:
		push_error("Matrix size initiated less than state count.")
	
	state_count = new_state_count
	
	for i in range(new_size):
		add_interaction()

func set_connection_matrix(new_connection_matrix: Array) -> void:
	connection_matrix = new_connection_matrix

func connect_interactions(
	connect_from_id: int, connect_to_id: int,
	particle: int = GLOBALS.PARTICLE.none, bidirectional: bool = false) -> void:
	
	check_bounds([connect_from_id, connect_to_id])
	
	connection_matrix[connect_from_id][connect_to_id].append(particle)
	
	if bidirectional:
		connection_matrix[connect_to_id][connect_from_id].append(particle)

func insert_connection(connection: Array) -> void:
	connect_interactions(connection[Connection.from_id], connection[Connection.to_id], connection[Connection.particle])

func disconnect_interactions(
	disconnect_from_id: int, disconnect_to_id: int,
	particle: int = GLOBALS.Particle.none, bidirectional: bool = false) -> void:
	
	check_bounds([disconnect_from_id, disconnect_to_id])
	
	connection_matrix[disconnect_from_id][disconnect_to_id].erase(particle)
	
	if bidirectional:
		connection_matrix[disconnect_to_id][disconnect_from_id].erase(particle)

func remove_connection(connection: Array) -> void:
	disconnect_interactions(connection[Connection.from_id], connection[Connection.to_id], connection[Connection.particle])

func check_bounds(ids: Array[int]) -> void:
	for id in ids:
		if id >= matrix_size:
			push_error("id " + str(id) + " is out of bounds for matrix of size " + str(matrix_size))

func create_empty_array(array_size: int) -> Array:
	var empty_array: Array = []
	
	for i in range(array_size):
		empty_array.push_back([])
	
	return empty_array

func add_interaction(
	interaction_state: StateLine.StateType = StateLine.StateType.None,
	id : int = calculate_new_interaction_id(interaction_state)
) -> void:

	emit_signal("interaction_added", id)
	
	connection_matrix.insert(id, create_empty_array(matrix_size))
	matrix_size += 1
	
	for row in range(matrix_size):
		connection_matrix[row].insert(id, [])
	
	last_added_id = id
	
	state_count[interaction_state] += 1

func calculate_new_interaction_id(
	interaction_state: StateLine.StateType = StateLine.StateType.None
) -> int:
	match interaction_state:
		StateLine.StateType.None:
			return matrix_size
		StateLine.StateType.Initial:
			return state_count[StateLine.StateType.Initial]
		StateLine.StateType.Final:
			return state_count[StateLine.StateType.Initial] + state_count[StateLine.StateType.Final]
	return INVALID

func remove_interaction(id: int) -> void:
	emit_signal("interaction_removed", id)
	
	connection_matrix.remove_at(id)
	
	for row in range(matrix_size):
		connection_matrix[row].remove_at(id)
	
	matrix_size -= 1

func are_interactions_connected(
	from_id: int, to_id: int,
	bidirectional: bool = false, particle: GLOBALS.Particle = GLOBALS.Particle.none) -> bool:
	
	if particle == GLOBALS.Particle.none:
		return connection_matrix[from_id][to_id].size() != 0 or (bidirectional and connection_matrix[to_id][from_id].size() != 0)
	else:
		return particle in connection_matrix[from_id][to_id] or (bidirectional and particle in connection_matrix[to_id][from_id])

func get_connection_size(from_id: int, to_id: int, bidirectional: bool = false) -> int:
	return connection_matrix[from_id][to_id].size() + int(bidirectional) * connection_matrix[to_id][from_id].size()

func get_connection_count(id: int, bidirectional: bool = false) -> int:
	var connection_count : int = 0
	
	for connection_id in get_connection_ids(id, bidirectional):
		connection_count += get_connection_size(id, connection_id, bidirectional)
	
	return connection_count

func get_connection_ids(id: int, bidirectional: bool = false) -> Array[int]:
	var connected_ids: Array[int] = []
	
	for jd in range(matrix_size):
		if are_interactions_connected(id, jd, bidirectional):
			connected_ids.push_back(jd)
	
	return connected_ids

func get_connection_particles(from_id: int, to_id: int, bidirectional: bool = false) -> Array:
	if !bidirectional:
		return connection_matrix[from_id][to_id]
	
	return connection_matrix[from_id][to_id] + connection_matrix[to_id][from_id]

func is_fully_connected(bidirectional: bool = false) -> bool:
	var reached_ids : PackedInt32Array = []
	var start_id: int = 0
	
	return reach_ids(start_id, reached_ids, bidirectional).size() == matrix_size

func reach_ids(
	id: int, reached_ids: PackedInt32Array, bidirectional: bool
) -> PackedInt32Array:
	reached_ids.push_back(id)
	
	for jd in matrix_size:
		if jd in reached_ids:
			continue
		
		if are_interactions_connected(id, jd, bidirectional):
			reached_ids = reach_ids(jd, reached_ids, bidirectional)
		
	return reached_ids

func get_starting_state_id(state: StateLine.StateType) -> int:
	match state:
		StateLine.StateType.None:
			return state_count[StateLine.StateType.Initial] + state_count[StateLine.StateType.Final]
		StateLine.StateType.Initial:
			return 0
		StateLine.StateType.Final:
			return state_count[StateLine.StateType.Initial]
		StateLine.StateType.Both:
			return 0
	
	return INVALID

func get_ending_state_id(state: StateLine.StateType) -> int:
	return get_starting_state_id(state) + get_state_count(state)

func get_state_from_id(id: int) -> StateLine.StateType:
	if id >= matrix_size:
		push_error("id is greater than matrix size")
	
	if id < state_count[StateLine.StateType.Initial]:
		return StateLine.StateType.Initial
	elif id < state_count[StateLine.StateType.Initial] + state_count[StateLine.StateType.Final]:
		return StateLine.StateType.Final
	
	return StateLine.StateType.None

func get_state_count(state: StateLine.StateType) -> int:
	if state == StateLine.StateType.Both:
		return state_count[StateLine.StateType.Initial] + state_count[StateLine.StateType.Final]
	
	return state_count[state]

func get_states(state: StateLine.StateType) -> Array:
	return connection_matrix.slice(get_starting_state_id(state), get_ending_state_id(state))

func get_state_ids(state: StateLine.StateType) -> PackedInt32Array:
	return range(get_starting_state_id(state), get_ending_state_id(state))

func get_travel_matrix() -> Array[PackedInt32Array]:
	var travel_matrix: Array[PackedInt32Array] = []
	
	for from_id in range(matrix_size):
		var travellable_points: PackedInt32Array = []
		for to_id in range(matrix_size):
			if get_connection_particles(from_id, to_id, true).any(func(particle): return particle in GLOBALS.BOSONS):
				travellable_points.push_back(to_id)

			elif are_interactions_connected(from_id, to_id):
				travellable_points.push_back(to_id)
		
		travel_matrix.push_back(travellable_points)
	
	return travel_matrix

func duplicate():
	var new_connection_matrix := ConnectionMatrix.new()
	new_connection_matrix.state_count = state_count.duplicate()
	new_connection_matrix.connection_matrix = connection_matrix.duplicate(true)
	new_connection_matrix.matrix_size = matrix_size
	
	return new_connection_matrix

func has_same_particles(comparison_matrix: ConnectionMatrix) -> bool:
	for state in [StateLine.StateType.Initial, StateLine.StateType.Final, StateLine.StateType.None]:
		
		var state_particles : Array = get_state_particles(StateLine.StateType.None)
		state_particles.sort()
		
		var comparison_state_particles : Array = comparison_matrix.get_state_particles(StateLine.StateType.None)
		comparison_state_particles.sort()
		
		if comparison_state_particles != state_particles:
			return false
	
	return true

func is_duplicate(comparison_matrix: ConnectionMatrix) -> bool:
	if comparison_matrix.matrix_size != matrix_size:
		return false
	
	if comparison_matrix.state_count != state_count:
		return false
	
	if !has_same_particles(comparison_matrix):
		return false
	
	if !has_same_connection_paths(comparison_matrix):
		return false
	
	return true

func get_state_particles(state: StateLine.StateType) -> Array:
	var state_particles: Array = []
	
	for from_state_id in get_state_ids(state):
		for to_id in matrix_size:
			state_particles += get_connection_particles(from_state_id, to_id, true)
	
	return state_particles

func has_same_connection_paths(comparison_matrix: ConnectionMatrix) -> bool:
	var paths_matrix: Array = []
	var comparison_paths_matrix: Array = []
	
	var state_ids := get_state_ids(StateLine.StateType.Both)
	
	for state_id in state_ids:
		var state_paths := generate_paths_from_point(state_id)
		var comparison_state_paths := comparison_matrix.generate_paths_from_point(state_id)
		
		var state_path_sizes : Array = state_paths.map(func(path): return path.size())
		var comparison_state_path_sizes : Array = comparison_state_paths.map(func(path): return path.size())
		
		state_path_sizes.sort()
		comparison_state_path_sizes.sort()
		
		if state_path_sizes != comparison_state_path_sizes:
			return false
			
		paths_matrix.push_back(state_paths)
		comparison_paths_matrix.push_back(state_paths)

	var reindex_dictionary := generate_reindex_dictionary(paths_matrix)
	
	var reindexed_paths_matrix := paths_matrix.map(
		func(state_paths): return state_paths.map(
			func(path): return reindex_path(path, reindex_dictionary)
		)
	)
	
	var comparison_reindexed_paths_matrix := paths_matrix.map(
		func(state_paths): return state_paths.map(
			func(path): return reindex_path(path, reindex_dictionary)
		)
	)
	
	if !compare_paths_matrices(reindexed_paths_matrix, comparison_reindexed_paths_matrix):
		return false
	
	return true

func compare_paths_matrices(paths_matrix: Array, comparison_paths_matrix: Array) -> bool:
	var flattened_paths : Array[PackedInt32Array] = []
	var comparison_flattened_paths : Array[PackedInt32Array] = []
	
	for state_id in range(paths_matrix.size()):
		for path_id in range(paths_matrix[state_id].size()):
			flattened_paths.push_back(paths_matrix[state_id][path_id])
			comparison_flattened_paths.push_back(comparison_paths_matrix[state_id][path_id])
	
	return flattened_paths.all(func(path): return path in comparison_flattened_paths)

func reindex_path(path: PackedInt32Array, reindex_dict: Dictionary) -> PackedInt32Array:
	var reindexed_path : PackedInt32Array = []
	
	for point in path:
		reindexed_path.push_back(reindex_dict[point])
	
	return reindexed_path
	
func generate_reindex_dictionary(paths_matrix: Array, state_ids: PackedInt32Array = get_state_ids(StateLine.StateType.Both)) -> Dictionary:
	var reindex_dict: Dictionary = {}
	var state_count_both := get_state_count(StateLine.StateType.Both)
	
	for state_id in state_ids:
		reindex_state_ids(reindex_dict, paths_matrix[state_id], state_id, state_count_both)
		if reindex_dict.size() == matrix_size:
			return reindex_dict
	
	for state_id in state_ids:
		reindex_unique_state_paths(reindex_dict, paths_matrix[state_id], state_id)
		if reindex_dict.size() == matrix_size:
			return reindex_dict

	return reindex_dict

func reindex_state_ids(reindex_dict: Dictionary, state_paths: Array, state_id: int,
	state_count_both := get_state_count(StateLine.StateType.Both),
) -> void:
	
	reindex_dict[state_id] = state_id
	
	var first_state_connected_point : int = state_paths.front()[1]
	
	if first_state_connected_point not in reindex_dict.keys():
		reindex_dict[first_state_connected_point] = state_count_both + state_id

func reindex_unique_state_paths(reindex_dict: Dictionary, state_paths: Array, state_id: int) -> void:
	var state_path_sizes : Array = state_paths.map(func(path): return path.size())
	
	for path_id in range(state_path_sizes.size()):
		var is_path_size_unique: bool = state_path_sizes.count(state_path_sizes[path_id]) == 1
		if !is_path_size_unique:
			continue
		
		for point in state_paths[path_id]:
			if point in reindex_dict.keys():
				continue
			
			reindex_dict[point] = reindex_dict.size()
			
			if reindex_dict.size() == matrix_size:
				return

func generate_paths_from_point(
	current_point: int, path_to_current_point: PackedInt32Array = [],
	travel_matrix: Array[PackedInt32Array] = get_travel_matrix()
) -> Array[PackedInt32Array]:
	
	var base_path_from_point : PackedInt32Array = [current_point]
	
	var path_is_finished : bool = true
	for point in travel_matrix[current_point]:
		if point not in path_to_current_point:
			path_is_finished = false
			break
	
	var path_is_loop : bool = current_point in path_to_current_point
		
	if path_is_finished or path_is_loop:
		return [base_path_from_point]
		
	path_to_current_point.push_back(current_point)
	
	var paths_from_current_point : Array[PackedInt32Array] = []
	
	for point in travel_matrix[current_point]:
		var point_is_previous := path_to_current_point.size() > 1 and point == path_to_current_point[PREVIOUS_POINT]
		if point_is_previous:
			continue
		
		for path_from_point in generate_paths_from_point(point, path_to_current_point.duplicate(), travel_matrix):
			paths_from_current_point.push_back(base_path_from_point + path_from_point)
	
	return paths_from_current_point

