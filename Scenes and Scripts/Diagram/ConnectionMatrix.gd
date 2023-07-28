class_name ConnectionMatrix

signal interaction_added(point_id)
signal interaction_removed(point_id)

enum InteractionState {None = -1, Initial, Final, Both}
enum {INVALID}

const States : Array[InteractionState] = [InteractionState.Initial, InteractionState.Final]

var matrix : Array = []:
	set(_new_value):
		pass

var state_count: Array[int] = [0, 0]

func init(new_size : int = 0, new_state_count: Array[int] = [0, 0]) -> void:
	if new_size < new_state_count[InteractionState.Initial] + new_state_count[InteractionState.Final]:
		push_error("Matrix size initiated less than state count.")
	
	state_count = new_state_count
	
	for i in range(new_size):
		add_interaction()

func connect_interactions(
	connect_from_id: int, connect_to_id: int,
	particle: int = GLOBALS.PARTICLE.none, bidirectional: bool = false) -> void:
	
	check_bounds([connect_from_id, connect_to_id])
	
	matrix[connect_from_id][connect_to_id].append(particle)
	
	if bidirectional:
		matrix[connect_to_id][connect_from_id].append(particle)

func disconnect_interactions(
	disconnect_from_id: int, disconnect_to_id: int,
	particle: int = GLOBALS.PARTICLE.none, bidirectional: bool = false) -> void:
	
	check_bounds([disconnect_from_id, disconnect_to_id])
	
	matrix[disconnect_from_id][disconnect_to_id].disconnect(particle)
	
	if bidirectional:
		matrix[disconnect_to_id][disconnect_from_id].disconnect(particle)

func check_bounds(ids: Array[int]) -> void:
	for id in ids:
		if id >= matrix.size():
			push_error("id " + str(id) + " is out of bounds for matrix of size " + str(matrix.size()))

func create_empty_array(array_size: int) -> Array:
	var empty_array: Array = []
	
	for i in range(array_size):
		empty_array.push_back([])
	
	return empty_array

func add_interaction(interaction_state: InteractionState = InteractionState.None) -> void:
	var id: int = calculate_new_interaction_id(interaction_state)
	
	emit_signal("interaction_added", id)
	
	matrix.insert(id, create_empty_array(matrix.size()))
	
	for row in range(matrix.size()):
		matrix[row].insert(id, [])
	
	if interaction_state == InteractionState.Initial or interaction_state == InteractionState.Final:
		state_count[interaction_state] += 1

func calculate_new_interaction_id(interaction_state: InteractionState) -> int:
	match interaction_state:
		InteractionState.None:
			return matrix.size()
		InteractionState.Initial:
			return state_count[InteractionState.Initial]
		InteractionState.Final:
			return state_count[InteractionState.Initial] + state_count[InteractionState.Final]
	return INVALID

func remove_interaction(id: int) -> void:
	emit_signal("interaction_removed", id)
	
	matrix.remove_at(id)
	
	for row in range(matrix.size()):
		matrix[row].remove_at(id)

func are_interactions_connected(
	from_id: int, to_id: int,
	bidirectional: bool = false, particle: int = GLOBALS.PARTICLE.none) -> bool:
	
	if particle == GLOBALS.PARTICLE.none:
		return matrix[from_id][to_id].size() != 0 or (bidirectional and matrix[to_id][from_id].size() != 0)
	else:
		return particle in matrix[from_id][to_id] or (bidirectional and particle in matrix[to_id][from_id])

func get_connections(id: int, bidirectional: bool = false) -> Array[int]:
	var connected_ids: Array[int] = []
	
	for jd in range(matrix.size()):
		if are_interactions_connected(id, jd, bidirectional):
			connected_ids.push_back(jd)
	
	return connected_ids

func is_fully_connected(bidirectional: bool = false) -> bool:
	var reached_ids : Array[int] = []
	var start_id: int = 0
	
	return reach_ids(start_id, reached_ids, bidirectional).size() == matrix.size()

func reach_ids(id: int, reached_ids: Array[int], bidirectional: bool) -> Array[int]:
	reached_ids.push_back(id)
	
	for jd in matrix[id]:
		if jd in reached_ids:
			continue
		
		if are_interactions_connected(id, jd, bidirectional):
			reached_ids = reach_ids(jd, reached_ids, bidirectional)
		
	return reached_ids

func size() -> int:
	return matrix.size()

func get_state_interaction_count(state: InteractionState) -> int:
	if state == InteractionState.None:
		return size()
	return state_count[state]
