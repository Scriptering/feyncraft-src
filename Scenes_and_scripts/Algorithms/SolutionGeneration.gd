extends Node

const INTERACTION_SIZE : int = 3

enum Find {All, LowestOrder, One}

var start_time : float
var print_times := false

var find_one: bool = false
var found_one: bool = false
var found_matrix: ConnectionMatrix
var g_degree: int
var g_particle_interactions: Dictionary = {}

var find: Find = Find.All

func generate_diagrams(
	initial_state: Array,
	final_state: Array,
	min_degree: int,
	max_degree: int,
	useable_particles: PackedInt32Array,
	p_find: Find = Find.All
) -> Array[ConnectionMatrix]:
	
	find = p_find
	find_one = find == Find.One
	found_one = false
	
	start_time = Time.get_ticks_usec()
	var print_results : bool = false
	
	if print_results:
		print(initial_state)
		print(final_state)
	
	if !are_quantum_numbers_valid(initial_state, final_state):
		print('Initial state quantum numbers do not match final state')
		return [null]
	
	g_particle_interactions = get_useable_particle_interactions(useable_particles)
	var base_interaction_matrix := create_base_interaction_matrix(initial_state, final_state)
	var shared_hadron_quarks := get_shared_elements(get_hadron_particles(initial_state), get_hadron_particles(final_state))
	var hadrons: PackedInt32Array = base_interaction_matrix.find_all_ids(
		func(id: int) -> bool:
			return base_interaction_matrix.unconnected_matrix[id].size() > 1
	)
	var hadron_connections := get_hadron_connections(base_interaction_matrix, hadrons)

	var degrees_to_check := get_degrees_to_check(
		min_degree, max_degree, base_interaction_matrix
	)

	var generated_connection_matrices : Array[ConnectionMatrix] = []
	
	for degree:int in degrees_to_check:
		if find == Find.LowestOrder and !generated_connection_matrices.is_empty():
			break
		
		g_degree = degree
		
		var hadron_connected_matrices := connect_hadrons(
			base_interaction_matrix,
			shared_hadron_quarks.size(),
			hadron_connections,
			degree
		)
		
		if found_one:
			return [found_matrix]
		
		var state_fermion_connected_matrices : Array[InteractionMatrix] = []
		for matrix:InteractionMatrix in hadron_connected_matrices:
			state_fermion_connected_matrices.append_array(connect_state_fermions(matrix))
		hadron_connected_matrices.clear()
		
		if found_one:
			return [found_matrix]
		
		var connected_matrices: Array[InteractionMatrix] = []
		for matrix:InteractionMatrix in state_fermion_connected_matrices:
			if is_complete(matrix):
				connected_matrices.push_back(matrix)
				continue
			elif is_disconnected(matrix):
				continue
			
			connected_matrices.append_array(connect_matrix(matrix))
		
		if found_one:
			return [found_matrix]
		
		generated_connection_matrices.append_array(
			get_connection_matrices(connected_matrices).filter(
				func(matrix:ConnectionMatrix) -> bool:
					return !is_matrix_colourless(matrix)
					)
		)
		
		if find == Find.LowestOrder and !generated_connection_matrices.is_empty():
			return generated_connection_matrices
		
	
	return generated_connection_matrices

func is_matrix_complete(matrix: InteractionMatrix) -> bool:
	return (
		!matrix.has_unconnected_particles()
		and matrix.is_fully_connected(true)
		and !is_matrix_colourless(matrix)
	)

func connect_hadrons(
	base_matrix: InteractionMatrix,
	max_connections: int,
	possible_connections: Array[PackedInt32Array],
	degree: int
) -> Array[InteractionMatrix]:
	
	if possible_connections.is_empty():
		return [base_matrix]
	
	var unconnected_particle_count: int = base_matrix.get_unconnected_particle_count()
	
	var min_connections : int = max(
		0, ceil((unconnected_particle_count - INTERACTION_SIZE*degree)/2)
	)
	
	var unique_start_indices: PackedInt32Array = []
	var seen_connections: Array[PackedInt32Array] = []
	for i:int in possible_connections.size():
		var connection: PackedInt32Array = possible_connections[i]
		if connection in seen_connections:
			continue
		unique_start_indices.push_back(i)
		seen_connections.push_back(connection)

	var connected_matrices: Array[InteractionMatrix] = []
	for connection_count: int in range(min_connections, max_connections + 1):
		if connection_count == 0:
			connected_matrices.push_back(base_matrix)
			continue
			
		var count: int = 0
		for index:int in unique_start_indices:
			if index > possible_connections.size() - connection_count:
				break

			connected_matrices += add_next_hadron_connection(
				base_matrix,
				possible_connections,
				index,
				connection_count,
				count,
				unique_start_indices.slice(unique_start_indices.find(index) + 1)
			)
	
	return connected_matrices

func add_next_hadron_connection(
	base_matrix: InteractionMatrix,
	connections: Array[PackedInt32Array],
	current_index: int,
	required_connection_count: int,
	current_connection_count: int,
	unique_start_indices: PackedInt32Array
) -> Array[InteractionMatrix]:
	var connected_matrix: InteractionMatrix = base_matrix.duplicate(true)
	
	var connection: Array = connections[current_index]
	
	connected_matrix.insert_connection(connection)
	
	if (
		connected_matrix.unconnected_matrix[connection[0]].is_empty()
		and connected_matrix.unconnected_matrix[connection[1]].is_empty()
		and (
			is_disconnected_hadron(connected_matrix, connection[0])
			or is_disconnected_hadron(connected_matrix, connection[1])
		)
	):
		return []
	
	if found_one:
		return []
	
	current_connection_count += 1
	if current_connection_count == required_connection_count:
		if find_one:
			connect_state_fermions(connected_matrix.duplicate(true)	)
		
		return [connected_matrix]
	
	var next_connected_matrices: Array[InteractionMatrix] = []
	
	if unique_start_indices.is_empty() or current_index + 1 != unique_start_indices[0]:
		next_connected_matrices += add_next_hadron_connection(
			connected_matrix,
			connections,
			current_index + 1,
			required_connection_count,
			current_connection_count,
			unique_start_indices
		)
	
	for next_index: int in unique_start_indices:
		if next_index > (connections.size() - (required_connection_count - current_connection_count)):
			break
		
		next_connected_matrices += add_next_hadron_connection(
			connected_matrix,
			connections,
			next_index,
			required_connection_count,
			current_connection_count,
			unique_start_indices.slice(unique_start_indices.find(next_index) + 1)
		)
	
	return next_connected_matrices

func has_disconnected_hadron(matrix: InteractionMatrix) -> bool:
	for state_id: int in matrix.get_state_ids(StateLine.State.Both):
		if !matrix.unconnected_matrix[state_id].is_empty():
			continue
		
		var reachable_ids: PackedInt32Array = matrix.reach_ids(state_id, [], true)
		
		if reachable_ids.size() == matrix.matrix_size:
			return false
		
		if ArrayFuncs.packed_int_any(
			reachable_ids, 
			func(id: int) -> bool:
				return !matrix.unconnected_matrix[id].is_empty()
		):
			return false
		
		return true

	return false

func is_disconnected_hadron(matrix: InteractionMatrix, state_id: int = -1) -> bool:
	var reachable_ids: PackedInt32Array = matrix.reach_ids(state_id, [], true)
	
	if reachable_ids.size() == matrix.matrix_size:
		return false
	
	if ArrayFuncs.packed_int_any(
		reachable_ids, 
		func(id: int) -> bool:
			return !matrix.unconnected_matrix[id].is_empty()
	):
		return false
	
	return true

func is_matrix_colourless(matrix: ConnectionMatrix) -> bool:
	var has_gluon: bool = !matrix.find_first_id(
		func(id: int) -> bool:
			return ParticleData.Particle.gluon in matrix.get_connected_particles(id)
	) == matrix.matrix_size
	
	if !has_gluon:
		return false
	
	var vision_matrix : DrawingMatrix = Vision.generate_colour_matrix(DrawingMatrix.new(matrix))
	var zip: Array = Vision.generate_colour_paths(vision_matrix, true)
	return Vision.find_colourless_interactions(zip.front(), zip.back(), vision_matrix, true).size() > 0

func generate_hadron_connected_matrices(
	base_interaction_matrix: InteractionMatrix, possible_hadron_connections: Array, possible_hadron_connection_count: Array
) -> Array[InteractionMatrix]:
	
	var hadron_connected_matrices: Array[InteractionMatrix] = []
	
	for connection_count:int in possible_hadron_connection_count:
		var hadron_connection_permutations : Array = get_permutations(possible_hadron_connections, connection_count)
		
		for hadron_connection_permutation:Array in hadron_connection_permutations:
			var interaction_matrix : InteractionMatrix = base_interaction_matrix.duplicate(true)
			
			for hadron_connection:Array in hadron_connection_permutation:
				interaction_matrix.insert_connection(hadron_connection)
			
			hadron_connected_matrices.push_back(interaction_matrix)
	
	return hadron_connected_matrices

func connect_state_fermions(base_matrix: InteractionMatrix) -> Array[InteractionMatrix]:
	var in_out_matrix: InteractionMatrix = convert_interaction_matrix_to_in_out(base_matrix)
	
	var fermion_entry_states : Array = base_matrix.get_entry_states().map(
		func(state: Array) -> Array:
			return state.filter(ParticleData.is_fermion).map(ParticleData.base)
	)
	
	var connected_interaction_matrices: Array[InteractionMatrix] = [in_out_matrix]

	for id:int in fermion_entry_states.size():
		for fermion:ParticleData.Particle in fermion_entry_states[id]:
			var fermion_connected_matrices: Array[InteractionMatrix] = []
			
			for interaction_matrix:InteractionMatrix in connected_interaction_matrices:
				fermion_connected_matrices.append_array(
					connect_fermion_from_id(
						fermion,
						id,
						interaction_matrix
					)
				)
			
			connected_interaction_matrices.assign(fermion_connected_matrices)

	return connected_interaction_matrices

func connect_matrix(base_matrix: InteractionMatrix) -> Array[InteractionMatrix]:
	
	var connected_matrices: Array[InteractionMatrix] = []
	
	var to_connect_matrices: Array[InteractionMatrix] = [base_matrix]
	for from_id:int in base_matrix.matrix_size:
		var further_matrices: Array[InteractionMatrix] = []
		for matrix:InteractionMatrix in to_connect_matrices:
			if (
				matrix.unconnected_matrix[from_id].is_empty()
				or get_next_particle(matrix.unconnected_matrix[from_id]) == ParticleData.Particle.none
			):
				further_matrices.push_back(matrix)
				continue

			further_matrices.append_array(connect_matrix_from_id(matrix, from_id))
		
		to_connect_matrices.clear()
		for matrix:InteractionMatrix in further_matrices:
			if is_complete(matrix):
				connected_matrices.push_back(matrix)
			else:
				to_connect_matrices.push_back(matrix)
		
		if to_connect_matrices.is_empty():
			break
				
	return connected_matrices

func convert_interaction_matrix_to_in_out(interaction_matrix: InteractionMatrix) -> InteractionMatrix:
	var converted_matrix: InteractionMatrix = interaction_matrix.duplicate(true)
	
	for id:int in converted_matrix.matrix_size:
		converted_matrix.unconnected_matrix[id] = converted_matrix.unconnected_matrix[id].map(
			func(particle:ParticleData.Particle) -> ParticleData.Particle:
				if particle in ParticleData.UNSHADED_PARTICLES:
					return particle
				
				return StateLine.state_factor[interaction_matrix.get_state_from_id(id)] * particle
		)
	
	return converted_matrix

func connect_particle_from_id(
	particle: ParticleData.Particle,
	from_id: int,
	base_matrix: InteractionMatrix
) -> Array[InteractionMatrix]:
	if found_one:
		return []

	var unconnected_particles: PackedInt32Array = base_matrix.get_unconnected_particles()
	unconnected_particles.remove_at(unconnected_particles.find(particle))
	
	var connected_matrices : Array[InteractionMatrix] = []

	for interaction:PackedInt32Array in g_particle_interactions[particle]:
		var interaction_connected_matrices := get_interaction_connected_matrices(
			interaction,
			base_matrix,
			particle,
			from_id,
			unconnected_particles,
		)
		
		for matrix:InteractionMatrix in interaction_connected_matrices:
			connected_matrices.append_array(
				connect_matrix_from_id(matrix, base_matrix.matrix_size)
			)
	
	return connected_matrices

func get_interaction_connected_matrices(
	interaction:PackedInt32Array,
	base_matrix:InteractionMatrix,
	from_particle:ParticleData.Particle,
	from_id:int,
	unconnected_particles:PackedInt32Array,
) -> Array[InteractionMatrix]:
	var interaction_degree: int = 1 if interaction.size() == 2 else 2
	var interaction_count: int = g_degree - base_matrix.degree
	
	if interaction_degree > interaction_count:
		return []
	
	var interaction_connected_matrices: Array[InteractionMatrix] = []
	
	var can_leave_all := is_connection_number_possible(
		unconnected_particles.size() + interaction.size(), interaction_count - interaction_degree
	)

	if can_leave_all:
		interaction_connected_matrices.push_back(
			add_interaction(interaction, base_matrix, from_particle, from_id, interaction_degree)
		)

	if !ArrayFuncs.packed_int_any(
		interaction,
		func(particle: ParticleData.Particle) -> bool:
			return has_connection_particle(unconnected_particles, particle)
	):
		return interaction_connected_matrices
	
	var new_id: int = base_matrix.matrix_size
	
	if interaction_degree == 1:
		interaction_connected_matrices.append_array(
			connect_3interaction(
				interaction,
				base_matrix,
				unconnected_particles,
				interaction_count - interaction_degree,
				from_particle,
				from_id,
				interaction_degree
			)
		)
	else:
		interaction_connected_matrices.append_array(
			connect_4interaction(
				interaction,
				base_matrix,
				unconnected_particles,
				interaction_count - interaction_degree,
				from_particle,
				from_id,
				interaction_degree
			)
		)
		
	return interaction_connected_matrices

func is_disconnected(matrix: InteractionMatrix) -> bool:
	return (
		matrix.degree > 0
		and matrix.get_unconnected_state_particle_count(StateLine.State.None) == 0
		and matrix.get_unconnected_state_particle_count(StateLine.State.Both) != 0
	)

func is_complete(matrix: InteractionMatrix) -> bool:
	return matrix.get_unconnected_particle_count() == 0

func connect_matrix_from_id(
	base_matrix: InteractionMatrix,
	from_id: int
) -> Array[InteractionMatrix]:
	if found_one:
		return []
	
	if is_disconnected(base_matrix):
		return []
	
	if is_complete(base_matrix):
		if find_one:
			var connection_matrix := base_matrix.get_connection_matrix()
			if !is_matrix_colourless(connection_matrix):
				found_one = true
				found_matrix = connection_matrix
				return []
		
		return [base_matrix]

	var connected_matrices: Array[InteractionMatrix] = []
	var to_connect_matrices: Array[InteractionMatrix] = [base_matrix]
	for i:int in base_matrix.unconnected_matrix[from_id].size():
		var further_matrices: Array[InteractionMatrix] = []
		
		for matrix:InteractionMatrix in to_connect_matrices:
			var next_particle := get_next_particle(matrix.unconnected_matrix[from_id])
			
			if next_particle == ParticleData.Particle.none:
				connected_matrices.push_back(matrix)
				continue
			
			further_matrices.append_array(
				connect_particle_from_id(next_particle, from_id, matrix	)
			)
		
		to_connect_matrices.clear()
		for matrix:InteractionMatrix in further_matrices:
			if matrix.unconnected_matrix[from_id].is_empty():
				connected_matrices.push_back(matrix)
			else:
				to_connect_matrices.push_back(matrix)
		
		if to_connect_matrices.is_empty():
			break
		
	return connected_matrices

func add_interaction(
	interaction: PackedInt32Array,
	base_matrix: InteractionMatrix,
	particle: ParticleData.Particle,
	from_id: int,
	degree: int
) -> InteractionMatrix:
	var particle_connected_matrix := base_matrix.duplicate(true)
	particle_connected_matrix.add_unconnected_interaction(
		interaction,
		StateLine.State.None,
		base_matrix.matrix_size,
		degree
	)
	particle_connected_matrix.connect_interactions_no_remove(
		from_id, base_matrix.matrix_size, particle, true, false
	)
	return particle_connected_matrix

func connect_1_particle(
	particle:ParticleData.Particle,
	interaction:PackedInt32Array,
	base_matrix:InteractionMatrix,
	unconnected_particles:PackedInt32Array,
	interaction_count:int,
	from_particle:ParticleData.Particle,
	from_id:int,
	degree:int
) -> Array[InteractionMatrix]:
	var unconnected_particle_count: int = unconnected_particles.size()
	
	var can_connect := is_connection_number_possible(
		unconnected_particle_count - 1, interaction_count
	) and has_connection_particle(unconnected_particles, particle)
	
	if !can_connect:
		return []

	var new_id: int = base_matrix.matrix_size
	var particle_connected_matrix := add_interaction(interaction, base_matrix, from_particle, from_id, degree)
	
	return connect_particle_to_ids(particle, new_id, particle_connected_matrix)

func connect_3interaction(
	interaction:PackedInt32Array,
	base_matrix:InteractionMatrix,
	unconnected_particles:PackedInt32Array,
	interaction_count:int,
	particle:ParticleData.Particle,
	from_id:int,
	degree:int
) -> Array[InteractionMatrix]:
	var unconnected_particle_count: int = unconnected_particles.size()
	
	var particleA: ParticleData.Particle = interaction[0] as ParticleData.Particle
	var particleB: ParticleData.Particle = interaction[1] as ParticleData.Particle
	var is_same_particle: bool = particleA == particleB
	
	var can_connect_A := is_connection_number_possible(
		unconnected_particle_count, interaction_count
	) and has_connection_particle(unconnected_particles, particleA)
	
	var can_connect_B := (
		!is_same_particle
		and is_connection_number_possible(
			unconnected_particle_count, interaction_count
		)
		and has_connection_particle(unconnected_particles, particleB)
	)
	
	var can_connect_both := is_connection_number_possible(
			unconnected_particle_count - 2, interaction_count
	) and has_connection_particles(unconnected_particles, interaction)

	if !can_connect_A and !can_connect_B and !can_connect_both:
		return []
	
	var new_id: int = base_matrix.matrix_size
	var particle_connected_matrix := add_interaction(interaction, base_matrix, particle, from_id, degree)
	
	var connected_matrices: Array[InteractionMatrix] = []
	if can_connect_A:
		connected_matrices.append_array(
			connect_particle_to_ids(particleA, new_id, particle_connected_matrix)
		)
		
	if can_connect_B:
		connected_matrices.append_array(
			connect_particle_to_ids(particleB, new_id, particle_connected_matrix)
		)
	
	if can_connect_both:
		connected_matrices.append_array(
			connect_2_particles_to_ids(particleA, particleB, new_id, particle_connected_matrix)
		)
	
	return connected_matrices

func connect_4interaction(
	interaction:PackedInt32Array,
	base_matrix:InteractionMatrix,
	unconnected_particles:PackedInt32Array,
	interaction_count:int,
	particle:ParticleData.Particle,
	from_id:int,
	degree:int
) -> Array[InteractionMatrix]:
	var unconnected_particle_count: int = unconnected_particles.size()
	
	var particleA: ParticleData.Particle = interaction[0] as ParticleData.Particle
	var particleB: ParticleData.Particle = interaction[1] as ParticleData.Particle
	var particleC: ParticleData.Particle = interaction[2] as ParticleData.Particle
	
	var is_AB_same_particle: bool = particleA == particleB
	var is_BC_same_particle: bool = particleB == particleC
	var is_AC_same_particle: bool = particleA == particleC
	
	var can_connect_A := (
		is_connection_number_possible(unconnected_particle_count + 1, interaction_count)
		and has_connection_particle(unconnected_particles, particleA)
	)
	
	var can_connect_B := (
		!is_AB_same_particle
		and is_connection_number_possible(unconnected_particle_count + 1, interaction_count)
		and has_connection_particle(unconnected_particles, particleB)
	)
	
	var can_connect_C := (
		!is_AC_same_particle
		and !is_BC_same_particle
		and is_connection_number_possible(unconnected_particle_count + 1, interaction_count)
		and has_connection_particle(unconnected_particles, particleB)
	)
	
	var can_connect_AB := (
		is_connection_number_possible(unconnected_particle_count - 1, interaction_count)
		and has_connection_particles(unconnected_particles, [particleA, particleB])
	)

	var can_connect_BC := (
		!(is_AB_same_particle and is_AC_same_particle)
		and is_connection_number_possible(unconnected_particle_count - 1, interaction_count)
		and has_connection_particles(unconnected_particles, [particleB, particleC])
	)
	
	var can_connect_AC := (
		!(is_AB_same_particle and is_AC_same_particle)
		and is_connection_number_possible(unconnected_particle_count - 1, interaction_count)
		and has_connection_particles(unconnected_particles, [particleA, particleC])
	)
	
	var can_connect_ABC := (
		is_connection_number_possible(unconnected_particle_count - 3, interaction_count)
		and has_connection_particles(unconnected_particles, interaction)
	)

	if !(
		can_connect_A
		or can_connect_B
		or can_connect_C
		or can_connect_AB
		or can_connect_BC
		or can_connect_AC
		or can_connect_ABC
	):
		return []
	
	var new_id: int = base_matrix.matrix_size
	var particle_connected_matrix := add_interaction(interaction, base_matrix, particle, from_id, degree)
	
	var connected_matrices: Array[InteractionMatrix] = []
	if can_connect_A:
		connected_matrices.append_array(
			connect_particle_to_ids(particleA, new_id, particle_connected_matrix)
		)
	
	if can_connect_B:
		connected_matrices.append_array(
			connect_particle_to_ids(particleB, new_id, particle_connected_matrix)
		)
	
	if can_connect_C:
		connected_matrices.append_array(
			connect_particle_to_ids(particleC, new_id, particle_connected_matrix)
		)
		
	if can_connect_AB:
		connected_matrices.append_array(
			connect_2_particles_to_ids(particleA, particleB, new_id, particle_connected_matrix)
		)

	if can_connect_BC:
		connected_matrices.append_array(
			connect_2_particles_to_ids(particleB, particleC, new_id, particle_connected_matrix)
		)
	
	if can_connect_AC:
		connected_matrices.append_array(
			connect_2_particles_to_ids(particleA, particleC, new_id, particle_connected_matrix)
		)
	
	if can_connect_ABC :
		connected_matrices.append_array(
			connect_3_particles_to_ids(particleA, particleB, particleC, new_id, particle_connected_matrix)
		)
	
	return connected_matrices

func get_next_particle(interaction: PackedInt32Array) -> ParticleData.Particle:
	for particle: ParticleData.Particle in interaction:
		if particle < 0:
			continue
		if ParticleData.is_fermion(particle):
			return particle
	
	for particle: ParticleData.Particle in interaction:
		if particle < 0:
			continue
		if ParticleData.is_particle(particle, ParticleData.Particle.W):
			return particle
	
	for particle: ParticleData.Particle in interaction:
		if !ParticleData.has_shade(particle):
			return particle
	
	return ParticleData.Particle.none

func connect_fermion_from_id(
	fermion: ParticleData.Particle,
	from_id: int,
	base_matrix: InteractionMatrix
) -> Array[InteractionMatrix]:
	
	if found_one:
		return []

	if is_disconnected(base_matrix):
		return []
	
	var interaction_count: int = g_degree - base_matrix.degree
	if interaction_count == 0:
		if !find_one:
			return [base_matrix]
		
		if is_complete(base_matrix):
			var connection_matrix := base_matrix.get_connection_matrix()
			if !is_matrix_colourless(connection_matrix):
				found_one = true
				found_matrix = connection_matrix
			return []
		else:
			connect_matrix(base_matrix)

	var unconnected_particles: PackedInt32Array = base_matrix.get_unconnected_particles()
	
	if unconnected_particles.find(fermion) == unconnected_particles.size():
		breakpoint
	
	unconnected_particles.remove_at(unconnected_particles.find(fermion))
	
	var connected_matrices: Array[InteractionMatrix] = []
	for interaction:PackedInt32Array in g_particle_interactions[fermion]:
		var interaction_connected_matrices := get_interaction_connected_matrices(
			interaction,
			base_matrix,
			fermion,
			from_id,
			unconnected_particles
		)
		
		var new_id: int = base_matrix.matrix_size
		for matrix:InteractionMatrix in interaction_connected_matrices:
			var next_particle: ParticleData.Particle = get_next_particle(
				matrix.unconnected_matrix[new_id]
			)
			
			if (
				next_particle == ParticleData.Particle.none
				or !ParticleData.is_fermion(next_particle)
			):
				connected_matrices.push_back(matrix)
				continue
			
			connected_matrices.append_array(
				connect_fermion_from_id(
					next_particle,
					new_id,
					matrix
				)
			)
	
	return connected_matrices

func connect_particle_to_ids(
	particle: ParticleData.Particle,
	from_id: int,
	base_matrix: InteractionMatrix,
	to_ids: PackedInt32Array = range(base_matrix.matrix_size),
	start_particle_index: int = 0
) -> Array[InteractionMatrix]:
	var connected_matrices: Array[InteractionMatrix] = []
	
	for to_id:int in to_ids:
		if to_id == from_id:
			continue

		var connected_particles: PackedInt32Array = []
		
		for to_particle_index:int in range(
			start_particle_index, base_matrix.unconnected_matrix[to_id].size()
		):
			var to_particle: ParticleData.Particle = (
				base_matrix.unconnected_matrix[to_id][to_particle_index]
			)
			
			if to_particle in connected_particles:
				continue
				
			if !is_connection_particle(particle, to_particle):
				continue
			
			var connected_matrix := connect_particle_to_id(
				particle, to_particle, from_id, to_id, base_matrix
			)
			connected_matrices.push_back(connected_matrix)
			connected_particles.push_back(to_particle)
		
		if to_id == to_ids[0]:
			start_particle_index = 0
	
	return connected_matrices

func connect_particle_to_id(
	from_particle: ParticleData.Particle,
	to_particle: ParticleData.Particle,
	from_id: int,
	to_id: int,
	base_matrix: InteractionMatrix
) -> InteractionMatrix:

	var connected_matrix: InteractionMatrix = base_matrix.duplicate(true)
	connected_matrix.connect_asymmetric_interactions(
		from_id,
		to_id,
		from_particle,
		to_particle,
		abs(to_particle),
		from_particle < 0
	)
	return connected_matrix

func connect_2_particles_to_ids(
	particleA: ParticleData.Particle,
	particleB: ParticleData.Particle,
	from_id: int,
	base_matrix: InteractionMatrix,
	to_ids: PackedInt32Array = range(base_matrix.matrix_size),
	start_particle_index: int = 0
) -> Array[InteractionMatrix]:
	
	var connected_matrices: Array[InteractionMatrix] = []
	
	if particleA != particleB:
		for particle_A_connected_matrix:InteractionMatrix in connect_particle_to_ids(
				particleA, from_id, base_matrix, to_ids
		):
			connected_matrices.append_array(
				connect_particle_to_ids(
					particleB, from_id, particle_A_connected_matrix, to_ids
				)
			)
		
		return connected_matrices
	
	var particle: ParticleData.Particle = particleA
	
	for to_idA:int in to_ids:
		if to_idA == from_id:
			continue

		var connected_particlesA: PackedInt32Array = []
		for to_particle_indexA:int in range(
			start_particle_index, base_matrix.unconnected_matrix[to_idA].size()
		):
			var to_particleA: ParticleData.Particle = (
				base_matrix.unconnected_matrix[to_idA][to_particle_indexA]
			)

			if to_particleA in connected_particlesA:
				continue
			
			if !is_connection_particle(particle, to_particleA):
				continue
			
			var particleA_connected_matrix := connect_particle_to_id(
				particle, to_particleA, from_id, to_idA, base_matrix
			)
			
			connected_particlesA.push_back(to_particleA)
			
			connected_matrices.append_array(
				connect_particle_to_ids(
					particle,
					from_id,
					particleA_connected_matrix,
					to_ids.slice(to_ids.find(to_idA)),
					to_particle_indexA + 1
				)
			)
		
		if to_idA == to_ids[0]:
			start_particle_index = 0
	
	return connected_matrices

func connect_3_particles_to_ids(
	particleA: ParticleData.Particle,
	particleB: ParticleData.Particle,
	particleC: ParticleData.Particle,
	from_id: int,
	base_matrix: InteractionMatrix,
	to_ids: PackedInt32Array = range(base_matrix.matrix_size)
) -> Array[InteractionMatrix]:
	
	var connected_matrices: Array[InteractionMatrix] = []
	
	if !(particleA == particleB or particleB == particleC):
		for particleA_connected_matrix:InteractionMatrix in connect_particle_to_ids(
				particleA, from_id, base_matrix, to_ids
		):
			for particle_AB_connected_matrix:InteractionMatrix in connect_particle_to_ids(
				particleB, from_id, particleA_connected_matrix, to_ids
			):
				connected_matrices.append_array(
					connect_particle_to_ids(
						particleC, from_id, particleA_connected_matrix, to_ids
					)
				)
		
		return connected_matrices
	
	elif (particleA != particleB):
		for particleA_connected_matrix in connect_particle_to_ids(
			particleA, from_id, base_matrix
		):
			connected_matrices.append_array(
				connect_2_particles_to_ids(
					particleB, particleC, from_id, particleA_connected_matrix
				)
			)
		
		return connected_matrices
	
	elif (particleB != particleC):
		for particleC_connected_matrix in connect_particle_to_ids(
			particleC, from_id, base_matrix
		):
			connected_matrices.append_array(
				connect_2_particles_to_ids(
					particleA, particleB, from_id, particleC_connected_matrix
				)
			)
		
		return connected_matrices
	
	
	var particle: ParticleData.Particle = particleA
	for to_idA:int in to_ids:
		if to_idA == from_id:
			continue

		var connected_particlesA: PackedInt32Array = []
		for to_particle_indexA:int in base_matrix.unconnected_matrix[to_idA].size():
			var to_particleA: ParticleData.Particle = (
				base_matrix.unconnected_matrix[to_idA][to_particle_indexA]
			)

			if to_particleA in connected_particlesA:
				continue
			
			if !is_connection_particle(particle, to_particleA):
				continue
			
			var particleA_connected_matrix := connect_particle_to_id(
				particle, to_particleA, from_id, to_idA, base_matrix
			)
			
			connected_particlesA.push_back(to_particleA)

			connected_matrices.append_array(
				connect_2_particles_to_ids(
					particleB,
					particleC,
					from_id,
					particleA_connected_matrix,
					to_ids.slice(to_ids.find(to_idA)),
					to_particle_indexA + 1
				)
			)
	
	return connected_matrices

func has_connection_particle(
	to_particles: PackedInt32Array,
	from_particle: ParticleData.Particle
) -> bool:
	return ArrayFuncs.packed_int_any(
		to_particles,
		func(particle: ParticleData.Particle) -> bool:
			return is_connection_particle(from_particle, particle)
	)

func has_connection_particles(
	to_particles: PackedInt32Array,
	from_particles: PackedInt32Array
) -> bool:
	var has_particles: Array[bool]
	has_particles.resize(from_particles.size())
	has_particles.fill(false)
	
	for particle: ParticleData.Particle in to_particles:
		for i:int in from_particles.size():
			if !has_particles[i] and is_connection_particle(particle, from_particles[i]):
				has_particles[i] = true
				break
		
		if has_particles.all(func(b:bool)->bool:return  b):
			return true
	
	return false

func is_connection_particle(
	from_particle: ParticleData.Particle,
	to_particle: ParticleData.Particle
) -> bool:
	if !ParticleData.has_shade(from_particle):
		return from_particle == to_particle
	
	if from_particle == -to_particle:
		return true
	
	return (
		ParticleData.is_general(from_particle) 
		and abs(to_particle) in ParticleData.GENERAL_CONVERSION[abs(from_particle)]
	)

func get_useable_particle_interactions(useable_particles: Array) -> Dictionary:
	var useable_particle_interactions: Dictionary = {}
	
	for particle:ParticleData.Particle in useable_particles:
		if ParticleData.is_anti(particle) or particle in useable_particle_interactions.keys():
			continue
		
		useable_particle_interactions[particle] = ParticleData.PARTICLE_INTERACTIONS[particle].filter(
			func(interaction:Array) -> bool:
				return interaction.all(
					func(p_particle: ParticleData.Particle) -> bool:
						return ParticleData.base(p_particle) in useable_particles
				)
		)
	
	return useable_particle_interactions

func get_useable_particles_from_interactions(interactions: Array) -> Array[ParticleData.Particle]:
	var useable_particles: Array[ParticleData.Particle] = []
	
	for interaction:Array in interactions:
		for particle:ParticleData.Particle in interaction:
			if ParticleData.base(particle) in useable_particles:
				continue
			
			useable_particles.push_back(ParticleData.base(particle))
	
	return useable_particles

func create_base_interaction_matrix(initial_state: Array, final_state: Array) -> InteractionMatrix:
	var base_interaction_matrix := InteractionMatrix.new()
	for state_interaction:Array in initial_state:
		base_interaction_matrix.add_unconnected_interaction(state_interaction, StateLine.State.Initial)
	for state_interaction:Array in final_state:
		base_interaction_matrix.add_unconnected_interaction(state_interaction, StateLine.State.Final)
	return base_interaction_matrix

func get_hadron_particles(state_interactions: Array) -> Array:
	var hadron_particles : Array = []
	
	for state_interaction:Array in state_interactions:
		var is_hadron: bool = state_interaction.size() > 1
		if !is_hadron:
			continue
		hadron_particles += state_interaction
	
	return hadron_particles

func get_degrees_to_check(
	min_degree: int,
	max_degree: int,
	interaction_matrix: InteractionMatrix
) -> Array:
	var degrees_to_check: Array = []
	var initial_hadron_particles := get_hadron_particles(interaction_matrix.get_unconnected_state(StateLine.State.Initial))
	var final_hadron_particles := get_hadron_particles(interaction_matrix.get_unconnected_state(StateLine.State.Final))
	var number_of_state_particles := interaction_matrix.get_unconnected_state_particle_count(StateLine.State.Both)

	var number_of_unconnectable_particles: int = (
		number_of_state_particles - initial_hadron_particles.size() - final_hadron_particles.size() +
		get_non_shared_elements(initial_hadron_particles, final_hadron_particles).size()
	)

	min_degree = max(ceil(number_of_unconnectable_particles/3.0), min_degree)
	
	for degree in range(min_degree, max_degree+1):
		if (number_of_state_particles - degree) % 2 == 0:
			degrees_to_check.append(degree)

	return degrees_to_check

func convert_interaction_to_general(interaction: Array) -> Array:
	return interaction.map(
		func(particle:ParticleData.Particle) -> ParticleData.Particle:
			return (
				(sign(particle) * ParticleData.GENERAL_CONVERSION[ParticleData.base(particle)])
				if ParticleData.base(particle) not in ParticleData.GENERAL_PARTICLES else particle
			)
	)
	
func convert_interactions_to_general(interactions: Array) -> Array:
	var converted_interactions : Array = interactions.map(convert_interaction_to_general)
	
	var general_interactions : Array = []
	for i:int in interactions.size():
		var converted_interaction: Array = converted_interactions[i]
		var base_interaction: Array = interactions[i]
		
		if converted_interaction not in interactions:
			general_interactions.push_back(base_interaction)

		elif converted_interaction not in general_interactions:
			general_interactions.push_back(converted_interaction)

	return general_interactions

func get_print_time() -> String:
	return "time: " + str(Time.get_ticks_usec() - start_time) + " usec"

func get_connection_matrices(interaction_matrices: Array[InteractionMatrix]) -> Array[ConnectionMatrix]:
	var connection_matrices: Array[ConnectionMatrix] = []
	
	for interaction_matrix:InteractionMatrix in interaction_matrices:
		connection_matrices.push_back(interaction_matrix.get_connection_matrix())
	
	return connection_matrices

func get_usable_interactions(interaction_checks: Array[bool]) -> Array:
	var usable_interactions : Array = []
	
	for interaction_type_count in range(ParticleData.INTERACTIONS.size()):
		if interaction_checks[interaction_type_count]:
			usable_interactions += ParticleData.INTERACTIONS[interaction_type_count]
	
	return usable_interactions

func get_non_shared_elements(array1: Array, array2: Array) -> Array:
	
	var non_shared : Array = []
	var array1_copy : Array = array1.duplicate()
	var array2_copy : Array = array2.duplicate()
	
	for element:Variant in array1:
		if element not in array2_copy:
			non_shared.append(element)
		else:
			array1_copy.erase(element)
			array2_copy.erase(element)
	
	for element:Variant in array2_copy:
		if element not in array1_copy:
			non_shared.append(element)
		else:
			array1_copy.erase(element)
	
	return non_shared

func get_shared_elements(array1 : Array, array2 : Array) -> Array:
	var shared_elements: Array = []
	
	for element:Variant in array2:
		if element in shared_elements:
			continue
		var shared_element := []
		shared_element.resize(min(array1.count(element), array2.count(element)))
		shared_element.fill(element)
		shared_elements += shared_element
	
	return shared_elements

func get_shared_elements_count(array1 : Array, array2 : Array) -> int:
	var shared_array1_count: int = 0
	var shared_array2_count: int = 0
	
	for element:Variant in array1:
		if element in array2:
			shared_array1_count += 1
	
	for element:Variant in array2:
		if element in array1:
			shared_array2_count += 1
	
	return min(shared_array1_count, shared_array2_count)

func print_time(count: int = -1) -> void:
	if !print_times:
		return
	
	if count == -1:
		print("Time: " + str(Time.get_ticks_usec() - start_time))
	else:
		print(count, "Time: ", get_print_time())

func get_permutations(array: Array, count: int) -> Array:
	var permutations : Array = []
	
	if count == 0:
		return [[]]
	
	var index_permutations : Array = get_index_permutations(range(array.size()), count)
	for i:int in range(index_permutations.size()):
		permutations.push_back([])
		for index:int in index_permutations[i]:
			permutations[i].push_back(array[index])
	
	var unique_permutations : Array = []
	for i:int in range(permutations.size()):
		if permutations[i] not in unique_permutations:
			unique_permutations.push_back(permutations[i])
	
	return unique_permutations

func get_index_permutations(indices: PackedInt32Array, count: int) -> Array[PackedInt32Array]:
	var permutations : Array[PackedInt32Array] = []
	
	for index:int in indices:
		permutations += get_index_permutations_from_index(indices.duplicate(), count, index)
	
	var unique_permutations : Array[PackedInt32Array] = []
	for i:int in range(permutations.size()):
		permutations[i].sort()
		if permutations[i] not in unique_permutations:
			unique_permutations.push_back(permutations[i])
	
	return unique_permutations
	
func get_index_permutations_from_index(
	indices: PackedInt32Array, count: int, current_index : int
) -> Array[PackedInt32Array]:
	
	count -= 1
	
	if count == 0:
		return [[current_index]]
	
	indices.remove_at(indices.find(current_index))
	
	var permutations_from_current_index : Array[PackedInt32Array] = []
	
	for index:int in indices:
		var index_permutations: Array[PackedInt32Array] = get_index_permutations_from_index(indices.duplicate(), count, index)
		for permutation in index_permutations:
			var permutation_from_current_index : PackedInt32Array = [current_index]
			permutation_from_current_index.append_array(permutation)
			
			permutations_from_current_index.push_back(permutation_from_current_index)
	
	return permutations_from_current_index

func get_hadron_connections(
	matrix: InteractionMatrix,
	hadron_ids: PackedInt32Array
) -> Array[PackedInt32Array]:
	var connections: Array[PackedInt32Array] = []
	
	for from_id:int in hadron_ids:
		var from_state: StateLine.State = matrix.get_state_from_id(from_id)

		for to_id:int in hadron_ids:
			if (
				from_id == to_id
				or from_state == matrix.get_state_from_id(to_id)
			):
				continue
			
			connections += get_hadron_connections_to_id(
				matrix,
				from_id,
				from_state,
				to_id
			)

	return connections

func get_hadron_connections_to_id(
	matrix: InteractionMatrix,
	from_id: int,
	from_state: int,
	to_id: int
) -> Array[PackedInt32Array]:
	var connections: Array[PackedInt32Array] = []
	
	for from_particle: ParticleData.Particle in get_shared_elements(
		matrix.unconnected_matrix[from_id], matrix.unconnected_matrix[to_id]
	):
		if !is_out_particle(from_particle, from_state):
			continue
		
		connections.push_back(PackedInt32Array([from_id, to_id, from_particle]))
	
	return connections

func is_out_particle(particle: ParticleData.Particle, state: StateLine.State) -> bool:
	return StateLine.state_factor[state] == sign(particle)

func interaction_size(interaction: Array) -> int:
	return 1 + int(interaction.size() == 4)

func is_connection_number_possible(unconnected_particle_count : int, interaction_count : int) -> bool:
	if unconnected_particle_count == 0:
		return interaction_count == 0
	
	if interaction_count == 1:
		return unconnected_particle_count == INTERACTION_SIZE

	return unconnected_particle_count <= interaction_count * INTERACTION_SIZE

func are_quantum_numbers_valid(initial_state : Array, final_state : Array) -> bool:
	for quantum_number:ParticleData.QuantumNumber in ParticleData.QuantumNumber.values():
		if !is_equal_approx(
			calculate_quantum_sum(quantum_number, initial_state),
			calculate_quantum_sum(quantum_number, final_state)
		):
			if (
				quantum_number == ParticleData.QuantumNumber.charge or
				quantum_number == ParticleData.QuantumNumber.lepton or 
				quantum_number == ParticleData.QuantumNumber.quark
			):
				return false
	
	return true

func calculate_quantum_sum(quantum_number: ParticleData.QuantumNumber, state_interactions: Array) -> float:
	var quantum_sum: float = 0
	for state_interaction:Array in state_interactions:
		for particle:ParticleData.Particle in state_interaction:
			quantum_sum += ParticleData.quantum_number(particle, quantum_number)
	return quantum_sum
