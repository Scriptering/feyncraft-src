class_name ConnectionMatrix

signal interaction_added(point_id)
signal interaction_removed(point_id)

enum {INVALID}
enum Connection {from_id, to_id, particle}
enum EntryFactor {Entry = +1, Exit = -1}

const MAX_REINDEX_ATTEMPTS : int = 100

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

func remove_empty_rows() -> void:
	for id in range(matrix_size - 1, -1, -1):
		if get_connected_count(id, true) == 0:
			remove_interaction(id)

func connect_interactions(
	from_id: int, to_id: int, particle: int = GLOBALS.PARTICLE.none, bidirectional: bool = false, reverse: bool = false
) -> void:

	if reverse:
		var temp_id: int = from_id
		from_id = to_id
		to_id = temp_id
	
	check_bounds([from_id, to_id])
	
	connection_matrix[from_id][to_id].append(particle)
	
	if bidirectional:
		connection_matrix[to_id][from_id].append(particle)

func swap_ids(id1: int, id2: int) -> void:
	var temp_id2 : Array = connection_matrix[id2].duplicate(true)
	
	connection_matrix[id2] = connection_matrix[id1]
	connection_matrix[id1] = temp_id2

func insert_connection(connection: Array) -> void:
	connect_interactions(connection[Connection.from_id], connection[Connection.to_id], connection[Connection.particle])

func disconnect_interactions(
	from_id: int, to_id: int, particle: int = GLOBALS.Particle.none, bidirectional: bool = false, reverse: bool = false
) -> void:

	if reverse:
		var temp_id: int = from_id
		from_id = to_id
		to_id = temp_id
	
	check_bounds([from_id, to_id])
	
	connection_matrix[from_id][to_id].erase(particle)
	
	if bidirectional:
		connection_matrix[to_id][from_id].erase(particle)

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
	from_id: int, to_id: int, bidirectional: bool = false, particle: GLOBALS.Particle = GLOBALS.Particle.none, reverse: bool = false
) -> bool:
	
	if reverse:
		var temp_id: int = from_id
		from_id = to_id
		to_id = temp_id
	
	if particle == GLOBALS.Particle.none:
		return connection_matrix[from_id][to_id].size() != 0 or (bidirectional and connection_matrix[to_id][from_id].size() != 0)
	else:
		return particle in connection_matrix[from_id][to_id] or (bidirectional and particle in connection_matrix[to_id][from_id])

func get_connection_size(from_id: int, to_id: int, bidirectional: bool = false, reverse: bool = false) -> int:
	if reverse:
		var temp_id: int = from_id
		from_id = to_id
		to_id = temp_id
	
	return connection_matrix[from_id][to_id].size() + int(bidirectional) * connection_matrix[to_id][from_id].size()

func get_connected_count(id: int, bidirectional: bool = false, reverse: bool = false) -> int:
	var connection_count : int = 0
	
	for connection_id in get_connected_ids(id, bidirectional, GLOBALS.Particle.none, reverse):
		connection_count += get_connection_size(id, connection_id, bidirectional, reverse)
	
	return connection_count

func get_connected_ids(
	id: int, bidirectional: bool = false, particle: GLOBALS.Particle = GLOBALS.Particle.none, reverse: bool = false,
	include_directionless: bool = false
) -> PackedInt32Array:
	
	var connected_ids: PackedInt32Array = []
	
	for jd in range(matrix_size):
		if are_interactions_connected(id, jd, bidirectional, particle, reverse):
			connected_ids.push_back(jd)
			continue
		
		if include_directionless and get_connection_particles(id, jd, false, true, reverse).size() > 0:
			connected_ids.push_back(jd)
	
	return connected_ids

func get_sorted_connected_particles(
	id: int, bidirectional: bool = false, include_directionless: bool = false, reverse: bool = false
) -> Array:
	var connected_particles: Array = get_connected_particles(id, bidirectional, include_directionless, reverse)
	connected_particles.sort()
	return connected_particles

func get_connected_particles(id: int, bidirectional: bool = false, include_directionless: bool = false, reverse: bool = false) -> Array:
	var connected_particles: Array = []
	
	for jd in range(matrix_size):
		connected_particles += get_connection_particles(id, jd, bidirectional, include_directionless, reverse)
	
	return connected_particles

func get_sorted_connection_particles(from_id: int, to_id: int, bidirectional: bool = false, include_directionless: bool = false) -> Array:
	var connection_particles: Array = get_connection_particles(from_id, to_id, bidirectional, include_directionless)
	connection_particles.sort()
	return connection_particles

func get_connection_particles(
	from_id: int, to_id: int, bidirectional: bool = false, include_directionless: bool = false, reverse: bool = false
) -> Array:
	
	if reverse:
		var temp_id: int = from_id
		from_id = to_id
		to_id = temp_id
	
	var connection_particles : Array = connection_matrix[from_id][to_id]
	
	if bidirectional:
		return connection_particles + connection_matrix[to_id][from_id]
	
	if include_directionless:
		var directionless_particles : Array = connection_matrix[to_id][from_id].filter(
			func(particle): return particle not in GLOBALS.SHADED_PARTICLES
		)
		return connection_particles + directionless_particles
	
	return connection_particles

func is_fully_connected(bidirectional: bool = false) -> bool:
	var reached_ids : PackedInt32Array = []
	var start_id: int = 0
	
	return reach_ids(start_id, reached_ids, bidirectional).size() == matrix_size

func reach_ids(id: int, reached_ids: PackedInt32Array, bidirectional: bool) -> PackedInt32Array:
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

func find_all_ids(test_function: Callable) -> PackedInt32Array:
	return range(matrix_size).filter(
		func(id: int):
			return test_function.call(id)
	)

func find_all_state_ids(test_function: Callable, state: StateLine.StateType) -> PackedInt32Array:
	var valid_state_ids: PackedInt32Array = []
	
	for id in get_state_ids(state):
		if test_function.call(id):
			valid_state_ids.push_back(id)
	
	return valid_state_ids

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

func get_id_state_index(id: int) -> int:
	return id - get_starting_state_id(get_state_from_id(id))

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
			if get_connection_particles(from_id, to_id, false, true).size() > 0:
				travellable_points.push_back(to_id)
		
		travel_matrix.push_back(travellable_points)
	
	return travel_matrix

func combine_matrix(new_matrix):
	if !new_matrix is ConnectionMatrix:
		push_error("Combining matrix of different type to connection matrix")
		return
	
	if new_matrix.matrix_size > matrix_size:
		push_error("Combining matrix size larger than base matrix size")
		return
	
	for i in new_matrix.matrix_size:
		for j in new_matrix.matrix_size:
			connection_matrix[i][j] += new_matrix.connection_matrix[i][j]

func duplicate():
	var new_connection_matrix := ConnectionMatrix.new()
	new_connection_matrix.state_count = state_count.duplicate()
	new_connection_matrix.connection_matrix = connection_matrix.duplicate(true)
	new_connection_matrix.matrix_size = matrix_size
	
	return new_connection_matrix

func is_extreme_point(id: int, entry_factor: EntryFactor) -> bool:
	if get_state_from_id(id) == StateLine.StateType.None:
		return false
	
	return get_connected_count(id, false, entry_factor == EntryFactor.Exit) != 0

func get_extreme_points(entry_factor: EntryFactor) -> PackedInt32Array:
	var extreme_points: PackedInt32Array = []
	
	for state_id in get_state_ids(StateLine.StateType.Both):
		if is_extreme_point(state_id, entry_factor):
			extreme_points.push_back(state_id)
	
	return extreme_points

func get_entry_points() -> PackedInt32Array:
	return get_extreme_points(EntryFactor.Entry)

func get_exit_points() -> PackedInt32Array:
	return get_extreme_points(EntryFactor.Exit)

func get_state_interactions(state: StateLine.StateType = StateLine.StateType.Both) -> Array:
	var state_interactions: Array = []
	
	for from_state_id in get_state_ids(state):
		var state_interaction: Array = [] 
		for to_id in matrix_size:
			state_interaction += get_connection_particles(from_state_id, to_id, false, false, true).map(
				func(base_particle: GLOBALS.Particle): return -1 * StateLine.state_factor[get_state_from_id(from_state_id)] * base_particle
			)
			
			state_interaction += get_connection_particles(from_state_id, to_id).map(
				func(base_particle: GLOBALS.Particle): return StateLine.state_factor[get_state_from_id(from_state_id)] * base_particle
			)
		
		state_interactions.push_back(state_interaction)
	
	return state_interactions

func get_unique(array: Array) -> Array:
	var unique_elements: Array = []
	
	for element in array:
		if element not in unique_elements:
			unique_elements.append(element)
	
	return unique_elements

func is_duplicate(comparison_matrix: ConnectionMatrix) -> bool:
	for i in matrix_size:
		for j in matrix_size:
			if get_sorted_connection_particles(i, j, false, true) != comparison_matrix.get_sorted_connection_particles(i, j, false, true):
				return false
			
	return true

func get_further_reindex_points(reindexed_id: int, reindexed_ids: Array) -> Array:
	var non_reindexed_ids: Array = []
	for connected_id in get_connected_ids(reindexed_id, false, GLOBALS.Particle.none, false, true):
		if connected_id not in reindexed_ids and connected_id not in non_reindexed_ids:
			non_reindexed_ids.push_back(connected_id)
	
	var non_reindexed_size: int = non_reindexed_ids.size()
	
	if non_reindexed_size == 0:
		return []
	elif non_reindexed_size == 1:
		return non_reindexed_ids
	
	var further_reindex_points: Array = []
	var self_connection_sizes: Array = []
	
	for i in range(non_reindexed_size):
		var connection_count: int = 0
		
		for id in non_reindexed_ids:
			if i == id:
				pass
			
			connection_count += get_connection_size(non_reindexed_ids[i], id)
		
		self_connection_sizes.push_back(connection_count)
	
	for i in range(non_reindexed_size):
		if self_connection_sizes.count(self_connection_sizes[i]) == 1:
			further_reindex_points.push_back(non_reindexed_ids[i])
	
	if further_reindex_points.size() != 0:
		return further_reindex_points
	
	var connected_particles: Array = []
	var connected_counts: Array = []
	for i in range(non_reindexed_size):
		connected_particles.push_back(get_sorted_connected_particles(non_reindexed_ids[i]))
		connected_counts.push_back(get_connected_count(non_reindexed_ids[i]))
	
	for i in range(non_reindexed_size):
		if connected_particles.count(connected_particles[i]) == 1 or connected_counts.count(connected_counts[i]) == 1:
			further_reindex_points.push_back(non_reindexed_ids[i])
	
	if further_reindex_points.size() != 0:
		return further_reindex_points
	
	var further_points_counts: Array = []
	for non_reindexed_id in non_reindexed_ids:
		var further_further_points : Array = get_further_reindex_points(non_reindexed_id, reindexed_ids + non_reindexed_ids)
		further_points_counts.push_back(further_further_points.size())
		
		further_reindex_points += further_further_points
	
	non_reindexed_ids.sort_custom(
		func(id1: int, id2: int):
			return further_points_counts[non_reindexed_ids.find(id1)] > further_points_counts[non_reindexed_ids.find(id2)]
	)
	
	further_reindex_points = non_reindexed_ids + further_reindex_points
	
	return further_reindex_points
	

func reindex_further_paths(reindex_dictionary: Dictionary, travel_matrix: Array[PackedInt32Array]) -> Dictionary:
	var reindexed_ids : Array = reindex_dictionary.keys()
	reindexed_ids.sort()
	
	for reindexed_id in reindexed_ids:
		var further_from_reindex_points: PackedInt32Array = get_further_reindex_points(reindexed_id, reindexed_ids)
		
		for further_point in further_from_reindex_points:
			if further_point in reindex_dictionary.keys():
				continue
				
			reindex_dictionary[further_point] = reindex_dictionary.size()
			reindex_from_point(further_point, reindex_dictionary, travel_matrix)
			
			if reindex_dictionary.size() == matrix_size:
				return reindex_dictionary
	
	return reindex_dictionary

func generate_reindex_dictionary() -> Dictionary:
	var reindex_dictionary: Dictionary = {}
	var travel_matrix: Array[PackedInt32Array] = get_travel_matrix()
	var state_ids := get_state_ids(StateLine.StateType.Both)
	
	for state_id in state_ids:
		reindex_dictionary[state_id] = state_id

	for state_id in state_ids:
		reindex_from_point(state_id, reindex_dictionary, travel_matrix)
		if reindex_dictionary.size() == matrix_size:
			return reindex_dictionary
	
	for reindex_attempt in range(MAX_REINDEX_ATTEMPTS):
		reindex_dictionary = reindex_further_paths(reindex_dictionary, travel_matrix)
		if reindex_dictionary.size() == matrix_size:
			return reindex_dictionary
	
	return reindex_dictionary

func reindex() -> void:
	var reindex_dictionary : Dictionary = generate_reindex_dictionary()
	
	var reindexed_connection_matrix : Array = connection_matrix.duplicate(true)
	
	for i in matrix_size:
		if i not in reindex_dictionary.keys():
			continue
		
		for j in matrix_size:
			if j not in reindex_dictionary.keys():
				continue

			reindexed_connection_matrix[reindex_dictionary[i]][reindex_dictionary[j]] = connection_matrix[i][j]
	
	connection_matrix = reindexed_connection_matrix.duplicate(true)

func filter_points(points: PackedInt32Array, test_function: Callable) -> PackedInt32Array:
	var filtered_points: PackedInt32Array = []
	
	for point in points:
		if test_function.call(point):
			filtered_points.push_back(point)
	
	return filtered_points

func reindex_from_point(point: int, reindex_dictionary: Dictionary, travel_matrix: Array[PackedInt32Array] = get_travel_matrix()) -> void:
	var connected_ids : Array = travel_matrix[point]
	
	connected_ids = connected_ids.filter(
		func(id: int): return id not in reindex_dictionary.keys()
	)

	var connected_particles : Array = []
	for id in connected_ids:
		connected_particles.push_back(get_sorted_connection_particles(point, id, false, true).front())
	
	var unique_particle_connected_ids: Array = []
	var non_unique_particles: Array = []
	var ids_to_further_sort: Array[PackedInt32Array] = []
	for id in connected_ids:
		if connected_particles.count(get_sorted_connection_particles(point, id, false, true).front()) == 1:
			unique_particle_connected_ids.push_back(id)
			continue
	
	unique_particle_connected_ids.sort_custom(
		func(id1: int, id2: int):
			return (
				get_sorted_connection_particles(point, id1, false, true).front() <
				get_sorted_connection_particles(point, id2, false, true).front()
			)
	)
	
	for id in unique_particle_connected_ids:
		reindex_dictionary[id] = reindex_dictionary.size()
	
	for id in unique_particle_connected_ids:
		reindex_from_point(id, reindex_dictionary, travel_matrix)
	
	return

func reindex_path(path: PackedInt32Array, reindex_dict: Dictionary) -> PackedInt32Array:
	var reindexed_path : PackedInt32Array = []
	
	for point in path:
		reindexed_path.push_back(reindex_dict[point])
	
	return reindexed_path
	
func index_state_paths(reindex_dictionary: Dictionary, state_paths: Array) -> Dictionary:
	
	index_unique_paths(reindex_dictionary, state_paths)

	return reindex_dictionary

func index_state_ids(reindex_dict: Dictionary, state_paths: Array, state_id: int,
	state_count_both := get_state_count(StateLine.StateType.Both),
) -> void:
	
	reindex_dict[state_id] = state_id
	
	var first_state_connected_point : int = state_paths.front()[1]
	
	if first_state_connected_point not in reindex_dict.keys():
		reindex_dict[first_state_connected_point] = state_count_both + state_id

func index_unique_paths(reindex_dictionary: Dictionary, state_paths: Array) -> void:
	var state_path_sizes : Array = state_paths.map(func(path): return path.size())
	
	for path_id in range(state_path_sizes.size()):
		var is_path_size_unique: bool = state_path_sizes.count(state_path_sizes[path_id]) == 1
		if !is_path_size_unique:
			continue
		
		index_path(reindex_dictionary, state_paths[path_id])

func index_path(reindex_dictionary: Dictionary, path: PackedInt32Array) -> void:
	for point in path:
		if point in reindex_dictionary.keys():
			continue
		
		reindex_dictionary[point] = reindex_dictionary.size()
		
		if reindex_dictionary.size() == matrix_size:
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

