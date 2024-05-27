extends Node

enum INTERACTION_TYPE {electroweak, strong, higgs, weak}
enum Shade {Bright, Dark, None}

const SHADED_PARTICLES := [ParticleData.BRIGHT_PARTICLES, ParticleData.DARK_PARTICLES, ParticleData.SHADED_PARTICLES]
const INTERACTION_SIZE = 3.0

var INTERACTIONS := ParticleData.INTERACTIONS
var TOTAL_INTERACTIONS : Array

var Vision: Node

enum Find {All, One, LowestOrder}

enum INDEX {unconnected, connected, ID = 0, TYPE, START = 0, END, INTERACTION = 0, CONNECTION_COUNT, CONNECTION_PARTICLES = 1}
enum {
	INVALID, VALID,
	FAILED, SUCCEEDED,
	ATTEMPTS_PER_DEGREE = 10,
	UNIQUE_CONNECTION_ATTEMPTS = 100, UNIQUE_CONNECTION_FAILED,
	CONNECTION_ATTEMPTS = 25, CONNECTION_FAILED,
	MAX_PATH_STEPS = 100,
	MAX_SHADE_CONNECTION_ROTATIONS = 100,
	MAX_LOOP_COUNT = 20
}

const state_factor : Dictionary = {
	StateLine.StateType.Initial: +1,
	StateLine.StateType.Final: -1
}

const states : Array[StateLine.StateType] = [
	StateLine.StateType.Initial,
	StateLine.StateType.Final
]

const shades : Array[Shade] = [
	Shade.Bright,
	Shade.Dark
]

const shade_factor : Dictionary = {
	Shade.Bright: -1,
	Shade.Dark: +1
}

var start_time : float
var print_times := false

var generated_matrix: InteractionMatrix

func init(vision: Node) -> void:
	Vision = vision

func get_useable_interactions_from_particles(allowed_particles: Array) -> Array:
	var useable_interactions: Array = []
	
	for interaction_set:Array in [ParticleData.INTERACTIONS, ParticleData.GENERAL_INTERACTIONS]:
		for interaction_type in interaction_set:
			for interaction:Array in interaction_type:
				if interaction.all(
					func(particle: ParticleData.Particle) -> bool:
						return particle in allowed_particles
				):
					useable_interactions.push_back(interaction)
	
	return useable_interactions

func generate_diagrams(
	initial_state: Array, final_state: Array, min_degree: int, max_degree: int, useable_interactions: Array, find: Find = Find.All
) -> Array[ConnectionMatrix]:
	
	start_time = Time.get_ticks_usec()
	var print_results : bool = false
	
	if print_results:
		print(initial_state)
		print(final_state)
	
	if compare_quantum_numbers(initial_state, final_state) == INVALID:
		print('Initial state quantum numbers do not match final state')
		return [null]
	
	var general_usable_interactions := convert_interactions_to_general(useable_interactions)
	
	var useable_particle_interactions : Dictionary = get_useable_particle_interactions(useable_interactions)
	
	var base_interaction_matrix := create_base_interaction_matrix(initial_state, final_state)
	var forbidden_exit_points: Array = get_forbidden_exit_points(base_interaction_matrix)

	var same_hadron_particles := get_shared_elements(get_hadron_particles(initial_state), get_hadron_particles(final_state))
	var possible_hadron_connections := get_possible_hadron_connections(base_interaction_matrix, same_hadron_particles)

	var degrees_to_check = get_degrees_to_check(
		min_degree, max_degree, base_interaction_matrix, useable_interactions
	)

	var generated_connection_matrices : Array[ConnectionMatrix] = []
	
	for degree in degrees_to_check:
		if print_results:
			print("degree: " + str(degree) + " " + get_print_time())

		var possible_hadron_connection_count := get_possible_hadron_connection_count(
			base_interaction_matrix.get_unconnected_state_particle_count(StateLine.StateType.Both),
			same_hadron_particles.size(), degree
		)
		
		var state_connected_matrices: Array[InteractionMatrix] = generate_unique_state_connected_interaction_matrices(
			base_interaction_matrix, degree, possible_hadron_connections, possible_hadron_connection_count, useable_particle_interactions
		)
		
		var completed_state_connection_matrices: Array[ConnectionMatrix] = []
		var unconnected_interaction_matrices: Array[InteractionMatrix] = []
		
		if find == Find.One:
			state_connected_matrices.shuffle()

		for matrix in state_connected_matrices:
			if matrix.get_unconnected_particle_count() > 0:
				unconnected_interaction_matrices.push_back(matrix)
				continue
		
			if !matrix.is_fully_connected(true):
				continue
			
			var connection_matrix: ConnectionMatrix = matrix.get_connection_matrix()
			connection_matrix.reindex()
			
			if completed_state_connection_matrices.any(
				func(compare_matrix: ConnectionMatrix) -> bool:
					return compare_matrix.is_duplicate(connection_matrix)
			):
				continue
			
			completed_state_connection_matrices.push_back(connection_matrix)
				
			if find == Find.One:
				break
		
		generated_connection_matrices += completed_state_connection_matrices
		
		for i:int in state_connected_matrices.size():
			state_connected_matrices[i] = convert_interaction_matrix_to_normal(state_connected_matrices[i])
		
		var unique_interaction_matrices : Array[InteractionMatrix] = generate_unique_interaction_matrices(
			state_connected_matrices, degree, general_usable_interactions
		)
		
		print_time(0)
		
		if find == Find.One:
			unique_interaction_matrices.shuffle()
	
		for interaction_matrix:InteractionMatrix in unique_interaction_matrices:
			generated_connection_matrices += generate_unique_connection_matrices(
				interaction_matrix, forbidden_exit_points, find
			)
			
			if find == Find.One: break
		
		if (find == Find.One or find == Find.LowestOrder) and generated_connection_matrices.size() != 0:
			break

	if generated_connection_matrices.size() == 0:
		if print_results:
			print('Generation failed')

		return [null]
	
	print("Generation Completed: " + get_print_time())
	
	generated_connection_matrices = cut_colourless_matrices(generated_connection_matrices)
	generated_connection_matrices = convert_general_matrices(generated_connection_matrices)
	
	if find == Find.One:
		return [generated_connection_matrices.pick_random()]
	
	return generated_connection_matrices

func cut_colourless_matrices(matrices: Array[ConnectionMatrix]) -> Array[ConnectionMatrix]:
	var valid_matrices: Array[ConnectionMatrix] = []
	
	for matrix in matrices:
		if is_matrix_colourless(matrix):
			continue
		
		valid_matrices.push_back(matrix)
	
	return valid_matrices

func is_matrix_colourless(matrix: ConnectionMatrix) -> bool:
	var has_gluon: bool = !matrix.find_first_id(
		func(id: int) -> bool:
			return ParticleData.Particle.gluon in matrix.get_connected_particles(id)
	) == matrix.matrix_size
	
	if !has_gluon:
		return false
	
	var drawing_matrix := DrawingMatrix.new()
	drawing_matrix.initialise_from_connection_matrix(matrix)
	
	var vision_matrix : DrawingMatrix = Vision.generate_colour_matrix(drawing_matrix)
	var zip: Array = Vision.generate_colour_paths(vision_matrix, true)
	
	return Vision.find_colourless_interactions(zip.front(), zip.back(), vision_matrix, true).size() > 0

func generate_unique_state_connected_interaction_matrices(
	base_interaction_matrix: InteractionMatrix, degree: int, possible_hadron_connections: Array,
	possible_hadron_connection_count: Array, useable_particle_interactions: Dictionary
) -> Array[InteractionMatrix]:
	
	var hadron_connected_matrices: Array[InteractionMatrix] = generate_hadron_connected_matrices(
		base_interaction_matrix, possible_hadron_connections, possible_hadron_connection_count
	)
	
	var state_connected_matrices: Array[InteractionMatrix] = generate_state_connected_interaction_matrices(
		hadron_connected_matrices, degree, useable_particle_interactions
	)

	return state_connected_matrices

func generate_hadron_connected_matrices(
	base_interaction_matrix: InteractionMatrix, possible_hadron_connections: Array, possible_hadron_connection_count: Array
) -> Array[InteractionMatrix]:
	
	var hadron_connected_matrices: Array[InteractionMatrix] = []
	
	for connection_count in possible_hadron_connection_count:
		var hadron_connection_permutations : Array = get_permutations(possible_hadron_connections, connection_count)
		
		for hadron_connection_permutation in hadron_connection_permutations:
			var interaction_matrix : InteractionMatrix = base_interaction_matrix.duplicate(true)
			
			for hadron_connection in hadron_connection_permutation:
				interaction_matrix.insert_connection(hadron_connection)
			
			hadron_connected_matrices.push_back(interaction_matrix)
	
	return hadron_connected_matrices

func generate_state_connected_interaction_matrices(
	unconnected_matrices: Array[InteractionMatrix], degree: int, useable_particle_interactions: Dictionary
) -> Array[InteractionMatrix]:
	
	var connected_matrices: Array[InteractionMatrix] = []
	
	for interaction_matrix:InteractionMatrix in unconnected_matrices:
		connected_matrices += connect_state_fermions(interaction_matrix, degree, useable_particle_interactions)
	
	return connected_matrices

func connect_state_fermions(
	unconnected_interaction_matrix: InteractionMatrix, degree: int, useable_particle_interactions: Dictionary
) -> Array[InteractionMatrix]:
	var in_out_matrix: InteractionMatrix = convert_interaction_matrix_to_in_out(unconnected_interaction_matrix)
	
	var is_fermion : Callable = func(particle:ParticleData.Particle) -> bool: return base_particle(particle) in ParticleData.FERMIONS
	
	var fermion_ids : PackedInt32Array = unconnected_interaction_matrix.find_all_unconnected(is_fermion)
	var point_in_fermion_ids : Callable = func(point: int) -> bool: return point in fermion_ids
	
	var fermion_entry_points := filter_points(unconnected_interaction_matrix.get_entry_points(), point_in_fermion_ids)
	var fermion_exit_points := filter_points(unconnected_interaction_matrix.get_exit_points(), point_in_fermion_ids)
	var entry_states : Array = unconnected_interaction_matrix.get_entry_states()
	var fermion_entry_states: Array = entry_states.map(
		func(state:Array) -> Array:
			return state.filter(is_fermion).map(
				func(fermion:ParticleData.Particle) -> ParticleData.Particle:
					return base_particle(fermion)
	))
	
	for entry_point:int in fermion_entry_points:
		fermion_entry_states[entry_point] = fermion_entry_states[entry_point].filter(is_fermion)

	var connected_interaction_matrices: Array[InteractionMatrix] = [in_out_matrix]

	for entry_point:int in fermion_entry_points:
		var fermions: Array = fermion_entry_states[entry_point].filter(is_fermion)
		
		for fermion in fermions:
			var fermion_connected_matrices: Array[InteractionMatrix] = []
			
			for interaction_matrix:InteractionMatrix in connected_interaction_matrices:
				var further_matrices: Array[InteractionMatrix] = connect_fermion_from_point(
					interaction_matrix, degree - interaction_matrix.state_count[StateLine.StateType.None],
					entry_point, fermion, useable_particle_interactions, true
				)
				
				fermion_connected_matrices += further_matrices
				
				if further_matrices == null:
					breakpoint
			
			connected_interaction_matrices = fermion_connected_matrices.duplicate(true)
			
	
	if is_null_array(connected_interaction_matrices):
		return [null]
		
	return connected_interaction_matrices

func convert_interaction_matrix_to_in_out(interaction_matrix: InteractionMatrix):
	var converted_matrix: InteractionMatrix = interaction_matrix.duplicate(true)
	
	for id:int in converted_matrix.matrix_size:
		converted_matrix.unconnected_matrix[id] = converted_matrix.unconnected_matrix[id].map(
			func(particle:ParticleData.Particle) -> ParticleData.Particle:
				if particle in ParticleData.UNSHADED_PARTICLES:
					return particle
				
				return StateLine.state_factor[interaction_matrix.get_state_from_id(id)] * particle
		)
	
	return converted_matrix

func convert_interaction_matrix_to_normal(interaction_matrix: InteractionMatrix):
	var converted_matrix: InteractionMatrix = interaction_matrix.duplicate(true)
	
	for id:int in converted_matrix.get_state_count(StateLine.StateType.Both):
		converted_matrix.unconnected_matrix[id] = converted_matrix.unconnected_matrix[id].map(
			func(particle:ParticleData.Particle) -> ParticleData.Particle:
				if particle in ParticleData.UNSHADED_PARTICLES:
					return particle
				
				return StateLine.state_factor[interaction_matrix.get_state_from_id(id)] * particle
		)
	
	return converted_matrix

func can_exit(interaction_matrix: InteractionMatrix, fermion: ParticleData.Particle) -> bool:
	return GLOBALS.find_all_var(
		interaction_matrix.get_unconnected_state(StateLine.StateType.Both),
		func(exit_state:Array) -> bool:
			return can_particle_connect(fermion, exit_state)
	).size() > 0

func connect_fermion_from_point(
	unconnected_interaction_matrix: InteractionMatrix, interaction_count_left: int, current_point: int, fermion: ParticleData.Particle,
	useable_particle_interactions: Dictionary, is_entry_point: bool = false
) -> Array[InteractionMatrix]:
	
	var further_matrices: Array[InteractionMatrix] = []
	
	if interaction_count_left == 0:
		if is_entry_point or !can_exit(unconnected_interaction_matrix, fermion):
			return []
	
	var unconnected_particles: Array = unconnected_interaction_matrix.get_unconnected_particles()
	unconnected_particles.erase(fermion)
	
	for interaction:Array in useable_particle_interactions[fermion]:
		further_matrices += connect_next_interaction(
			interaction.duplicate(true), unconnected_interaction_matrix.duplicate(true), unconnected_particles, interaction_count_left, current_point,
			fermion
		)
	
	var connected_matrices: Array[InteractionMatrix] = []
	
	for i:int in further_matrices.size():
		var matrix: InteractionMatrix = further_matrices[i]
		
		var next_point: int = matrix.matrix_size - 1
		var next_fermion_index: ParticleData.Particle = GLOBALS.find_var(
			matrix.unconnected_matrix[next_point], func(particle: ParticleData.Particle) -> bool: return particle in ParticleData.FERMIONS
		)
		
		if next_fermion_index == matrix.unconnected_matrix[next_point].size():
			connected_matrices.push_back(matrix)
			continue
		
		connected_matrices.append_array(connect_fermion_from_point(
			matrix, interaction_count_left - 1, next_point, matrix.unconnected_matrix[next_point][next_fermion_index],
			useable_particle_interactions
		))
	
	return connected_matrices

func connect_next_interaction(
	interaction: Array, unconnected_interaction_matrix: InteractionMatrix, unconnected_particles: Array, interaction_count_left: int,
	current_point: int, current_particle: ParticleData.Particle
) -> Array[InteractionMatrix]:
	
	var connected_matrices: Array[InteractionMatrix] = []
	var extra_particles: Array = interaction.duplicate()
	extra_particles.erase(current_particle)
	
	var shared_particles: Array = extra_particles.filter(
		func(particle: ParticleData.Particle) -> bool:
			return can_particle_connect(particle, unconnected_particles)
	)
	
	var possible_connection_count: PackedInt32Array = range(shared_particles.size() + 1).filter(
		func(connection_count: int) -> bool:
			return is_connection_number_possible(
				unconnected_particles.size() + extra_particles.size() - 2*connection_count, interaction_count_left-1
			)
	)
	
	if possible_connection_count.size() == 0:
		return []
	
	unconnected_interaction_matrix.add_unconnected_interaction(interaction)
	var next_point: int = unconnected_interaction_matrix.matrix_size - 1
	
	unconnected_interaction_matrix.connect_interactions(current_point, next_point, current_particle)
	
	if 0 in possible_connection_count:
		connected_matrices.push_back(unconnected_interaction_matrix)
	
	if !(1 in possible_connection_count or 2 in possible_connection_count):
		return connected_matrices
	
	connected_matrices += connect_particle(shared_particles.front(), next_point, unconnected_interaction_matrix)
	
	if shared_particles.size() == 1:
		return connected_matrices

	if 2 in possible_connection_count:
		var two_connected_matrices: Array[InteractionMatrix] = []
		for matrix in connected_matrices:
			two_connected_matrices += connect_particle(shared_particles.back(), next_point, matrix)
		
		if 1 not in possible_connection_count:
			return two_connected_matrices

	if 1 in possible_connection_count:
		connected_matrices += connect_particle(shared_particles.back(), next_point, unconnected_interaction_matrix)

	return connected_matrices

func connect_particle(
	particle: ParticleData.Particle, current_point: int, unconnected_interaction_matrix: InteractionMatrix
) -> Array[InteractionMatrix]:
	var connected_matrices: Array[InteractionMatrix] = []
	
	for interaction_index:int in unconnected_interaction_matrix.matrix_size:
		if interaction_index == current_point:
			continue
		
		if unconnected_interaction_matrix.unconnected_matrix[interaction_index].size() == 0:
			continue
		
		for connection_particle in get_possible_connection_particles(
			particle, unconnected_interaction_matrix.unconnected_matrix[interaction_index]
		):
			var connected_matrix: InteractionMatrix = unconnected_interaction_matrix.duplicate(true)
			
			connected_matrix.connect_asymmetric_interactions(
				current_point, interaction_index, particle, connection_particle, base_particle(connection_particle), connection_particle >= 0
			)
			
#			connected_matrix.connect_in_out_interactions(current_point, interaction_index, connection_particle)
			connected_matrices.push_back(connected_matrix)
	
	return connected_matrices

func get_possible_connection_particles(particle: ParticleData.Particle, unconnected_particles: Array) -> Array:
	var possible_connection_particles: Array = []

	if particle in ParticleData.UNSHADED_PARTICLES:
		return [particle] if particle in unconnected_particles else []
	
	if -particle in unconnected_particles:
		possible_connection_particles.push_back(-particle)
	
	if particle in ParticleData.GENERAL_PARTICLES:
		possible_connection_particles += unconnected_particles.filter(
			func(unconnected_particle: ParticleData.Particle) -> bool:
				return -unconnected_particle in ParticleData.GENERAL_CONVERSION[particle]
		)
	
	return possible_connection_particles

func can_particle_connect(particle: ParticleData.Particle, unconnected_particles: Array) -> bool:
	if particle in ParticleData.UNSHADED_PARTICLES:
		return particle in unconnected_particles
	
	if particle in ParticleData.GENERAL_PARTICLES:
		return (
			-particle in unconnected_particles or
			unconnected_particles.any(
				func(unconnected_particle: ParticleData.Particle) -> bool:
					return -unconnected_particle in ParticleData.GENERAL_CONVERSION[particle]
		))
	
	return -particle in unconnected_particles

func get_useable_particle_interactions(useable_interactions: Array) -> Dictionary:
	var useable_particle_interactions : Dictionary = {}
	var useable_general_interactions: Array = convert_interactions_to_general(useable_interactions)
	var useable_particles: Array[ParticleData.Particle] = get_useable_particles_from_interactions(
		useable_interactions + useable_general_interactions
	)
	
	for particle:ParticleData.Particle in ParticleData.BASE_PARTICLES:
		if particle not in useable_particles:
			useable_particle_interactions[particle] = []
			continue
		
		useable_particle_interactions[particle] = ParticleData.PARTICLE_INTERACTIONS[particle].filter(
			func(interaction:Array) -> bool:
				return interaction.all(
					func(particle: ParticleData.Particle) -> bool:
						return base_particle(particle) in useable_particles
				)
		)
	
	return useable_particle_interactions

func get_useable_particles_from_interactions(interactions: Array) -> Array[ParticleData.Particle]:
	var useable_particles: Array[ParticleData.Particle] = []
	
	for interaction:Array in interactions:
		for particle:ParticleData.Particle in interaction:
			if base_particle(particle) in useable_particles:
				continue
			
			useable_particles.push_back(base_particle(particle))
	
	return useable_particles
	

func anti_particle(particle: ParticleData.Particle) -> ParticleData.Particle:
	if base_particle(particle) in ParticleData.SHADED_PARTICLES:
		return -particle
	
	return particle 

func get_forbidden_exit_points(base_interaction_matrix: InteractionMatrix) -> Array:
	var forbidden_exit_points: Array = []
	var state_count: int = base_interaction_matrix.get_state_count(StateLine.StateType.Both)
	var exit_points: PackedInt32Array = base_interaction_matrix.get_exit_points()
	var entry_points: PackedInt32Array = base_interaction_matrix.get_entry_points()
	
	for i:int in state_count:
		var interaction: Array = base_interaction_matrix.unconnected_matrix[i]
		forbidden_exit_points.push_back([])
		
		if i not in entry_points:
			continue

		forbidden_exit_points[i].resize(interaction.size())
		
		
		for particle_index:int in interaction.size():
			var particle: ParticleData.Particle = interaction[particle_index]
			var forbidden_points: Array = []
			for j:int in state_count:
				if j not in exit_points:
					continue

				if base_interaction_matrix.unconnected_matrix[j].count(
					particle if base_particle(particle) in ParticleData.BOSONS else (
						StateLine.state_factor[base_interaction_matrix.get_state_from_id(i)] *
						StateLine.state_factor[base_interaction_matrix.get_state_from_id(j)] *
						anti_particle(particle)
						)
				) == 0:
					forbidden_points.push_back(j)
			
			forbidden_exit_points[i][particle_index] = forbidden_points
	
	return forbidden_exit_points

func create_base_interaction_matrix(initial_state: Array, final_state: Array) -> InteractionMatrix:
	var base_interaction_matrix := InteractionMatrix.new()
	for state_interaction in initial_state:
		base_interaction_matrix.add_unconnected_interaction(state_interaction, StateLine.StateType.Initial)
	for state_interaction in final_state:
		base_interaction_matrix.add_unconnected_interaction(state_interaction, StateLine.StateType.Final)
	return base_interaction_matrix

func get_hadron_particles(state_interactions: Array) -> Array:
	var hadron_particles : Array = []
	
	for state_interaction in state_interactions:
		var is_hadron: bool = state_interaction.size() > 1
		if !is_hadron:
			continue
		hadron_particles += state_interaction
	
	return hadron_particles

func get_degrees_to_check(
	min_degree: int, max_degree: int, interaction_matrix: InteractionMatrix, interactions: Array) -> Array:
	var degrees_to_check: Array = []
	var initial_hadron_particles := get_hadron_particles(interaction_matrix.get_unconnected_state(StateLine.StateType.Initial))
	var final_hadron_particles := get_hadron_particles(interaction_matrix.get_unconnected_state(StateLine.StateType.Final))
	var number_of_state_particles := interaction_matrix.get_unconnected_state_particle_count(StateLine.StateType.Both)

	var number_of_unconnectable_particles: int = (
		number_of_state_particles - initial_hadron_particles.size() - final_hadron_particles.size() +
		get_non_shared_elements(initial_hadron_particles, final_hadron_particles).size()
	)

	min_degree = max(ceil(number_of_unconnectable_particles/3.0), min_degree)
	
	var unconnected_particles := interaction_matrix.get_unconnected_base_particles()
	unconnected_particles.sort()
	if unconnected_particles in interactions:
		min_degree = interaction_size(unconnected_particles)
	
	for degree in range(min_degree, max_degree+1):
		if (number_of_state_particles - degree) % 2 == 0:
			degrees_to_check.append(degree)

	return degrees_to_check

func convert_interaction_to_general(interaction: Array) -> Array:
	return interaction.map(
		func(particle:ParticleData.Particle) -> ParticleData.Particle:
			return (
				(sign(particle) * ParticleData.GENERAL_CONVERSION[base_particle(particle)])
				if base_particle(particle) not in ParticleData.GENERAL_PARTICLES else particle
			)
	)

func convert_general_matrices(general_connection_matrices: Array[ConnectionMatrix]) -> Array[ConnectionMatrix]:
	var converted_matrices: Array[ConnectionMatrix] = []
	
	for matrix in general_connection_matrices:
		var has_general_particles: bool = matrix.find_first_id(
			func(id:int) -> bool:
				return matrix.get_connected_particles(id, true).any(
					func(particle:ParticleData.Particle) -> bool:
						return particle in ParticleData.GENERAL_PARTICLES)
		) != matrix.matrix_size
		
		if !has_general_particles:
			converted_matrices.push_back(matrix)
			continue
		
		var converted_matrix: ConnectionMatrix = convert_general_matrix(matrix)
		
		if converted_matrix:
			converted_matrices.push_back(converted_matrix)
	
	return converted_matrices

func convert_general_matrix(matrix: ConnectionMatrix) -> ConnectionMatrix:
	for id:int in matrix.get_state_ids(StateLine.StateType.None):
		if id_needs_converting(id, matrix):
			matrix = convert_general_id(id, matrix)

	return matrix

func convert_general_id(id: int, matrix: ConnectionMatrix) -> ConnectionMatrix:
	var connected_particles: Array = matrix.get_connected_particles(id, true)
	var general_particle: ParticleData.Particle = connected_particles[GLOBALS.find_var(
		connected_particles, func(particle:ParticleData.Particle) -> bool:
			return particle in ParticleData.GENERAL_PARTICLES
	)]
	var non_general_particle: ParticleData.Particle = connected_particles[GLOBALS.find_var(
		connected_particles, func(particle:ParticleData.Particle) -> bool:
			return particle in ParticleData.FERMIONS and particle not in ParticleData.GENERAL_PARTICLES
	)]
	
	for connected_id in matrix.get_connected_ids(id, true):
		var connection_particles: Array = matrix.get_connection_particles(id, connected_id, true)
		
		if general_particle not in connection_particles:
			continue
			
		var is_reverse_connection: bool = general_particle not in matrix.get_connection_particles(id, connected_id)
		
		if matrix.get_state_from_id(connected_id) != StateLine.StateType.None:
			return null
		
		matrix.disconnect_interactions(id, connected_id, general_particle, false, is_reverse_connection)
		matrix.connect_interactions(id, connected_id, non_general_particle, false, is_reverse_connection)
		
		if id_needs_converting(connected_id, matrix):
			matrix = convert_general_id(connected_id, matrix)
			if !matrix:
				return null
		
	return matrix

func id_needs_converting(id: int, matrix: ConnectionMatrix) -> bool:
	var connected_particles: Array = matrix.get_connected_particles(id, true)
	
	if connected_particles.has(ParticleData.Particle.W):
		return false
	
	if connected_particles.all(func(particle:ParticleData.Particle) -> bool: return particle not in ParticleData.FERMIONS):
		return false
	
	if GLOBALS.count_var(connected_particles, func(particle:ParticleData.Particle) -> bool: return particle in ParticleData.GENERAL_PARTICLES) != 1:
		return false
	
	return true
	
func convert_interactions_to_general(interactions: Array) -> Array:
	var converted_interactions : Array = interactions.map(convert_interaction_to_general)
	
	var general_interactions : Array = []
	for interaction:Array in converted_interactions:
		if interaction not in general_interactions:
			general_interactions.push_back(interaction)

	return general_interactions

func generate_useable_interactions_from_particles(useable_particles: Array) -> Array:
	var useable_interactions: Array = []
	
	for interaction_type:Array in ParticleData.INTERACTIONS:
		for interaction:Array in interaction_type:
			if interaction.all(
				func(particle: ParticleData.Particle) -> bool:
					return particle in useable_particles
			):
				useable_interactions.push_back(interaction)
	
	return useable_interactions


func get_print_time() -> String:
	return "time: " + str(Time.get_ticks_usec() - start_time) + " usec"

func is_connection_matrix_unique(connection_matrix: ConnectionMatrix, connection_matrices: Array[ConnectionMatrix]) -> bool:
	return !connection_matrices.any(
		func(matrix: ConnectionMatrix) -> bool:
			return matrix.is_duplicate(connection_matrix)
	)

func generate_unique_connection_matrices(
	unconnected_interaction_matrix: InteractionMatrix, forbidden_exit_points: Array, find: Find,
	entry_points: PackedInt32Array = unconnected_interaction_matrix.get_entry_points(),
	exit_points: PackedInt32Array = unconnected_interaction_matrix.get_exit_points()
) -> Array[ConnectionMatrix]:
		
	var connected_matrices: Array[ConnectionMatrix] = connect_interaction_matrix(
		unconnected_interaction_matrix, forbidden_exit_points, find, entry_points, exit_points
	)
	
	if connected_matrices.size() == 0 or connected_matrices == [null]:
		return []
	
	if find == Find.One:
		return connected_matrices
	
	print_time(4)
	var unique_connected_matrices : Array[ConnectionMatrix] = []
	
	print_time(5)
	
	for connected_matrix:ConnectionMatrix in connected_matrices:
		connected_matrix.reindex()
	
	print_time(6)
	
	for connection_matrix:ConnectionMatrix in connected_matrices:
		if unique_connected_matrices.any(
			func(matrix: ConnectionMatrix) -> bool: 
				return matrix.is_duplicate(connection_matrix)
		):
			continue
		
		unique_connected_matrices.push_back(connection_matrix)
	
	print_time(7)
	
	return unique_connected_matrices

func get_connection_matrices(interaction_matrices: Array[InteractionMatrix]) -> Array[ConnectionMatrix]:
	var connection_matrices: Array[ConnectionMatrix] = []
	
	for interaction_matrix:InteractionMatrix in interaction_matrices:
		connection_matrices.push_back(interaction_matrix.get_connection_matrix())
	
	return connection_matrices

func connect_interaction_matrix(
	unconnected_interaction_matrix: InteractionMatrix, forbidden_exit_points: Array, find: Find,
	entry_points: PackedInt32Array = unconnected_interaction_matrix.get_entry_points(),
	exit_points: PackedInt32Array = unconnected_interaction_matrix.get_exit_points()
) -> Array[ConnectionMatrix]:
	
	var directional_interaction_matrices : Array[InteractionMatrix] = generate_directional_connections(
		unconnected_interaction_matrix, forbidden_exit_points, entry_points, exit_points
	)
	
	if is_null_array(directional_interaction_matrices):
		return [null]
	
	var directionless_interaction_matrices: Array[InteractionMatrix] = generate_directionless_connections(
		unconnected_interaction_matrix, directional_interaction_matrices != []
	)
	
	if is_null_array(directionless_interaction_matrices):
		return [null]
	
	if find == Find.One:
		directional_interaction_matrices.shuffle()
		directionless_interaction_matrices.shuffle()
		
		for i:int in range(directional_interaction_matrices.size()):
			for j:int in range(directionless_interaction_matrices.size()):
				var combined_connection_matrix : ConnectionMatrix = combine_connection_matrices(
					get_connection_matrices([directional_interaction_matrices[i]]),
					get_connection_matrices([directionless_interaction_matrices[j]])
				).front()
				
				if combined_connection_matrix.is_fully_connected(true):
					return [combined_connection_matrix]
		
		return []
	
	var combined_connection_matrices : Array[ConnectionMatrix] = combine_connection_matrices(
		get_connection_matrices(directional_interaction_matrices), get_connection_matrices(directionless_interaction_matrices)
	)
	
	return combined_connection_matrices.filter(
		func(matrix: ConnectionMatrix) -> bool:
			return matrix.is_fully_connected(true)
	)

func combine_connection_matrices(
	base_connection_matrices: Array[ConnectionMatrix], combining_connection_matrices: Array[ConnectionMatrix]
) -> Array[ConnectionMatrix]:
	print_time(3)
	
	var combined_connection_matrices: Array[ConnectionMatrix] = []
	
	if base_connection_matrices.size() == 0:
		return combining_connection_matrices
	elif combining_connection_matrices.size() == 0:
		return base_connection_matrices
	
	for base_connection_matrix:ConnectionMatrix in base_connection_matrices:
		for combining_connection_matrix:ConnectionMatrix in combining_connection_matrices:
			var combined_matrix : ConnectionMatrix = base_connection_matrix.duplicate(true)
			combined_matrix.combine_matrix(combining_connection_matrix)
			combined_connection_matrices.push_back(combined_matrix)
	
	print_time()
	return combined_connection_matrices

func get_loop_points(interaction_matrix: InteractionMatrix) -> PackedInt32Array:
	return interaction_matrix.find_all_unconnected(func(particle:ParticleData.Particle) -> bool: return particle in ParticleData.FERMIONS)

func generate_directionless_connections(
	unconnected_interaction_matrix: InteractionMatrix, clear_connection_matrix: bool = true
) -> Array[InteractionMatrix]:
	print_time(2)
	
	if clear_connection_matrix:
		unconnected_interaction_matrix.clear_connection_matrix()
	
	var has_directionless_particles: bool = unconnected_interaction_matrix.get_unconnected_base_particles().any(
		func(particle:ParticleData.Particle) -> bool: return particle not in ParticleData.SHADED_PARTICLES
	)
	
	if !has_directionless_particles:
		return []
	
	var is_directionless_particle: Callable = func(particle:ParticleData.Particle) -> bool: return particle not in ParticleData.SHADED_PARTICLES
	
	var directionless_particle_count := unconnected_interaction_matrix.get_unconnected_particles().filter(is_directionless_particle).size()
	var directionless_ids := unconnected_interaction_matrix.find_all_unconnected(is_directionless_particle)
	
	var state_points : PackedInt32Array = unconnected_interaction_matrix.get_state_ids(StateLine.StateType.Both)

	var unconnected_interaction_matrices : Array[InteractionMatrix] = [unconnected_interaction_matrix]
	
	for connection_count in range(directionless_particle_count / 2.0):
		if unconnected_interaction_matrices.size() == 0:
			return [null]

		var iteration_matrices : Array[InteractionMatrix] = unconnected_interaction_matrices
		unconnected_interaction_matrices = []

		for matrix in iteration_matrices:
			var start_point := matrix.find_first_unconnected(is_directionless_particle)

			for further_matrix in generate_paths_from_point(
				start_point, matrix.duplicate(true), directionless_ids, directionless_ids, state_points, is_directionless_particle,
				true, false
			):
				if further_matrix == null:
					continue

				unconnected_interaction_matrices.push_back(further_matrix)
	
	return unconnected_interaction_matrices

func generate_directional_connections(
	unconnected_interaction_matrix: InteractionMatrix, forbidden_exit_points: Array,
	entry_points: PackedInt32Array = unconnected_interaction_matrix.get_entry_points(),
	exit_points: PackedInt32Array = unconnected_interaction_matrix.get_exit_points(),
	entry_states: Array = unconnected_interaction_matrix.get_entry_states()) -> Array[InteractionMatrix]:
	print_time(1)
	
	var has_directional_particles : bool = unconnected_interaction_matrix.get_unconnected_base_particles().any(
		func(particle:ParticleData.Particle) -> bool: return particle in ParticleData.SHADED_PARTICLES
	)
	
	if !has_directional_particles:
		return []

	unconnected_interaction_matrix.reduce_to_base_particles()
	entry_states = entry_states.map(
		func(state_interaction: Array) -> Array:
			return state_interaction.map(
				func(particle: ParticleData.Particle) -> ParticleData.Particle:
					return base_particle(particle)
	))

	var fermion_connected_matrices := generate_possible_loops(
		[unconnected_interaction_matrix], 
		func(particle: ParticleData.Particle) -> bool:
			return particle in ParticleData.FERMIONS
	)
	
	if is_null_array(fermion_connected_matrices):
		return [null]
	
	var connected_matrices: Array[InteractionMatrix] = []
	
	for fermion_connected_matrix:InteractionMatrix in fermion_connected_matrices:
		var W_connected_matrices := generate_W_connections(fermion_connected_matrix, entry_points, exit_points)
		
		if !is_null_array(W_connected_matrices):
			connected_matrices += W_connected_matrices
	
	if connected_matrices.size() == 0:
		return [null]
	
	return connected_matrices

func generate_possible_path(
	connected_interaction_matrices: Array[InteractionMatrix], start_point: int, available_points: PackedInt32Array,
	end_points: PackedInt32Array, state_points: PackedInt32Array, particle_test_function: Callable,
	starting_particle : ParticleData.Particle = ParticleData.Particle.none
) -> Array[InteractionMatrix]:
	
	if connected_interaction_matrices.size() == 0:
		return [null]
	
	var iteration_matrices : Array[InteractionMatrix] = connected_interaction_matrices
	connected_interaction_matrices = []
	
	const is_start_point : bool = true
	const connect_uniquely : bool = true
	
	for matrix in iteration_matrices:
		for further_matrix in generate_paths_from_point(
			start_point, matrix.duplicate(true), available_points, end_points, state_points, particle_test_function, is_start_point,
			connect_uniquely, starting_particle
		):
			if further_matrix == null:
				continue

			connected_interaction_matrices.push_back(further_matrix)
	
	return connected_interaction_matrices

func generate_possible_state_paths(
	interaction_matrix: InteractionMatrix, forbidden_exit_points: Array, start_points: PackedInt32Array, available_points: PackedInt32Array,
	end_points: PackedInt32Array, state_points: PackedInt32Array, particle_test_function: Callable, entry_states: Array = []
) -> Array[InteractionMatrix]:
	
	var connected_interaction_matrices : Array[InteractionMatrix] = [interaction_matrix]
	
	for start_point:int in start_points:
		for starting_particle_index:int in entry_states[start_point].size():
			var starting_particle: ParticleData.Particle = entry_states[start_point][starting_particle_index]
			
			var start_point_available_points : PackedInt32Array = filter_points(
				available_points,
				func(point: int) -> bool: 
					return point not in forbidden_exit_points[start_point][starting_particle_index]
			)
			
			connected_interaction_matrices = generate_possible_path(
				connected_interaction_matrices, start_point, start_point_available_points, end_points, state_points, particle_test_function,
				starting_particle
			)
	
	return connected_interaction_matrices

func generate_possible_paths(
	interaction_matrix: InteractionMatrix, start_points: PackedInt32Array, available_points: PackedInt32Array, end_points: PackedInt32Array,
	state_points: PackedInt32Array, particle_test_function: Callable
) -> Array[InteractionMatrix]:
	
	var connected_interaction_matrices : Array[InteractionMatrix] = [interaction_matrix]
	
	for start_point:int in start_points:
		connected_interaction_matrices = generate_possible_path(
			connected_interaction_matrices, start_point, available_points, end_points, state_points, particle_test_function
		)
	
	return connected_interaction_matrices

func generate_possible_loops(interaction_matrices : Array[InteractionMatrix], particle_test_function: Callable) -> Array[InteractionMatrix]:
	var connected_interaction_matrices: Array[InteractionMatrix] = []
	
	for loop_count in MAX_LOOP_COUNT:
		if interaction_matrices.size() == 0:
			break
		
		var iteration_matrices : Array[InteractionMatrix] = interaction_matrices
		interaction_matrices = []
		
		for matrix in iteration_matrices:
			var loop_point := matrix.find_first_unconnected(particle_test_function)
			
			if loop_point == matrix.matrix_size:
				connected_interaction_matrices.push_back(matrix)
				continue
			
			for further_matrix in generate_paths_from_point(
				loop_point, matrix.duplicate(true), matrix.get_state_ids(StateLine.StateType.None), [loop_point], [],
				particle_test_function, true
			):
				if further_matrix == null:
					continue

				interaction_matrices.push_back(further_matrix)
	
	return connected_interaction_matrices

func filter_points(points: PackedInt32Array, test_function: Callable) -> PackedInt32Array:
	var filtered_points: PackedInt32Array = []
	
	for point:int in points:
		if test_function.call(point):
			filtered_points.push_back(point)
	
	return filtered_points

func generate_W_connections(
	unconnected_interaction_matrix: InteractionMatrix, entry_points: PackedInt32Array, exit_points: PackedInt32Array
) -> Array[InteractionMatrix]:
	var is_W : Callable = func(particle:ParticleData.Particle) -> bool: return particle == ParticleData.Particle.W
	
	var W_ids : PackedInt32Array = unconnected_interaction_matrix.find_all_unconnected(is_W)
	var point_in_W_ids : Callable = func(point:int) -> bool: return point in W_ids
	
	entry_points = filter_points(entry_points, point_in_W_ids)
	exit_points = filter_points(exit_points, point_in_W_ids)

	var state_points = entry_points.duplicate()
	state_points.append_array(exit_points)
	
	var start_points: PackedInt32Array = filter_points(entry_points, point_in_W_ids)
	var end_points: PackedInt32Array = filter_points(exit_points, point_in_W_ids)
	
	for W_id in W_ids:
		if unconnected_interaction_matrix.unconnected_matrix[W_id].size() > 1:
			continue
		
		if unconnected_interaction_matrix.get_state_from_id(W_id) != StateLine.StateType.None:
			continue
		
		if unconnected_interaction_matrix.get_connected_particles(W_id)[0] in ParticleData.BRIGHT_PARTICLES:
			start_points.push_back(W_id)
		
		else:
			end_points.push_back(W_id)
	
	var available_points: PackedInt32Array = end_points.duplicate()
	available_points.append_array(filter_points(unconnected_interaction_matrix.get_state_ids(StateLine.StateType.None), point_in_W_ids))
	
	var unconnected_interaction_matrices : Array[InteractionMatrix] = generate_possible_paths(
		unconnected_interaction_matrix, start_points, available_points, end_points, state_points, is_W
	)
	
	if is_null_array(unconnected_interaction_matrices):
		return [null]
	
	var connected_interaction_matrices : Array[InteractionMatrix] = generate_possible_loops(
		unconnected_interaction_matrices, is_W
	)
	
	if connected_interaction_matrices.size() == 0:
		return [null]
		
	return connected_interaction_matrices

func is_null_array(array: Array) -> bool:
	return array == [null]

func generate_fermion_connections(
	unconnected_interaction_matrix: InteractionMatrix, forbidden_exit_points: Array, entry_points: PackedInt32Array,
	exit_points: PackedInt32Array, entry_states: Array
) -> Array[InteractionMatrix]:
	
	var is_fermion : Callable = func(particle:ParticleData.Particle) -> bool: return base_particle(particle) in ParticleData.FERMIONS
	
	var fermion_ids : PackedInt32Array = unconnected_interaction_matrix.find_all_unconnected(is_fermion)
	var point_in_fermion_ids : Callable = func(point:int) -> bool: return point in fermion_ids
	
	entry_points = filter_points(entry_points, point_in_fermion_ids)
	exit_points = filter_points(exit_points, point_in_fermion_ids)
	
	for entry_point:int in entry_points:
		entry_states[entry_point] = entry_states[entry_point].filter(is_fermion)
	
	var state_points: PackedInt32Array = entry_points.duplicate()
	state_points.append_array(exit_points)
	
	var available_points: PackedInt32Array = exit_points.duplicate()
	available_points.append_array(
		filter_points(unconnected_interaction_matrix.get_state_ids(StateLine.StateType.None), point_in_fermion_ids)
	)

	var unconnected_interaction_matrices : Array[InteractionMatrix] = generate_possible_state_paths(
		unconnected_interaction_matrix, forbidden_exit_points, entry_points, available_points, exit_points, state_points, is_fermion,
		entry_states
	)
	
	if is_null_array(unconnected_interaction_matrices):
		return [null]
	
	var connected_interaction_matrices : Array[InteractionMatrix] = generate_possible_loops(
		unconnected_interaction_matrices, is_fermion
	)
	
	if connected_interaction_matrices.size() == 0:
		return [null]
		
	return connected_interaction_matrices

func find_first_instance(array: Array, test_function: Callable) -> int:
	for i:int in range(array.size()):
		if test_function.call(array[i]):
			return i
	
	return array.size()

func get_first_instance(array: Array, test_function: Callable) -> ParticleData.Particle:
	for particle:ParticleData.Particle in array:
		if test_function.call(particle):
			return particle
	
	return ParticleData.Particle.none

func get_possible_next_points(
	current_point: int, particle: ParticleData.Particle, interaction_matrix: InteractionMatrix, available_points: Array,
	end_points: PackedInt32Array, state_points: PackedInt32Array, connect_uniquely: bool
) -> PackedInt32Array:
	
	var possible_next_points : PackedInt32Array = available_points.filter(
		func(point:int) -> bool:
			return (
				!(current_point in state_points and point in state_points) and
				interaction_matrix.unconnected_matrix[point].has(particle) and
				point != current_point
			)
	)
	
	if !connect_uniquely:
		return possible_next_points
	
	var unique_possible_next_points : PackedInt32Array = []
	var unique_interactions : Array = []
	
	for point:int in possible_next_points:
		if point in end_points:
			unique_possible_next_points.push_back(point)
			continue
		
		if interaction_matrix.unconnected_matrix[point] not in unique_interactions:
			unique_interactions.push_back(interaction_matrix.unconnected_matrix[point])
			unique_possible_next_points.push_back(point)
	
	return unique_possible_next_points

func generate_paths_from_point(
	current_point: int, interaction_matrix: InteractionMatrix, available_points: Array, end_points: PackedInt32Array,
	state_points: PackedInt32Array, particle_test_function: Callable, is_start_point: bool = false, connect_uniquely: bool = true,
	starting_particle: ParticleData.Particle = ParticleData.Particle.none
) -> Array[InteractionMatrix]:
	
	if current_point in end_points and !is_start_point:
		return [interaction_matrix]
	
	var current_particle : ParticleData.Particle = starting_particle if starting_particle != ParticleData.Particle.none else get_first_instance(
		interaction_matrix.unconnected_matrix[current_point], particle_test_function
	)
	
	if current_particle == ParticleData.Particle.none:
		return [null]

	var further_matrices : Array[InteractionMatrix] = []
	
	var next_possible_points := get_possible_next_points(
		current_point, current_particle, interaction_matrix, available_points, end_points, state_points, connect_uniquely
	)
	
	if next_possible_points.size() == 0:
		return [null]

	for point:int in next_possible_points:
		var new_interaction_matrix : InteractionMatrix = interaction_matrix.duplicate(true)
		new_interaction_matrix.connect_interactions(current_point, point, current_particle)

		for further_interaction_matrix in generate_paths_from_point(
			point, new_interaction_matrix, available_points.duplicate(), end_points, state_points, particle_test_function
		):
			if further_interaction_matrix == null:
				continue

			further_matrices.push_back(further_interaction_matrix)

	return further_matrices

func get_available_points(
	interaction_matrix: InteractionMatrix, current_point: int, current_particle: ParticleData.Particle, forbidden_points: PackedInt32Array
) -> PackedInt32Array:
	
	var available_points := interaction_matrix.find_all_unconnected_state_particle(current_particle, StateLine.StateType.None)
	
	if interaction_matrix.get_state_from_id(current_point) == StateLine.StateType.None:
		available_points += interaction_matrix.find_all_unconnected_state_particle(current_particle, StateLine.StateType.Both)
	
	while available_points.has(current_point):
		available_points.remove_at(available_points.find(current_point))
	
	for forbidden_point:int in forbidden_points:
		while available_points.has(forbidden_point):
			available_points.remove_at(available_points.find(forbidden_point))
	
	return available_points

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

func print_time(count: int = -1):
	if !print_times:
		return
	
	if count == -1:
		print("Time: " + str(Time.get_ticks_usec() - start_time))
	else:
		print(count, "Time: ", get_print_time())

func generate_unique_interaction_matrices(
	state_connected_matrices: Array[InteractionMatrix], degree: int, usable_interactons: Array
) -> Array[InteractionMatrix]:
	
	var generated_matrices : Array[InteractionMatrix] = []
	
	for interaction_matrix:InteractionMatrix in state_connected_matrices:
		var interaction_sets = generate_interaction_sets(
			interaction_matrix.get_unconnected_base_particles(),
			degree - interaction_matrix.state_count[StateLine.StateType.None],
			usable_interactons
		)
		
		if interaction_sets == [FAILED]:
			continue
		
		add_interaction_sets(interaction_matrix, generated_matrices, interaction_sets)
	
	var unique_matrices : Array[InteractionMatrix] = []

	for interaction_matrix:InteractionMatrix in generated_matrices:
		if unique_matrices.any(
			func(unique_matrix: InteractionMatrix) -> bool:
				return unique_matrix.is_duplicate_interaction_matrix(interaction_matrix)
		):
			continue

		unique_matrices.push_back(interaction_matrix)

	return unique_matrices

func sum(accum: int, number: int) -> int:
	return accum + number

func add_interaction_sets(
	base_interaction_matrix: InteractionMatrix, unique_matrices: Array[InteractionMatrix], interaction_sets: Array
) -> void:
	
	if interaction_sets == []:
		unique_matrices.push_back(base_interaction_matrix)
		return
	
	var unique_interaction_sets : Array = []
	
	for interaction_set:Array in interaction_sets:
		if unique_interaction_sets.any(
			func(unique_interaction_set: Array) -> bool:
				return get_shared_elements_count(interaction_set, unique_interaction_set) == interaction_set.size()
		):
			continue
		
		unique_interaction_sets.push_back(interaction_set)
	
	for interaction_set:Array in unique_interaction_sets:
		var interaction_matrix: InteractionMatrix = base_interaction_matrix.duplicate(true)
		for interaction:Array in interaction_set:
			interaction_matrix.add_unconnected_interaction(interaction)
		unique_matrices.push_back(interaction_matrix)

func generate_interaction_sets(unconnected_particles: Array, degree: int, usable_interactions: Array) -> Array:
	var interaction_sets : Array = []
	
	if degree == 0:
		return []
	
	var possible_interaction_connections := get_possible_interaction_connections(unconnected_particles, degree, usable_interactions)
	
	for connection:Array in possible_interaction_connections:
		var new_unconnected_particles : Array = add_next_interaction_connection(unconnected_particles, connection)
		var new_degree : int = degree-interaction_size(connection[INDEX.INTERACTION])
		
		if new_degree == 0 and new_unconnected_particles.size() == 0:
			interaction_sets.push_back([connection[INDEX.INTERACTION]])
			continue
		
		if new_degree == 0 and new_unconnected_particles.size() > 0:
			return [FAILED]
		
		var next_interaction_sets := generate_interaction_sets(new_unconnected_particles, new_degree, usable_interactions)
		
		if next_interaction_sets == [FAILED] or next_interaction_sets == []:
			continue
		
		for interaction_set:Array in next_interaction_sets:
			var combined_set : Array = []
			combined_set.push_back(connection[INDEX.INTERACTION])
			combined_set += interaction_set
			
			interaction_sets.push_back(combined_set)
	
	return interaction_sets

func add_next_interaction_connection(unconnected_particles: Array, interaction_connection: Array,
	interaction = interaction_connection[INDEX.INTERACTION], connection_particles = interaction_connection[INDEX.CONNECTION_PARTICLES]
) -> Array:
	unconnected_particles = get_non_shared_elements(unconnected_particles, connection_particles)
	unconnected_particles += get_non_shared_elements(interaction, connection_particles)
	
	return unconnected_particles

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
	indices: PackedInt32Array, count: int, current_index : int) -> Array[PackedInt32Array]:
	
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

func get_unique_instances(array: Array) -> Array:
	var unique_instances: Array = []
	
	for element:Variant in array:
		if !element in unique_instances:
			unique_instances.append(element)
	
	return unique_instances

func get_possible_hadron_connections(interaction_matrix: InteractionMatrix, same_hadron_particles: Array) -> Array:
	var unique_same_hadron_particles := get_unique_instances(same_hadron_particles)
	var possible_hadron_connections : Array = []
	
	for particle:ParticleData.Particle in unique_same_hadron_particles:
		var connect_from_ids: PackedInt32Array = []
		var connect_to_ids: PackedInt32Array = []
		for state:StateLine.StateType in states:
			for id:int in interaction_matrix.find_all_unconnected_state_particle(particle, state):
				if !interaction_matrix.is_hadron(id):
					continue
				if sign(particle) * state_factor[state] > 0:
					connect_from_ids.push_back(id)
				else:
					connect_to_ids.push_back(id)
		
		for connect_from_id in connect_from_ids:
			for connect_to_id in connect_to_ids:
				if (
					possible_hadron_connections.count([connect_from_id, connect_to_id, particle]) >=
					interaction_matrix.unconnected_matrix[connect_from_id].count(particle)
				):
					continue
				elif (
					possible_hadron_connections.count([connect_from_id, connect_to_id, particle]) >=
					interaction_matrix.unconnected_matrix[connect_to_id].count(particle)
				):
					continue
				possible_hadron_connections.append([connect_from_id, connect_to_id, particle])

	return possible_hadron_connections

func get_possible_hadron_connection_count(
	unconnected_state_particle_count: int, same_hadron_particles_count: int, degree: int
) -> Array:
	
	if same_hadron_particles_count == 0:
		return [0]
	
	var possible_hadron_connection_count := range(
		max(ceil((unconnected_state_particle_count - INTERACTION_SIZE*degree)/2), 0),
		same_hadron_particles_count + 1
	)
	
	possible_hadron_connection_count.sort()
	possible_hadron_connection_count.reverse()
	
	return possible_hadron_connection_count

func choose_random(array: Array, choose_count: int = 1) -> Array:
	if array.size() == 0:
		push_error("Choose random array is size 0")
	
	var chosen_random := []
	var random_start_index := randi() % array.size()
	
	for i:int in choose_count:
		chosen_random.append(array[random_start_index - i])
	
	return chosen_random

func get_possible_interaction_connections(
	unconnected_particles: Array, interaction_count: int, usable_interactions: Array
) -> Array:
	var possible_interaction_connections := []

	for interaction:Array in usable_interactions:
		var shared_particles := get_shared_elements(interaction, unconnected_particles)

		if shared_particles.size() == 0:
			continue

		for connection_number:int in range(1, shared_particles.size()+1):
			if is_connection_number_possible(
				unconnected_particles.size() + interaction.size() - 2*connection_number,
				interaction_count - interaction_size(interaction)
			):
				for connection_particles:Array in get_permutations(shared_particles, connection_number):
					possible_interaction_connections.append([interaction, connection_particles])

	return possible_interaction_connections

func interaction_size(interaction: Array) -> int:
	return 1 + int(interaction.size() == 4)

func is_interaction_possible(
	interaction: Array, unconnected_particles: Array, interaction_count: int
) -> bool:
	
	var remaining_unconnected_particles_count := get_non_shared_elements(interaction, unconnected_particles).size()
	
	if remaining_unconnected_particles_count == unconnected_particles.size():
		return false
	
	return is_connection_number_possible(remaining_unconnected_particles_count, interaction_count - interaction_size(interaction))

func is_connection_number_possible(unconnected_particle_count : int, interaction_count : int) -> bool:
	if interaction_count == 1:
		return unconnected_particle_count == INTERACTION_SIZE

	return unconnected_particle_count <= interaction_count * INTERACTION_SIZE

func compare_quantum_numbers(initial_state : Array, final_state : Array) -> int:
	for quantum_number in range(ParticleData.QuantumNumber.size()):
		if !is_equal_approx(calculate_quantum_sum(quantum_number, initial_state), calculate_quantum_sum(quantum_number, final_state)):
			if (
				quantum_number == ParticleData.QuantumNumber.charge or
				quantum_number == ParticleData.QuantumNumber.lepton or 
				quantum_number == ParticleData.QuantumNumber.quark
			):
				return INVALID
	
	return VALID

func calculate_quantum_sum(quantum_number: ParticleData.QuantumNumber, state_interactions: Array) -> float:
	var quantum_sum: float = 0
	for state_interaction in state_interactions:
		for particle:ParticleData.Particle in state_interaction:
			quantum_sum += sign(particle) * ParticleData.QUANTUM_NUMBERS[base_particle(particle)][quantum_number]
	return quantum_sum

func is_anti(particle: ParticleData.Particle) -> bool:
	return particle < 0

func base_particle(particle: ParticleData.Particle) -> ParticleData.Particle:
	return abs(particle)

func print_matrix(matrix : Array) -> void:
	print('Printing Matrix')
	for interaction:Array in matrix:
		print(interaction)
