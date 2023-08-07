extends Node

enum INTERACTION_TYPE {electroweak, strong, higgs, weak}

enum Shade {Bright, Dark, None}

const SHADED_PARTICLES := [GLOBALS.BRIGHT_PARTICLES, GLOBALS.DARK_PARTICLES, GLOBALS.DIRECTIONAL_PARTICLES]

const INTERACTION_SIZE = 3.0

var INTERACTIONS := GLOBALS.INTERACTIONS
var TOTAL_INTERACTIONS : Array

signal draw_diagram

enum INDEX {unconnected, connected, ID = 0, TYPE, START = 0, END, INTERACTION = 0, CONNECTION_COUNT}
enum {
	INVALID, VALID,
	FAILED, SUCCEEDED,
	ATTEMPTS_PER_DEGREE = 10,
	UNIQUE_GENERATION_ATTEMPTS = 100, UNIQUE_GENERATION_FAILED,
	INTERACTION_MATRIX_GENERATION_ATTEMPTS = 10, INTERACTION_GENERATION_FAILED,
	CONNECTION_ATTEMPTS = 100, CONNECTION_FAILED,
	MAX_PATH_STEPS = 100,
	MAX_SHADE_CONNECTION_ROTATIONS = 100
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

var generated_matrix: InteractionMatrix

func _ready() -> void:
	await get_tree().create_timer(1).timeout
	
	var diagram := generate_diagram(
		[[GLOBALS.Particle.gluon], [GLOBALS.Particle.gluon]], [[GLOBALS.Particle.H]], 3, 3,
		 get_usable_interactions([true, true, true, true])
	)
	
	emit_signal('draw_diagram', diagram)
	
func _generation_button_pressed(
	initial_state: Array, final_state: Array, minDegree: int, maxDegree: int, interaction_checks: Array[bool]
) -> void:
	var diagram := generate_diagram(initial_state, final_state, minDegree, maxDegree, get_usable_interactions(interaction_checks))
	
	emit_signal('draw_diagram', diagram)

func init(GenerationButton: Control) -> void:
	GenerationButton.connect("generate", Callable(self, "_generation_button_pressed"))

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

func generate_diagram(
	initial_state: Array, final_state: Array, min_degree: int, max_degree: int, usable_interactions: Array, find_all: bool = false
) -> ConnectionMatrix:
	start_time = Time.get_ticks_usec()
	var print_results : bool = true
	
	if compare_quantum_numbers(initial_state, final_state) == INVALID:
		print('Initial state quantum numbers do not match final state')
		return null
	
	var base_interaction_matrix := create_base_interaction_matrix(initial_state, final_state)

	var same_hadron_particles := get_shared_elements(get_hadron_particles(initial_state), get_hadron_particles(final_state))
	var possible_hadron_connections := get_possible_hadron_connections(base_interaction_matrix, same_hadron_particles)

	var degrees_to_check = get_degrees_to_check(
		min_degree, max_degree, base_interaction_matrix, usable_interactions
	)

	var generated_connection_matrices : Array[ConnectionMatrix] = []

	for degree in degrees_to_check:

		var possible_hadron_connection_count := get_possible_hadron_connection_count(
			base_interaction_matrix.get_unconnected_particle_count(StateLine.StateType.Both),
			same_hadron_particles.size(), degree
		)
		
		var unique_matrices : Array[InteractionMatrix] = []

		for attempt in range(ATTEMPTS_PER_DEGREE * (degree + 1)):
			var unique_interaction_matrix: InteractionMatrix = generate_unique_interaction_matrix(
					base_interaction_matrix, degree, possible_hadron_connections, possible_hadron_connection_count, unique_matrices,
					usable_interactions
			)
			if unique_interaction_matrix == null:
				if print_results:
					print("Unable to find unique matrix")
				continue
				
			unique_matrices.append(unique_interaction_matrix)
			unique_interaction_matrix = connect_interaction_matrix(unique_interaction_matrix)
			
			if unique_interaction_matrix == null:
				if print_results:
					print("Unable to connect matrix")
				continue
			
			if print_results:
				print(
					'Success! Found at degree ', degree,' which took ', attempt,
					' attempts which took ', Time.get_ticks_usec() - start_time, ' usec'
				)
				
				generated_matrix = unique_interaction_matrix
				
			
			if !find_all:
				return unique_interaction_matrix.get_connection_matrix()
			
			generated_connection_matrices.append(unique_interaction_matrix.get_connection_matrix())
				
		
		if print_results:
			print('Failed to find at degree ', degree)
	
	if print_results:
		print('Generation failed')
	return null
	
func connect_interaction_matrix(unconnected_interaction_matrix: InteractionMatrix) -> InteractionMatrix:
	var entry_and_exit_points := unconnected_interaction_matrix.get_entry_and_exit_points()
	
	var forbidden_points : PackedInt32Array = []
	for point in entry_and_exit_points[0]:
		if point not in entry_and_exit_points[1]:
			forbidden_points.append(point)
	
	var initial_path_start_points : Array[PackedInt32Array] = [
		get_shade_start_points(unconnected_interaction_matrix, Shade.Bright),
		get_shade_start_points(unconnected_interaction_matrix, Shade.Dark)
	]
	unconnected_interaction_matrix.reduce_to_base_particles()
	
	for _attempt in range(CONNECTION_ATTEMPTS):
		var interaction_matrix : InteractionMatrix = unconnected_interaction_matrix.duplicate()
		
		var has_directional_particles : bool = interaction_matrix.get_unconnected_base_particles().any(
			func(particle): return particle in GLOBALS.DIRECTIONAL_PARTICLES
		)
		
		if has_directional_particles:
			if connect_directional_particles(interaction_matrix, initial_path_start_points, forbidden_points) == FAILED:
				continue
		
		var has_directionless_particles: bool = interaction_matrix.get_unconnected_base_particles().any(
			func(particle): return particle not in GLOBALS.DIRECTIONAL_PARTICLES
		)
		
		if has_directionless_particles:
			if connect_directionless_particles(interaction_matrix) == FAILED:
				continue
				
		var diagram_connected := interaction_matrix.is_fully_connected(true)
		
		if diagram_connected:
			return interaction_matrix
	
	return null

func connect_directionless_particles(interaction_matrix: InteractionMatrix) -> int:
	for connect_from_id in range(interaction_matrix.unconnected_matrix.size()):
		for particle in interaction_matrix.unconnected_matrix[connect_from_id]:
			var available_points := get_available_points(interaction_matrix, connect_from_id, particle, [])
			
			if available_points.size() == 0:
				return FAILED
			
			var connect_to_id : int = choose_random(available_points)[0]
			interaction_matrix.connect_interactions(connect_from_id, connect_to_id, particle)
	
	return SUCCEEDED

func connect_directional_particles(
	interaction_matrix: InteractionMatrix, initial_shade_start_points: Array[PackedInt32Array], forbidden_points: PackedInt32Array
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
			
			var connection_failed = path_start_points[-1] == CONNECTION_FAILED
			if connection_failed:
				return FAILED
			
		if path_start_points.size() == 0:
			break
	
	var loop_start_points : PackedInt32Array = []
	for rotation_count in range(MAX_SHADE_CONNECTION_ROTATIONS):
		if !interaction_matrix.unconnected_matrix.any(
			func(interaction): return interaction.any(
				func(particle): return particle in GLOBALS.DIRECTIONAL_PARTICLES
		)):
			return SUCCEEDED
		
		for shade in shades:
			loop_start_points += get_initial_shade_loop_points(interaction_matrix, shade)
			
			if loop_start_points.size() == 0:
				continue
				
			loop_start_points = connect_shade_loops(interaction_matrix, loop_start_points, shade)
			
			if loop_start_points.size() == 0:
				break
			
			var connection_failed = loop_start_points[-1] == CONNECTION_FAILED
			if connection_failed:
				return FAILED

	return FAILED

func get_initial_shade_loop_points(interaction_matrix: InteractionMatrix, shade: Shade) -> PackedInt32Array:
	var initial_loop_points : PackedInt32Array = []
	
	for i in range(
		interaction_matrix.get_starting_state_id(StateLine.StateType.None),
		interaction_matrix.get_ending_state_id(StateLine.StateType.None)
	):
		for particle in interaction_matrix.unconnected_matrix[i]:
			if particle in SHADED_PARTICLES[shade]:
				initial_loop_points.append(i)
			
				break
	
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

func print_time():
	print(Time.get_ticks_usec() - start_time)

func generate_unique_interaction_matrix(
	base_interaction_matrix: InteractionMatrix, degree: int, possible_hadron_connections: Array,
	possible_hadron_connection_count: Array, unique_matrices: Array[InteractionMatrix], usable_interactions: Array
) -> InteractionMatrix:
	
	var unique_interaction_matrix : InteractionMatrix
	
	for _attempt in range(UNIQUE_GENERATION_ATTEMPTS):
		unique_interaction_matrix = generate_interaction_matrix(
			base_interaction_matrix, degree, possible_hadron_connections, possible_hadron_connection_count, usable_interactions
		)
		var generation_failed: bool = unique_interaction_matrix == null
		
		if generation_failed:
			continue
		
		if unique_interaction_matrix in unique_matrices:
			continue
		
		return unique_interaction_matrix

	return null

func generate_interaction_matrix(
	base_interaction_matrix: InteractionMatrix, degree: int, hadron_connections: Array, possible_hadron_connection_count: Array,
	usable_interactions: Array
) -> InteractionMatrix:
	
	for _attempt in range(INTERACTION_MATRIX_GENERATION_ATTEMPTS):
		for hadron_connection_count in possible_hadron_connection_count:
			var interaction_matrix : InteractionMatrix = base_interaction_matrix.duplicate()
			insert_random_hadron_connections(interaction_matrix, hadron_connections, hadron_connection_count)
			
			var interactions : Array = generate_interactions(
				interaction_matrix.get_unconnected_base_particles(), degree, usable_interactions
			)
			
			if interactions == [INTERACTION_GENERATION_FAILED]:
				continue
			
			for interaction in interactions:
				interaction_matrix.add_unconnected_interaction(interaction)
			
			return interaction_matrix
	
	return null

func insert_random_hadron_connections(
	interaction_matrix: InteractionMatrix, hadron_connections: Array, hadron_connection_count: int
) -> void:
	hadron_connections.shuffle()
	for i in range(hadron_connection_count):
		interaction_matrix.insert_connection(hadron_connections[i])

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
		var connect_from_ids: Array[PackedInt32Array] = [[], []]
		var connect_to_ids: Array[PackedInt32Array] = [[], []]
		for state in states:
			for id in interaction_matrix.find_all_unconnected_state_particle(particle, state):
				if !interaction_matrix.is_hadron(id):
					continue
				if sign(particle) * state_factor[state] > 0:
					connect_from_ids[state].append(id)
				else:
					connect_to_ids[state].append(id)
		
		for state in states:
			for connect_from_id in connect_from_ids[state]:
				for connect_to_id in connect_to_ids[(state+1)%2]:
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

func generate_interactions(unconnected_particles: Array, degree: int, usable_interactions: Array) -> Array:
	var interactions : Array = []

	var skip_next_interaction : bool = false
	for interaction_count in range(degree):
		if skip_next_interaction:
			continue

		var possible_interaction_connections := get_possible_interaction_connections(
			unconnected_particles, degree-interaction_count, usable_interactions
		)

		if possible_interaction_connections.size() == 0:
			return [INTERACTION_GENERATION_FAILED]

		var next_interaction_connection : Array = choose_random(possible_interaction_connections, 1)[0]
		unconnected_particles = add_next_interaction(interactions, unconnected_particles, next_interaction_connection)

		skip_next_interaction = interaction_size(next_interaction_connection[INDEX.INTERACTION]) == 2

	return interactions

func choose_random(array: Array, choose_count: int = 1) -> Array:
	if array.size() == 0:
		push_error("Choose random array is size 0")
	
	var chosen_random := []
	var random_start_index := randi() % array.size()
	
	for i in choose_count:
		chosen_random.append(array[random_start_index - i])
	
	return chosen_random

func add_next_interaction(interactions: Array, unconnected_particles: Array, interaction_connection: Array) -> Array:
	
	var interaction : Array = interaction_connection[INDEX.INTERACTION]
	interactions.append(interaction)
	
	var connection_particles : Array = choose_random(
		get_shared_elements(interaction, unconnected_particles),
		interaction_connection[INDEX.CONNECTION_COUNT]
	)
	
	unconnected_particles = get_non_shared_elements(unconnected_particles, connection_particles)
	unconnected_particles += get_non_shared_elements(interaction, connection_particles)
	
	return unconnected_particles

func get_possible_interaction_connections(
	unconnected_particles: Array, interaction_count: int, usable_interactions: Array
) -> Array:
	var possible_interaction_connections := []

	for interaction in usable_interactions:
		var shared_particles_count := get_shared_elements_count(interaction, unconnected_particles)

		if shared_particles_count == 0:
			continue

		for connection_number in range(1, shared_particles_count+1):
			if is_connection_number_possible(
				unconnected_particles.size() + interaction.size() - 2*connection_number,
				interaction_count - interaction_size(interaction)
			):
				possible_interaction_connections.append([interaction, connection_number])

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
