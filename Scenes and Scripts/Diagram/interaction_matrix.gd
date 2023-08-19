class_name InteractionMatrix
extends ConnectionMatrix

enum {UNCONNECTED, CONNECTED}

var unconnected_matrix: Array = []

var unconnected_particle_count: PackedInt32Array = [0, 0, 0]

func add_interaction(
	interaction_state : StateLine.StateType = StateLine.StateType.None,
	id : int = calculate_new_interaction_id(interaction_state)
):
	super.add_interaction(interaction_state, id)
	
	unconnected_matrix.insert(id, [])

func add_unconnected_interaction(
	unconnected_particles: Array = [],
	interaction_state: StateLine.StateType = StateLine.StateType.None,
	id : int = calculate_new_interaction_id(interaction_state)
) -> void:
	super.add_interaction(interaction_state, id)
	
	unconnected_matrix.insert(id, unconnected_particles)
	unconnected_particle_count[interaction_state] += unconnected_particles.size()

func connect_interactions(
	connect_from_id: int, connect_to_id: int,
	particle: int = GLOBALS.PARTICLE.none, bidirectional: bool = false
) -> void:
	super.connect_interactions(connect_from_id, connect_to_id, particle, bidirectional)
	
	unconnected_matrix[connect_from_id].erase(particle)
	unconnected_particle_count[get_state_from_id(connect_from_id)] -= 1
	
	unconnected_matrix[connect_to_id].erase(particle)
	unconnected_particle_count[get_state_from_id(connect_to_id)] -= 1

func insert_connection(connection: Array) -> void:
	connect_interactions(connection[Connection.from_id], connection[Connection.to_id], connection[Connection.particle])
	
func disconnect_interactions(
	disconnect_from_id: int, disconnect_to_id: int,
	particle: int = GLOBALS.PARTICLE.none, bidirectional: bool = false
) -> void:
	super.disconnect_interactions(disconnect_from_id, disconnect_to_id, particle, bidirectional)
	
	unconnected_matrix[disconnect_from_id].append(particle)
	unconnected_particle_count[get_state_from_id(disconnect_from_id)] += 1
	
	if bidirectional:
		unconnected_matrix[disconnect_to_id].append(particle)
		unconnected_particle_count[get_state_from_id(disconnect_to_id)] += 1

func remove_connection(connection: Array) -> void:
	disconnect_interactions(connection[Connection.from_id], connection[Connection.to_id], connection[Connection.particle])

func get_unconnected_particle_count(state: StateLine.StateType) -> int:
	if state == StateLine.StateType.Both:
		return unconnected_particle_count[StateLine.StateType.Initial] + unconnected_particle_count[StateLine.StateType.Final]
	
	return unconnected_particle_count[state]

func find_unconnected_particle(particle: GLOBALS.Particle) -> PackedInt32Array:
	var found_ids: PackedInt32Array = []
	for id in range(unconnected_matrix.size()):
		if particle in unconnected_matrix[id]:
			found_ids.append(id)
	
	return found_ids

func find_all_unconnected_state_particle(particle: GLOBALS.Particle, state: StateLine.StateType) -> PackedInt32Array:
	var found_ids: PackedInt32Array = []
	for id in range(get_starting_state_id(state), get_ending_state_id(state)):
		for unconnected_particle in unconnected_matrix[id]:
			if unconnected_particle == particle:
				found_ids.append(id)
	return found_ids

func is_hadron(id: int) -> bool:
	return unconnected_matrix[id].size() > 1

func get_unconnected_particles() -> Array:
	var unconnected_particles : Array = []
	for interaction in unconnected_matrix:
		unconnected_particles += interaction
	return unconnected_particles

func get_unconnected_base_particles() -> Array:
	return get_unconnected_particles().map(func(particle): return abs(particle))

func get_unconnected_state(state: StateLine.StateType) -> Array:
	return unconnected_matrix.slice(get_starting_state_id(state), get_ending_state_id(state))

func get_extreme_points(entry_factor: EntryFactor) -> PackedInt32Array:
	var extreme_points: PackedInt32Array = []
	
	for state_id in range(get_state_count(StateLine.StateType.Both)):
		for particle in unconnected_matrix[state_id]:
			if abs(particle) not in GLOBALS.SHADED_PARTICLES:
				continue
			
			if entry_factor * state_factor[get_state_from_id(state_id)] * particle >= 0:
				extreme_points.append(state_id)
	
	return extreme_points
	
func get_entry_points() -> PackedInt32Array:
	return get_extreme_points(EntryFactor.Entry)
	

func get_exit_points() -> PackedInt32Array:
	return get_extreme_points(EntryFactor.Exit)

func find_first_unconnected(test_function: Callable) -> int:
	var found_ids: PackedInt32Array = []
	
	for id in matrix_size:
		if unconnected_matrix[id].any(func(particle): return test_function.call(particle)):
			return id
	
	return matrix_size

func find_all_unconnected(test_function: Callable) -> PackedInt32Array:
	var found_ids: PackedInt32Array = []
	
	for id in matrix_size:
		if unconnected_matrix[id].any(func(particle): return test_function.call(particle)):
			found_ids.push_back(id)
	
	return found_ids

func reduce_to_base_particles() -> void:
	unconnected_matrix = unconnected_matrix.map(
		func(interaction): return interaction.map(
			func(particle): return abs(particle)
		)
	)
	
	connection_matrix = connection_matrix.map(
		func(interaction): return interaction.map(
			func(connection): return connection.map(
				func(particle): return abs(particle)
			)
		)
	)

func get_combined_matrix(new_matrix):
	if !new_matrix is InteractionMatrix:
		push_error("Combining matrix of different type to interaction matrix")
		return
	
	if new_matrix.matrix_size > matrix_size:
		push_error("Combining matrix size larger than base matrix size")
		return
	
	for i in new_matrix.matrix_size:
		for j in new_matrix.matrix_size:
			if !new_matrix.are_interactions_connected(i, j):
				continue
			
			for particle in new_matrix.get_connected_particles(i, j):
				connect_interactions(i, j, particle)

func get_connection_matrix() -> ConnectionMatrix:
	var new_connection_matrix := ConnectionMatrix.new()
	
	new_connection_matrix.connection_matrix = connection_matrix.duplicate(true)
	new_connection_matrix.state_count = state_count.duplicate()
	new_connection_matrix.matrix_size = self.matrix_size
	
	return new_connection_matrix

func duplicate():
	var new_interaction_matrix := InteractionMatrix.new()
	new_interaction_matrix.unconnected_matrix = unconnected_matrix.duplicate(true)
	new_interaction_matrix.connection_matrix = connection_matrix.duplicate(true)
	new_interaction_matrix.state_count = state_count.duplicate()
	new_interaction_matrix.unconnected_particle_count = unconnected_particle_count.duplicate()
	new_interaction_matrix.matrix_size = self.matrix_size
	return new_interaction_matrix

func has_same_unconnected_matrix(comparison_matrix: InteractionMatrix) -> bool:
	if unconnected_matrix == comparison_matrix.unconnected_matrix:
		return true
	
	if unconnected_matrix.size() != comparison_matrix.unconnected_matrix.size():
		return false
	
	if unconnected_matrix.any(func(interaction): return interaction not in comparison_matrix.unconnected_matrix):
		return false
	
	if comparison_matrix.unconnected_matrix.any(func(interaction): return interaction not in unconnected_matrix):
		return false
	
	return true
