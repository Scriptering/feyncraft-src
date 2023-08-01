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
	particle: int = GLOBALS.PARTICLE.none, bidirectional: bool = false) -> void:
	
	check_bounds([disconnect_from_id, disconnect_to_id])
	
	connection_matrix[disconnect_from_id][disconnect_to_id].erase(particle)
	
	if bidirectional:
		connection_matrix[disconnect_to_id][disconnect_from_id].erase(particle)

func remove_connection(connection: Array) -> void:
	disconnect_interactions(connection[Connection.from_id], connection[Connection.to_id], connection[Connection.particle])

func check_bounds(ids: Array[int]) -> void:
	for id in ids:
		if id >= size():
			push_error("id " + str(id) + " is out of bounds for matrix of size " + str(size()))

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
	
	connection_matrix.insert(id, create_empty_array(size()))
	
	for row in range(size()):
		connection_matrix[row].insert(id, [])
	
	state_count[interaction_state] += 1

func calculate_new_interaction_id(interaction_state: StateLine.StateType) -> int:
	match interaction_state:
		StateLine.StateType.None:
			return size()
		StateLine.StateType.Initial:
			return state_count[StateLine.StateType.Initial]
		StateLine.StateType.Final:
			return state_count[StateLine.StateType.Initial] + state_count[StateLine.StateType.Final]
	return INVALID

func remove_interaction(id: int) -> void:
	emit_signal("interaction_removed", id)
	
	connection_matrix.remove_at(id)
	
	for row in range(size()):
		connection_matrix[row].remove_at(id)

func are_interactions_connected(
	from_id: int, to_id: int,
	bidirectional: bool = false, particle: GLOBALS.Particle = GLOBALS.Particle.none) -> bool:
	
	if particle == GLOBALS.Particle.none:
		return connection_matrix[from_id][to_id].size() != 0 or (bidirectional and connection_matrix[to_id][from_id].size() != 0)
	else:
		return particle in connection_matrix[from_id][to_id] or (bidirectional and particle in connection_matrix[to_id][from_id])

func get_connections(id: int, bidirectional: bool = false) -> Array[int]:
	var connected_ids: Array[int] = []
	
	for jd in range(size()):
		if are_interactions_connected(id, jd, bidirectional):
			connected_ids.push_back(jd)
	
	return connected_ids

func is_fully_connected(bidirectional: bool = false) -> bool:
	var reached_ids : Array[int] = []
	var start_id: int = 0
	
	return reach_ids(start_id, reached_ids, bidirectional).size() == size()

func reach_ids(id: int, reached_ids: Array[int], bidirectional: bool) -> Array[int]:
	reached_ids.push_back(id)
	
	for jd in connection_matrix[id].size():
		if jd in reached_ids:
			continue
		
		if are_interactions_connected(id, jd, bidirectional):
			reached_ids = reach_ids(jd, reached_ids, bidirectional)
		
	return reached_ids

func size() -> int:
	return connection_matrix.size()

func get_starting_state_id(state: StateLine.StateType) -> int:
	match state:
		StateLine.StateType.Initial:
			return 0
		StateLine.StateType.Final:
			return state_count[StateLine.StateType.Initial]
		StateLine.StateType.Both:
			return 0
		StateLine.StateType.None:
			return get_state_count(StateLine.StateType.Both)
	
	return INVALID

func get_ending_state_id(state: StateLine.StateType) -> int:
	return get_starting_state_id(state) + get_state_count(state)

func get_state_from_id(id: int) -> StateLine.StateType:
	if id >= size():
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

func seperate_double_connections() -> void:
	for i in range(size()):
		for j in range(size()):
			if i == j:
				continue
			
			var both_hadrons := (
				get_state_from_id(i) != StateLine.StateType.None and
				get_state_from_id(j) != StateLine.StateType.None
			)
			
			if both_hadrons:
				continue
			
			while is_double_connection(i, j):
				divert_connection(i, j)

func divert_connection(
	divert_from_id: int, divert_to_id: int, new_id: int = calculate_new_interaction_id(get_state_from_id(divert_from_id))
) -> void:
	
	var seperating_particle: GLOBALS.Particle = connection_matrix[divert_from_id][divert_to_id][0]
	
	disconnect_interactions(divert_from_id, divert_to_id, seperating_particle)
	add_interaction(get_state_from_id(divert_from_id), new_id)
	connect_interactions(divert_from_id, size(), seperating_particle)

func is_double_connection(from_id: int, to_id: int, bidirectional : bool = false) -> bool:
	if bidirectional:
		return connection_matrix[from_id][to_id].size() + connection_matrix[from_id][to_id].size() > 1
	
	return (
		(connection_matrix[from_id][to_id].size() != 0 and connection_matrix[from_id][to_id].size() != 0) or
		connection_matrix[from_id][to_id].size() > 1
	)

func split_hadrons() -> void:
	pass

func get_states(state: StateLine.StateType) -> Array:
	return connection_matrix.slice(get_starting_state_id(state), get_ending_state_id(state))

func get_state_ids(state: StateLine.StateType) -> PackedInt32Array:
	return range(get_starting_state_id(state), get_ending_state_id(state))

func duplicate():
	var new_connection_matrix := ConnectionMatrix.new()
	new_connection_matrix.init(size(), state_count)
	new_connection_matrix.connection_matrix = connection_matrix.duplicate(true)
	
	return new_connection_matrix
	
	
