extends Node

enum INTERACTION_TYPE {electroweak, strong, higgs, weak}
enum Shade {Bright, Dark, None}

const SHADED_PARTICLES := [GLOBALS.BRIGHT_PARTICLES, GLOBALS.DARK_PARTICLES, GLOBALS.SHADED_PARTICLES]
const INTERACTION_SIZE = 3.0

var INTERACTIONS := GLOBALS.INTERACTIONS
var TOTAL_INTERACTIONS : Array

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
	var number_of_state_particles := interaction_matrix.get_unconnected_particle_count(StateLine.StateType.Both)

	var number_of_unconnectable_particles: int = (
		number_of_state_particles - initial_hadron_particles.size() - final_hadron_particles.size() +
		get_non_shared_elements(initial_hadron_particles, final_hadron_particles).size()
	)

	min_degree = max(floor(number_of_unconnectable_particles/3.0)+1, min_degree)
	
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
		func(particle):
			return (
				(sign(particle) * GLOBALS.GENERAL_CONVERSION[base_particle(particle)])
				if base_particle(particle) not in GLOBALS.GENERAL_PARTICLES else particle
			)
	)

func convert_interactions_to_general(interactions: Array) -> Array:
	var converted_interactions : Array = interactions.map(convert_interaction_to_general)
	
	var general_interactions : Array = []
	for interaction in converted_interactions:
		if interaction not in general_interactions:
			general_interactions.push_back(interaction)

	return general_interactions

func generate_diagrams(
	initial_state: Array, final_state: Array, min_degree: int, max_degree: int, usable_interactions: Array, find_all: bool = false
) -> Array[ConnectionMatrix]:
	
	start_time = Time.get_ticks_usec()
	var print_results : bool = true
	
	if compare_quantum_numbers(initial_state, final_state) == INVALID:
		print('Initial state quantum numbers do not match final state')
		return [null]
	
	var general_usable_interactions := convert_interactions_to_general(usable_interactions)
	
	var base_interaction_matrix := create_base_interaction_matrix(initial_state, final_state)

	var same_hadron_particles := get_shared_elements(get_hadron_particles(initial_state), get_hadron_particles(final_state))
	var possible_hadron_connections := get_possible_hadron_connections(base_interaction_matrix, same_hadron_particles)

	var degrees_to_check = get_degrees_to_check(
		min_degree, max_degree, base_interaction_matrix, usable_interactions
	)

	var generated_connection_matrices : Array[ConnectionMatrix] = []

	for degree in degrees_to_check:
		if print_results:
			print("degree: " + str(degree) + " " + get_print_time())

		var possible_hadron_connection_count := get_possible_hadron_connection_count(
			base_interaction_matrix.get_unconnected_particle_count(StateLine.StateType.Both),
			same_hadron_particles.size(), degree
		)
		
		var unique_interaction_matrices : Array[InteractionMatrix] = generate_unique_interaction_matrices(
			base_interaction_matrix, degree, possible_hadron_connections, possible_hadron_connection_count, general_usable_interactions
		)
		
		print_time(0)
	
		for interaction_matrix in unique_interaction_matrices:
			generated_connection_matrices += generate_unique_connection_matrices(interaction_matrix)

	if generated_connection_matrices.size() == 0:
		if print_results:
			print('Generation failed')

		return [null]
	
	print("Generation Completed: " + get_print_time())

	return generated_connection_matrices

func get_print_time() -> String:
	return "time: " + str(Time.get_ticks_usec() - start_time) + " usec"

func is_connection_matrix_unique(connection_matrix: ConnectionMatrix, connection_matrices: Array[ConnectionMatrix]) -> bool:
	return !connection_matrices.any(func(matrix: ConnectionMatrix): return matrix.is_duplicate(connection_matrix))

func generate_unique_connection_matrices(unconnected_interaction_matrix: InteractionMatrix) -> Array[ConnectionMatrix]:
	var connected_matrices: Array[ConnectionMatrix] = connect_interaction_matrix(unconnected_interaction_matrix)
	
	print_time(4)
	var unique_connected_matrices : Array[ConnectionMatrix] = []
	
	print_time(5)
	
	for connected_matrix in connected_matrices:
		connected_matrix.reindex()
	
	print_time(6)
	
	for connection_matrix in connected_matrices:
		if unique_connected_matrices.any(
			func(matrix: ConnectionMatrix): return matrix.is_duplicate(connection_matrix)
		):
			continue
		
		unique_connected_matrices.push_back(connection_matrix)
	
	print_time(7)
	
	return unique_connected_matrices

func connect_interaction_matrix(unconnected_interaction_matrix: InteractionMatrix) -> Array[ConnectionMatrix]:
	return combine_connection_matrices(
		generate_directional_connections(unconnected_interaction_matrix).map(
			func(matrix: InteractionMatrix): return matrix.get_connection_matrix()
		),
		generate_directionless_connections(unconnected_interaction_matrix).map(
			func(matrix: InteractionMatrix): return matrix.get_connection_matrix()
		)
	).filter(
		func(matrix: ConnectionMatrix): return matrix.is_fully_connected(true)
	)

func combine_connection_matrices(base_connection_matrices: Array, combining_connection_matrices: Array) -> Array[ConnectionMatrix]:
	print_time(3)
	
	var combined_connection_matrices: Array[ConnectionMatrix] = []
	
	if base_connection_matrices.size() == 0:
		return combining_connection_matrices
	elif combining_connection_matrices.size() == 0:
		return base_connection_matrices
	
	for base_connection_matrix in base_connection_matrices:
		for combining_connection_matrix in combining_connection_matrices:
			var combined_matrix : ConnectionMatrix = base_connection_matrix.duplicate()
			combined_matrix.combine_matrix(combining_connection_matrix)
			combined_connection_matrices.push_back(combined_matrix)
	
	print_time()
	return combined_connection_matrices

func connect_directionless_particles(interaction_matrix: InteractionMatrix) -> int:
	for connect_from_id in range(interaction_matrix.unconnected_matrix.size()):
		for particle in interaction_matrix.unconnected_matrix[connect_from_id]:
			var available_points := get_available_points(interaction_matrix, connect_from_id, particle, [])
			
			if available_points.size() == 0:
				return FAILED
			
			var connect_to_id : int = choose_random(available_points)[0]
			interaction_matrix.connect_interactions(connect_from_id, connect_to_id, particle)

	return SUCCEEDED

func get_loop_points(interaction_matrix: InteractionMatrix) -> PackedInt32Array:
	return interaction_matrix.find_all_unconnected(func(particle): return particle in GLOBALS.FERMIONS)

func generate_directionless_connections(unconnected_interaction_matrix: InteractionMatrix) -> Array[InteractionMatrix]:
	print_time(2)
	
	var has_directionless_particles: bool = unconnected_interaction_matrix.get_unconnected_base_particles().any(
		func(particle): return particle not in GLOBALS.SHADED_PARTICLES
	)
	
	if !has_directionless_particles:
		return []
	
	var is_directionless_particle: Callable = func(particle): return particle not in GLOBALS.SHADED_PARTICLES
	
	var directionless_particle_count := unconnected_interaction_matrix.get_unconnected_particles().filter(is_directionless_particle).size()
	var directionless_ids := unconnected_interaction_matrix.find_all_unconnected(is_directionless_particle)
	var point_in_directionless_ids : Callable = func(point): return point in directionless_ids
	
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
				start_point, matrix.duplicate(), directionless_ids, directionless_ids, state_points, is_directionless_particle,
				true, false
			):
				if further_matrix == null:
					continue

				unconnected_interaction_matrices.push_back(further_matrix)
	
	return unconnected_interaction_matrices

func generate_directional_connections(unconnected_interaction_matrix: InteractionMatrix) -> Array[InteractionMatrix]:
	print_time(1)
	
	var has_directional_particles : bool = unconnected_interaction_matrix.get_unconnected_base_particles().any(
		func(particle): return particle in GLOBALS.SHADED_PARTICLES
	)
	
	if !has_directional_particles:
		return []
	
	var entry_points : Array = unconnected_interaction_matrix.get_entry_points()
	var exit_points : Array = unconnected_interaction_matrix.get_exit_points()
	
	unconnected_interaction_matrix.reduce_to_base_particles()

	var fermion_connected_matrices := generate_fermion_connections(unconnected_interaction_matrix, entry_points, exit_points)
	
	var connected_matrices: Array[InteractionMatrix] = []
	
	for fermion_connected_matrix in fermion_connected_matrices:
		connected_matrices += generate_W_connections(fermion_connected_matrix, entry_points, exit_points)
	
	return connected_matrices

func generate_possible_paths(
	interaction_matrix: InteractionMatrix, start_points: PackedInt32Array, available_points: PackedInt32Array, end_points: PackedInt32Array,
	state_points: PackedInt32Array, particle_test_function: Callable
) -> Array[InteractionMatrix]:
	
	var connected_interaction_matrices : Array[InteractionMatrix] = [interaction_matrix]
	
	for start_point in start_points:
		if connected_interaction_matrices.size() == 0:
			return [null]
		
		var iteration_matrices : Array[InteractionMatrix] = connected_interaction_matrices
		connected_interaction_matrices = []
		
		for matrix in iteration_matrices:
			for further_matrix in generate_paths_from_point(
				start_point, matrix.duplicate(), available_points, end_points, state_points, particle_test_function, true
			):
				if further_matrix == null:
					continue

				connected_interaction_matrices.push_back(further_matrix)
	
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
				loop_point, matrix.duplicate(), matrix.get_state_ids(StateLine.StateType.None), [loop_point], [],
				particle_test_function, true
			):
				if further_matrix == null:
					continue

				interaction_matrices.push_back(further_matrix)
	
	return connected_interaction_matrices

func filter_points(points: PackedInt32Array, test_function: Callable) -> PackedInt32Array:
	var filtered_points: PackedInt32Array = []
	
	for point in points:
		if test_function.call(point):
			filtered_points.push_back(point)
	
	return filtered_points

func generate_W_connections(
	unconnected_interaction_matrix: InteractionMatrix, entry_points: PackedInt32Array, exit_points: PackedInt32Array
) -> Array[InteractionMatrix]:
	var is_W : Callable = func(particle): return particle == GLOBALS.Particle.W
	
	var W_ids : PackedInt32Array = unconnected_interaction_matrix.find_all_unconnected(is_W)
	var point_in_W_ids : Callable = func(point): return point in W_ids
	
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
		
		if unconnected_interaction_matrix.get_connected_particles(W_id)[0] in GLOBALS.BRIGHT_PARTICLES:
			start_points.push_back(W_id)
		
		else:
			end_points.push_back(W_id)
	
	var available_points: PackedInt32Array = end_points.duplicate()
	available_points.append_array(filter_points(unconnected_interaction_matrix.get_state_ids(StateLine.StateType.None), point_in_W_ids))
	
	var unconnected_interaction_matrices : Array[InteractionMatrix] = generate_possible_paths(
		unconnected_interaction_matrix, start_points, available_points, end_points, state_points, is_W
	)
	
	var connected_interaction_matrices : Array[InteractionMatrix] = generate_possible_loops(
		unconnected_interaction_matrices, is_W
	)
	
	if connected_interaction_matrices.size() == 0:
		return [null]
		
	return connected_interaction_matrices

func generate_fermion_connections(
	unconnected_interaction_matrix: InteractionMatrix, entry_points: PackedInt32Array, exit_points: PackedInt32Array
) -> Array[InteractionMatrix]:
	
	var is_fermion : Callable = func(particle): return particle in GLOBALS.FERMIONS
	
	var fermion_ids : PackedInt32Array = unconnected_interaction_matrix.find_all_unconnected(is_fermion)
	var point_in_fermion_ids : Callable = func(point): return point in fermion_ids
	
	entry_points = filter_points(entry_points, point_in_fermion_ids)
	exit_points = filter_points(exit_points, point_in_fermion_ids)
	
	var state_points: PackedInt32Array = entry_points.duplicate()
	state_points.append_array(exit_points)
	
	var start_points: PackedInt32Array = entry_points.duplicate()
	var end_points: PackedInt32Array = exit_points.duplicate()
	var available_points: PackedInt32Array = end_points.duplicate()
	available_points.append_array(
		filter_points(unconnected_interaction_matrix.get_state_ids(StateLine.StateType.None), point_in_fermion_ids)
	)

	var unconnected_interaction_matrices : Array[InteractionMatrix] = generate_possible_paths(
		unconnected_interaction_matrix, start_points, available_points, end_points, state_points, is_fermion
	)
	
	var connected_interaction_matrices : Array[InteractionMatrix] = generate_possible_loops(
		unconnected_interaction_matrices, is_fermion
	)
	
	if connected_interaction_matrices.size() == 0:
		return [null]
		
	return connected_interaction_matrices

func connect_directional_particles(
	interaction_matrix: InteractionMatrix, initial_shade_start_points: Array[PackedInt32Array], forbidden_points: PackedInt32Array
) -> int:
	
	if initial_shade_start_points.any(func(start_points): return start_points.size() > 0):
		var path_connection_failed : bool = connect_paths(interaction_matrix, initial_shade_start_points, forbidden_points) == FAILED
		
		if path_connection_failed:
			return FAILED

	var unconnected_directional_particles := interaction_matrix.get_unconnected_base_particles().filter(
		func(particle): return particle in GLOBALS.SHADED_PARTICLES
	)

	if unconnected_directional_particles.size() != 0:
		var loop_connection_failed : bool = connect_loops(interaction_matrix, unconnected_directional_particles, forbidden_points) == FAILED

		if loop_connection_failed:
			return FAILED

	return SUCCEEDED

func find_first_instance(array: Array, test_function: Callable) -> int:
	for i in range(array.size()):
		if test_function.call(array[i]):
			return i
	
	return array.size()

func get_first_instance(array: Array, test_function: Callable) -> GLOBALS.Particle:
	for particle in array:
		if test_function.call(particle):
			return particle
	
	return GLOBALS.Particle.none

func get_possible_next_points(
	current_point: int, particle: GLOBALS.Particle, interaction_matrix: InteractionMatrix, available_points: Array,
	end_points: PackedInt32Array, state_points: PackedInt32Array, connect_uniquely: bool
) -> PackedInt32Array:
	
	var possible_next_points : PackedInt32Array = available_points.filter(
		func(point):
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
	
	for point in possible_next_points:
		if point in end_points:
			unique_possible_next_points.push_back(point)
			continue
		
		if interaction_matrix.unconnected_matrix[point] not in unique_interactions:
			unique_interactions.push_back(interaction_matrix.unconnected_matrix[point])
			unique_possible_next_points.push_back(point)
	
	return unique_possible_next_points

func generate_paths_from_point(
	current_point: int, interaction_matrix: InteractionMatrix, available_points: Array, end_points: PackedInt32Array,
	state_points: PackedInt32Array, particle_test_function: Callable, is_start_point: bool = false,
	connect_uniquely: bool = true
) -> Array[InteractionMatrix]:
	
	if current_point in end_points and !is_start_point:
		return [interaction_matrix]
	
	var current_particle : GLOBALS.Particle = get_first_instance(
		interaction_matrix.unconnected_matrix[current_point], particle_test_function
	)
	
	if current_particle == GLOBALS.Particle.none:
		return [null]

	var further_matrices : Array[InteractionMatrix] = []
	
	var next_possible_points := get_possible_next_points(
		current_point, current_particle, interaction_matrix, available_points, end_points, state_points, connect_uniquely
	)
	
	if next_possible_points.size() == 0:
		return [null]

	for point in next_possible_points:
		var new_interaction_matrix : InteractionMatrix = interaction_matrix.duplicate()
		new_interaction_matrix.connect_interactions(current_point, point, current_particle)

		for further_interaction_matrix in generate_paths_from_point(
			point, new_interaction_matrix, available_points.duplicate(), end_points, state_points, particle_test_function
		):
			if further_interaction_matrix == null:
				continue

			further_matrices.push_back(further_interaction_matrix)

	return further_matrices

func connect_loops(interaction_matrix: InteractionMatrix, unconnected_directional_particles: Array,
	forbidden_points: PackedInt32Array
) -> int:
	
	var loop_start_points : PackedInt32Array = []
	var no_shade_start_points : bool = false
	
	for rotation_count in range(MAX_SHADE_CONNECTION_ROTATIONS):
		for shade in shades:
			loop_start_points += get_initial_shade_loop_points(interaction_matrix, shade)
			
			if loop_start_points.size() == 0:
				if no_shade_start_points:
					return SUCCEEDED
				
				no_shade_start_points = true
				continue
			
			no_shade_start_points = false
				
			loop_start_points = connect_shade_loops(interaction_matrix, loop_start_points, shade)
			
			var connection_failed = CONNECTION_FAILED in loop_start_points
			if connection_failed:
				return FAILED
	
	return SUCCEEDED

func connect_paths(interaction_matrix: InteractionMatrix, initial_shade_start_points: Array[PackedInt32Array],
	forbidden_points: PackedInt32Array
) -> int:
	
	var path_start_points : PackedInt32Array = []
	
	for rotation_count in range(MAX_SHADE_CONNECTION_ROTATIONS):
		for shade in shades:
			if rotation_count == 0:
				path_start_points += initial_shade_start_points[shade]
			else:
				forbidden_points += path_start_points
				
			if path_start_points.size() == 0:
				continue
				
			path_start_points = connect_shade_paths(interaction_matrix, path_start_points, shade, forbidden_points)
			
			if path_start_points.size() == 0:
				break
			
			var connection_failed = CONNECTION_FAILED in path_start_points
			if connection_failed:
				return FAILED
			
		if path_start_points.size() == 0:
			break

	return SUCCEEDED

func get_initial_shade_loop_points(interaction_matrix: InteractionMatrix, shade: Shade) -> PackedInt32Array:
	var initial_loop_points : PackedInt32Array = []
	
	for id in interaction_matrix.get_state_ids(StateLine.StateType.None):
		if interaction_matrix.unconnected_matrix[id].any(func(particle): return particle in SHADED_PARTICLES[shade]):
			initial_loop_points.append(id)
	
	return initial_loop_points
	
func connect_shade_loops(interaction_matrix: InteractionMatrix, start_points: PackedInt32Array, shade: Shade) -> PackedInt32Array:
	
	var next_start_points : PackedInt32Array = []
	
	for start_point in start_points:
		if !interaction_matrix.unconnected_matrix[start_point].any(func(particle): return particle in SHADED_PARTICLES[shade]):
			continue
		
		next_start_points += connect_shade_path(interaction_matrix, start_point, shade, [])
		if next_start_points == PackedInt32Array([CONNECTION_FAILED]):
			return PackedInt32Array([CONNECTION_FAILED])
	
	return next_start_points

func connect_shade_paths(
	interaction_matrix: InteractionMatrix, start_points: PackedInt32Array, shade : Shade, forbidden_points : PackedInt32Array
) -> PackedInt32Array:
	
	var next_start_points : PackedInt32Array = []
	
	for start_point in start_points:
		next_start_points += connect_shade_path(interaction_matrix, start_point, shade, forbidden_points)
		if next_start_points == PackedInt32Array([CONNECTION_FAILED]):
			return PackedInt32Array([CONNECTION_FAILED])
	
	return next_start_points

func connect_shade_path(
	interaction_matrix: InteractionMatrix, start_point: int, shade : Shade, forbidden_points : PackedInt32Array
) -> PackedInt32Array:
	var extra_start_points : PackedInt32Array = []
	var current_point := start_point
	var current_particle : GLOBALS.Particle = GLOBALS.Particle.none
	
	for _step in range(MAX_PATH_STEPS):
		var next_particle = choose_random_shade_particle(interaction_matrix, current_point, shade)
		
		if (
			next_particle == GLOBALS.Particle.W and
			current_particle != GLOBALS.Particle.W and
			interaction_matrix.get_state_from_id(current_point) == StateLine.StateType.None
		):
			extra_start_points.append(current_point)
		
		current_particle = next_particle
		var available_points := get_available_points(interaction_matrix, current_point, current_particle, forbidden_points)
		
		if available_points.size() == 0:
			return [CONNECTION_FAILED]
		
		var next_point : int = choose_random(available_points)[0]
		
		connect_shade_points(interaction_matrix, current_point, next_point, current_particle, shade)
		
		current_point = next_point
		
		if is_path_finished(interaction_matrix, current_point, shade):
			break
	
	return extra_start_points

func is_path_finished(interaction_matrix: InteractionMatrix, current_point: int, shade: Shade) -> bool:
	if interaction_matrix.get_state_from_id(current_point) != StateLine.StateType.None:
		return true
	
	if interaction_matrix.unconnected_matrix[current_point].size() == 0:
		return true
	
	for particle in interaction_matrix.unconnected_matrix[current_point]:
		if particle in SHADED_PARTICLES[shade]:
			return false
	
	return true

func connect_shade_points(
	interaction_matrix: InteractionMatrix, current_point: int, next_point: int, current_particle: GLOBALS.Particle, shade: Shade
) -> void:
	
	if current_particle != GLOBALS.Particle.W:
		interaction_matrix.connect_interactions(current_point, next_point, current_particle)
		return
	
	match shade:
		Shade.Dark:
			interaction_matrix.connect_interactions(current_point, next_point, current_particle)
		Shade.Bright:
			interaction_matrix.connect_interactions(next_point, current_point, current_particle)

func get_available_points(
	interaction_matrix: InteractionMatrix, current_point: int, current_particle: GLOBALS.Particle, forbidden_points: PackedInt32Array
) -> PackedInt32Array:
	
	var available_points := interaction_matrix.find_all_unconnected_state_particle(current_particle, StateLine.StateType.None)
	
	if interaction_matrix.get_state_from_id(current_point) == StateLine.StateType.None:
		available_points += interaction_matrix.find_all_unconnected_state_particle(current_particle, StateLine.StateType.Both)
	
	while available_points.has(current_point):
		available_points.remove_at(available_points.find(current_point))
	
	for forbidden_point in forbidden_points:
		while available_points.has(forbidden_point):
			available_points.remove_at(available_points.find(forbidden_point))
	
	return available_points

func choose_random_shade_particle(interaction_matrix: InteractionMatrix, id: int, shade: Shade) -> GLOBALS.Particle:
	return choose_random(interaction_matrix.unconnected_matrix[id].filter(func(particle): return particle in SHADED_PARTICLES[shade]))[0]

func get_shade_start_points(interaction_matrix: InteractionMatrix, shade: Shade) -> PackedInt32Array:
	var start_points : PackedInt32Array = []
	
	for i in range(interaction_matrix.get_state_count(StateLine.StateType.Both)):
		for particle in interaction_matrix.unconnected_matrix[i]:
			if (
				(base_particle(particle) == GLOBALS.Particle.W and shade_factor[shade] == sign(particle)) or
				(base_particle(particle) != GLOBALS.Particle.W and base_particle(particle) not in SHADED_PARTICLES[shade])
			):
				continue
			
			if state_factor[interaction_matrix.get_state_from_id(i)] * particle >= 0:
				start_points.append(i)
			
	return start_points

func get_usable_interactions(interaction_checks: Array[bool]) -> Array:
	var usable_interactions : Array = []
	
	for interaction_type_count in range(GLOBALS.INTERACTIONS.size()):
		if interaction_checks[interaction_type_count]:
			usable_interactions += GLOBALS.INTERACTIONS[interaction_type_count]
	
	return usable_interactions

func get_non_shared_elements(array1: Array, array2: Array) -> Array:
	
	var non_shared : Array = []
	var array1_copy : Array = array1.duplicate()
	var array2_copy : Array = array2.duplicate()
	
	for element in array1:
		if element not in array2_copy:
			non_shared.append(element)
		else:
			array1_copy.erase(element)
			array2_copy.erase(element)
	
	for element in array2_copy:
		if element not in array1_copy:
			non_shared.append(element)
		else:
			array1_copy.erase(element)
	
	return non_shared

func get_shared_elements(array1 : Array, array2 : Array) -> Array:
	var shared_elements: Array = []
	
	for element in array2:
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
	
	for element in array1:
		if element in array2:
			shared_array1_count += 1
	
	for element in array2:
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
	base_interaction_matrix: InteractionMatrix, degree: int, possible_hadron_connections: Array,
	possible_hadron_connection_count: Array, usable_interactons: Array
) -> Array[InteractionMatrix]:
	
	var generated_matrices : Array[InteractionMatrix] = []
	
	for connection_count in possible_hadron_connection_count:
		var hadron_connection_permutations : Array = get_permutations(possible_hadron_connections, connection_count)
		
		for hadron_connection_permutation in hadron_connection_permutations:
			var interaction_matrix : InteractionMatrix = base_interaction_matrix.duplicate()
			
			for hadron_connection in hadron_connection_permutation:
				interaction_matrix.insert_connection(hadron_connection)
			
			interaction_matrix.unconnected_matrix = interaction_matrix.unconnected_matrix.map(convert_interaction_to_general)
			
			var interaction_sets = generate_interaction_sets(
				interaction_matrix.get_unconnected_base_particles(), degree, usable_interactons
			)
			
			if interaction_sets == [FAILED]:
				continue
			
			add_interaction_sets(interaction_matrix, generated_matrices, interaction_sets)
	
	var unique_matrices : Array[InteractionMatrix] = []
	
	for interaction_matrix in generated_matrices:
		if unique_matrices.any(
			func(unique_matrix: InteractionMatrix): return unique_matrix.has_same_unconnected_matrix(interaction_matrix)
		):
			continue
		
		unique_matrices.push_back(interaction_matrix)

	return unique_matrices

func sum(accum: int, number: int) -> int:
	return accum + number

func add_interaction_sets(
	base_interaction_matrix: InteractionMatrix, unique_matrices: Array[InteractionMatrix], interaction_sets: Array
) -> void:
	
	var unique_interaction_sets : Array = []
	
	for interaction_set in interaction_sets:
		if unique_interaction_sets.any(
			func(
				unique_interaction_set: Array
			): return get_shared_elements_count(interaction_set, unique_interaction_set) == interaction_set.size()
		):
			continue
		
		unique_interaction_sets.push_back(interaction_set)
	
	for interaction_set in unique_interaction_sets:
		var interaction_matrix : InteractionMatrix = base_interaction_matrix.duplicate()
		for interaction in interaction_set:
			interaction_matrix.add_unconnected_interaction(interaction)
		unique_matrices.push_back(interaction_matrix)

func generate_interaction_sets(unconnected_particles: Array, degree: int, usable_interactions: Array) -> Array:
	var interaction_sets : Array = []
	
	for interaction_connection in get_possible_interaction_connections(unconnected_particles, degree, usable_interactions):
		var new_unconnected_particles : Array = add_next_interaction_connection(unconnected_particles, interaction_connection)
		var new_degree : int = degree-interaction_size(interaction_connection[INDEX.INTERACTION])
		
		if new_degree == 0 and new_unconnected_particles.size() == 0:
			interaction_sets.push_back([interaction_connection[INDEX.INTERACTION]])
			continue
		
		if new_degree == 0 and new_unconnected_particles.size() > 0:
			return [FAILED]
		
		var next_interaction_sets := generate_interaction_sets(new_unconnected_particles, new_degree, usable_interactions)
		
		if next_interaction_sets == [FAILED] or next_interaction_sets == []:
			continue
		
		for interaction_set in next_interaction_sets:
			var combined_set : Array = []
			combined_set.push_back(interaction_connection[INDEX.INTERACTION])
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
	for i in range(index_permutations.size()):
		permutations.push_back([])
		for index in index_permutations[i]:
			permutations[i].push_back(array[index])
	
	var unique_permutations : Array = []
	for i in range(permutations.size()):
		if permutations[i] not in unique_permutations:
			unique_permutations.push_back(permutations[i])
	
	return unique_permutations

func get_index_permutations(indices: PackedInt32Array, count: int) -> Array[PackedInt32Array]:
	var permutations : Array[PackedInt32Array] = []
	
	for index in indices:
		permutations += get_index_permutations_from_index(indices.duplicate(), count, index)
	
	var unique_permutations : Array[PackedInt32Array] = []
	for i in range(permutations.size()):
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
	
	for index in indices:
		var index_permutations: Array[PackedInt32Array] = get_index_permutations_from_index(indices.duplicate(), count, index)
		for permutation in index_permutations:
			var permutation_from_current_index : PackedInt32Array = [current_index]
			permutation_from_current_index.append_array(permutation)
			
			permutations_from_current_index.push_back(permutation_from_current_index)
	
	return permutations_from_current_index

func get_unique_instances(array: Array) -> Array:
	var unique_instances: Array = []
	
	for element in array:
		if !element in unique_instances:
			unique_instances.append(element)
	
	return unique_instances

func get_possible_hadron_connections(interaction_matrix: InteractionMatrix, same_hadron_particles: Array) -> Array:
	var unique_same_hadron_particles := get_unique_instances(same_hadron_particles)
	var possible_hadron_connections : Array = []
	
	for particle in unique_same_hadron_particles:
		var connect_from_ids: PackedInt32Array = []
		var connect_to_ids: PackedInt32Array = []
		for state in states:
			for id in interaction_matrix.find_all_unconnected_state_particle(particle, state):
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
				
				possible_hadron_connections.append([connect_from_id, connect_to_id, particle])

	return possible_hadron_connections

func get_possible_hadron_connection_count(
	unconnected_state_particle_count: int, same_hadron_particles_count: int, degree: int
) -> Array:
	
	if same_hadron_particles_count == 0:
		return [0]
	
	var possible_hadron_connection_count := range(
		max(ceil((unconnected_state_particle_count - INTERACTION_SIZE*degree)/2), 0),
		same_hadron_particles_count
	)
	
	possible_hadron_connection_count.shuffle()
	
	return possible_hadron_connection_count

func choose_random(array: Array, choose_count: int = 1) -> Array:
	if array.size() == 0:
		push_error("Choose random array is size 0")
	
	var chosen_random := []
	var random_start_index := randi() % array.size()
	
	for i in choose_count:
		chosen_random.append(array[random_start_index - i])
	
	return chosen_random

func get_possible_interaction_connections(
	unconnected_particles: Array, interaction_count: int, usable_interactions: Array
) -> Array:
	var possible_interaction_connections := []

	for interaction in usable_interactions:
		var shared_particles := get_shared_elements(interaction, unconnected_particles)

		if shared_particles.size() == 0:
			continue

		for connection_number in range(1, shared_particles.size()+1):
			if is_connection_number_possible(
				unconnected_particles.size() + interaction.size() - 2*connection_number,
				interaction_count - interaction_size(interaction)
			):
				for connection_particles in get_permutations(shared_particles, connection_number):
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
	for quantum_number in range(GLOBALS.QuantumNumber.size()):
		if !is_equal_approx(calculate_quantum_sum(quantum_number, initial_state), calculate_quantum_sum(quantum_number, final_state)):
			if (
				quantum_number == GLOBALS.QuantumNumber.charge or
				quantum_number == GLOBALS.QuantumNumber.lepton or 
				quantum_number == GLOBALS.QuantumNumber.quark
			):
				return INVALID
	
	return VALID

func calculate_quantum_sum(quantum_number: GLOBALS.QuantumNumber, state_interactions: Array) -> float:
	var quantum_sum: float = 0
	for state_interaction in state_interactions:
		for particle in state_interaction:
			quantum_sum += sign(particle) * GLOBALS.QUANTUM_NUMBERS[base_particle(particle)][quantum_number]
	return quantum_sum

func is_anti(particle) -> bool:
	return particle < 0.0

func base_particle(particle) -> GLOBALS.Particle:
	return abs(particle)

func print_matrix(matrix : Array) -> void:
	print('Printing Matrix')
	for interaction in matrix:
		print(interaction)
