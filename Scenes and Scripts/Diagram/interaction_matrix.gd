class_name InteractionMatrix
extends ConnectionMatrix

enum {UNCONNECTED, CONNECTED}

@export var unconnected_matrix: Array = []
@export var unconnected_particle_count: PackedInt32Array = [0, 0, 0]

func add_interaction(
	interaction_state : StateLine.State = StateLine.State.None,
	id : int = calculate_new_interaction_id(interaction_state)
) -> void:
	super.add_interaction(interaction_state, id)
	
	unconnected_matrix.insert(id, [])

func add_unconnected_interaction(
	unconnected_particles: Array = [],
	interaction_state: StateLine.State = StateLine.State.None,
	id : int = calculate_new_interaction_id(interaction_state)
) -> void:
	super.add_interaction(interaction_state, id)
	
	unconnected_matrix.insert(id, unconnected_particles)
	unconnected_particle_count[interaction_state] += unconnected_particles.size()

func connect_interactions(
	from_id: int, to_id: int, particle: int = ParticleData.Particle.none, bidirectional: bool = false, reverse: bool = false
) -> void:
	super.connect_interactions(from_id, to_id, particle, bidirectional, reverse)
	
	if particle in unconnected_matrix[from_id]:
		unconnected_matrix[from_id].erase(particle)
		unconnected_particle_count[get_state_from_id(from_id)] -= 1
	
	if particle in unconnected_matrix[to_id]:
		unconnected_matrix[to_id].erase(particle)
		unconnected_particle_count[get_state_from_id(to_id)] -= 1

func connect_asymmetric_interactions(
	from_id: int, to_id: int, from_particle: ParticleData.Particle, to_particle: ParticleData.Particle,
	connection_particle: ParticleData.Particle, reverse: bool = false
) -> void:
	super.connect_interactions(from_id, to_id, connection_particle, false, reverse)
	
	unconnected_matrix[from_id].erase(from_particle)
	unconnected_particle_count[get_state_from_id(from_id)] -= 1
	
	unconnected_matrix[to_id].erase(to_particle)
	unconnected_particle_count[get_state_from_id(to_id)] -= 1

func insert_connection(connection: Array) -> void:
	connect_interactions(connection[Connection.from_id], connection[Connection.to_id], connection[Connection.particle])
	
func disconnect_interactions(
	from_id: int, to_id: int, particle: int = ParticleData.PARTICLE.none, bidirectional: bool = false, reverse: bool = false
) -> void:
	super.disconnect_interactions(from_id, to_id, particle, bidirectional, reverse)

	unconnected_matrix[from_id].append(particle)
	unconnected_particle_count[get_state_from_id(from_id)] += 1

	if bidirectional:
		unconnected_matrix[to_id].append(particle)
		unconnected_particle_count[get_state_from_id(to_id)] += 1

func remove_connection(connection: Array) -> void:
	disconnect_interactions(connection[Connection.from_id], connection[Connection.to_id], connection[Connection.particle])

func get_unconnected_particle_count() -> int:
	var particle_count: int = 0
	
	for unconnected_count:int in unconnected_particle_count:
		particle_count += unconnected_count
	
	return particle_count

func get_unconnected_state_particle_count(state: StateLine.State) -> int:
	if state == StateLine.State.Both:
		return unconnected_particle_count[StateLine.State.Initial] + unconnected_particle_count[StateLine.State.Final]

	return unconnected_particle_count[state]

func find_unconnected_particle(particle: ParticleData.Particle) -> PackedInt32Array:
	var found_ids: PackedInt32Array = []
	for id:int in range(unconnected_matrix.size()):
		if particle in unconnected_matrix[id]:
			found_ids.append(id)

	return found_ids

func find_all_unconnected_state_particle(particle: ParticleData.Particle, state: StateLine.State) -> PackedInt32Array:
	var found_ids: PackedInt32Array = []
	for id:int in range(get_starting_state_id(state), get_ending_state_id(state)):
		for unconnected_particle:ParticleData.Particle in unconnected_matrix[id]:
			if unconnected_particle == particle:
				found_ids.append(id)
	return found_ids

func is_hadron(id: int) -> bool:
	return unconnected_matrix[id].size() > 1

func get_unconnected_particles() -> Array:
	var unconnected_particles : Array = []
	for interaction:Array in unconnected_matrix:
		unconnected_particles += interaction
	return unconnected_particles

func get_unconnected_base_particles() -> Array:
	return get_unconnected_particles().map(
		func(particle:ParticleData.Particle) -> ParticleData.Particle:
			return abs(particle) as ParticleData.Particle
	)

func get_unconnected_state(state: StateLine.State) -> Array:
	return unconnected_matrix.slice(get_starting_state_id(state), get_ending_state_id(state))

func is_extreme_particle(particle: ParticleData.Particle, entry_factor: EntryFactor, state_id: int) -> bool:
	if abs(particle) not in ParticleData.SHADED_PARTICLES:
		return false

	return entry_factor * state_factor[get_state_from_id(state_id)] * particle >= 0
	
func get_extreme_points(entry_factor: EntryFactor) -> PackedInt32Array:
	var extreme_points: PackedInt32Array = []

	for state_id:int in get_state_ids(StateLine.State.Both):
		if unconnected_matrix[state_id].any(
			func(particle: ParticleData.Particle) -> bool:
				return is_extreme_particle(particle, entry_factor, state_id)
		):
			extreme_points.push_back(state_id)
			continue

	return extreme_points

func get_extreme_states(entry_factor: EntryFactor) -> Array:
	var extreme_states := []
	
	for state_id:int in get_state_ids(StateLine.State.Both):
		extreme_states.push_back(unconnected_matrix[state_id].filter(
			func(particle: ParticleData.Particle) -> bool:
				return is_extreme_particle(particle, entry_factor, state_id)
		))
	
	return extreme_states

func get_entry_states() -> Array:
	return get_extreme_states(EntryFactor.Entry)

func get_exit_states() -> Array:
	return get_extreme_states(EntryFactor.Exit)

func get_entry_points() -> PackedInt32Array:
	return get_extreme_points(EntryFactor.Entry)

func get_exit_points() -> PackedInt32Array:
	return get_extreme_points(EntryFactor.Exit)

func find_unconnected_id() -> int:
	for id:int in matrix_size:
		if unconnected_matrix[id].size() > 0 :
			return id
	
	return matrix_size

func find_unconnected_ids() -> PackedInt32Array:
	var unconnected_ids: PackedInt32Array = []
	
	for id:int in matrix_size:
		if unconnected_matrix[id].size() > 0 :
			unconnected_ids.push_back(id)
	
	return unconnected_ids

func find_first_unconnected(test_function: Callable) -> int:
	for id:int in matrix_size:
		if unconnected_matrix[id].any(
			func(particle:ParticleData.Particle) -> bool:
				return test_function.call(particle)
		):
			return id

	return matrix_size

func find_all_unconnected(test_function: Callable) -> PackedInt32Array:
	var found_ids: PackedInt32Array = []

	for id:int in matrix_size:
		if unconnected_matrix[id].any(
			func(particle:ParticleData.Particle) -> bool:
				return test_function.call(particle)
		):
			found_ids.push_back(id)

	return found_ids

func clear_connection_matrix() -> void:
	for i:int in matrix_size:
		for j:int in matrix_size:
			connection_matrix[i][j].clear()

func reduce_to_base_particles() -> void:
	unconnected_matrix = unconnected_matrix.map(
		func(interaction:Array) -> Array:
			return interaction.map(
				func(particle:ParticleData.Particle) -> ParticleData.Particle:
					return abs(particle)
	))

	connection_matrix = connection_matrix.map(
		func(interaction:Array) -> Array:
			return interaction.map(
				func(connection:Array) -> Array:
					return connection.map(
						func(particle:ParticleData.Particle) -> ParticleData.Particle:
							return abs(particle)
			)
	))

func get_combined_matrix(new_matrix:Variant) -> void:
	if !new_matrix is InteractionMatrix:
		push_error("Combining matrix of different type to interaction matrix")
		return
	
	if new_matrix.matrix_size > matrix_size:
		push_error("Combining matrix size larger than base matrix size")
		return
	
	for i:int in new_matrix.matrix_size:
		for j:int in new_matrix.matrix_size:
			if !new_matrix.are_interactions_connected(i, j):
				continue
			
			for particle:ParticleData.Particle in new_matrix.get_connected_particles(i, j):
				connect_interactions(i, j, particle)

func get_connection_matrix() -> ConnectionMatrix:
	var new_connection_matrix := ConnectionMatrix.new()
	
	new_connection_matrix.connection_matrix = connection_matrix.duplicate(true)
	new_connection_matrix.state_count = state_count.duplicate()
	new_connection_matrix.matrix_size = self.matrix_size
	
	return new_connection_matrix

func has_same_unconnected_matrix(comparison_matrix: InteractionMatrix) -> bool:
	if unconnected_matrix == comparison_matrix.unconnected_matrix:
		return true
	
	if unconnected_matrix.size() != comparison_matrix.unconnected_matrix.size():
		return false
	
	if unconnected_matrix.any(
		func(interaction:Array) -> bool:
			return interaction not in comparison_matrix.unconnected_matrix
	):
		return false
	
	if comparison_matrix.unconnected_matrix.any(
		func(interaction:Array) -> bool:
			return interaction not in unconnected_matrix
	):
		return false
	
	return true

func has_same_connection_matrix(comparison_matrix: InteractionMatrix) -> bool:
	if connection_matrix == comparison_matrix.connection_matrix:
		return true
	
	if connection_matrix.size() != comparison_matrix.connection_matrix.size():
		return false
	
	if connection_matrix.any(
		func(interaction:Array) -> bool:
			return interaction not in comparison_matrix.connection_matrix
	):
		return false
	
	if comparison_matrix.connection_matrix.any(
		func(interaction:Array) -> bool:
			return interaction not in connection_matrix
	):
		return false
	
	return true

func is_duplicate_interaction_matrix(compare_interaction_matrix: InteractionMatrix) -> bool:
	if !has_same_unconnected_matrix(compare_interaction_matrix):
		return false
	
	if !has_same_connection_matrix(compare_interaction_matrix):
		return false
	
	return true
	
	
