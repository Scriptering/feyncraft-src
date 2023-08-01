extends Node

@onready var Level = get_tree().get_nodes_in_group('level')[0]
@onready var diagram_actions : DiagramActions = Level.get_node("diagram_actions")

enum INTERACTION_TYPE {electroweak, strong, higgs, weak}

enum Shade {Bright, Dark, None}

const SHADED_PARTICLES := [GLOBALS.BRIGHT_PARTICLES, GLOBALS.DARK_PARTICLES, GLOBALS.DIRECTIONAL_PARTICLES]

const INTERACTION_SIZE = 3.0

var INTERACTIONS := GLOBALS.INTERACTIONS
var TOTAL_INTERACTIONS : Array

signal draw_diagram

enum INDEX {unconnected, connected, ID = 0, TYPE, START = 0, END, INTERACTION = 0, CONNECTION_COUNT}
enum {
	WEAK, NOT_WEAK,
	UNIQUE_GENERATION_ATTEMPTS = 100, UNIQUE_GENERATION_FAILED,
	INTERACTION_GENERATION_ATTEMPTS = 100, INTERACTION_GENERATION_FAILED,
	INTERACTION_MATRIX_GENERATION_ATTEMPTS = 100,
	CONNECTION_ATTEMPTS = 100, CONNECTION_FAILED,
	MAX_PATH_STEPS = 100,
	MAX_SHADE_CONNECTION_ROTATIONS = 100
}

enum STATE {final = -1, neither, initial}

enum {FAILED, SUCCEEDED}

var state_factor : Dictionary = {
	StateLine.StateType.Initial: +1,
	StateLine.StateType.Final: -1
}

var states : Array[StateLine.StateType] = [
	StateLine.StateType.Initial,
	StateLine.StateType.Final
]

var shades : Array[Shade] = [
	Shade.Bright,
	Shade.Dark
]

var shade_factor : Dictionary = {
	Shade.Bright: -1,
	Shade.Dark: +1
}

var NUM_QUANTUM_NUMBERS = GLOBALS.QUANTUM_NUMBERS[0].size() -1

const INVALID = -1
const NOT_UNIQUE = -2
const ALL = 4
const VALID = 1
const MAX_DEGREE = 10
const MAX_ATTEMPTS = 10000
const ATTEMPTS_PER_DEGREE = 10
const MAX_INTERACTION_ATTEMPTS = 1000
const ATTEMPTS_PER_DIAGRAM_PER_DEGREE = 10
const ATTEMPTS_FOR_DIRECTIONLESS_PER_ATTEMPT = 10
const ATTEMPTS_FOR_UNIQUE_MATRIX_PER_DEGREE = 100
const MAX_STEPS = 100

var start_time : float

var InitialState : Array
var FinalState : Array

var Interaction_checks : Array

@onready var Line = preload("res://Scenes and Scripts/Diagram/line.tscn")

func _ready() -> void:
	
	await get_tree().create_timer(1).timeout
	var diagram := generate_diagram([[GLOBALS.Particle.up]], [[GLOBALS.Particle.top]], 1, 10, get_usable_interactions([true, true, true, true]))
	
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
	min_degree: int, max_degree: int, initial_state: Array, final_state: Array, number_of_state_particles: int
) -> Array:
	var degrees_to_check: Array = []
	var initial_hadron_particles := get_hadron_particles(initial_state)
	var final_hadron_particles := get_hadron_particles(final_state)

	var number_of_unconnectable_particles: int = (
		number_of_state_particles - initial_hadron_particles.size() - final_hadron_particles.size() +
		get_non_shared_elements(initial_hadron_particles, final_hadron_particles).size()
	)

	min_degree = max(number_of_unconnectable_particles%3, min_degree)
	
	for degree in range(min_degree, max_degree+1):
		if (number_of_state_particles - degree) % 2 == 0:
			degrees_to_check.append(degree)

	return degrees_to_check

func generate_diagram(
	initial_state: Array, final_state: Array, min_degree: int, max_degree: int, usable_interactions: Array, find_all: bool = false
) -> ConnectionMatrix:
	start_time = Time.get_ticks_usec()
	
	if compare_quantum_numbers(initial_state, final_state) == INVALID:
		print('Initial state quantum numbers do not match final state')
		return null
	
	var weak: bool = compare_quantum_numbers(initial_state, final_state) == WEAK
	var base_interaction_matrix := create_base_interaction_matrix(initial_state, final_state)
	
	# remove later
	InitialState = initial_state
	FinalState = final_state

	var same_hadron_particles := get_shared_elements(get_hadron_particles(initial_state), get_hadron_particles(final_state))
	var possible_hadron_connections := get_possible_hadron_connections(base_interaction_matrix, same_hadron_particles)

	var degrees_to_check = get_degrees_to_check(
		min_degree, max_degree, initial_state, final_state,
		base_interaction_matrix.get_state_count(StateLine.StateType.Both)
	)

	var interaction_matrix : Array
	var unique_matrices : Array[InteractionMatrix] = []
	var generated_connection_matrices : Array[ConnectionMatrix]

	var failed : bool = false
	for degree in degrees_to_check:

		var possible_hadron_connection_count := get_possible_hadron_connection_count(
			base_interaction_matrix.get_unconnected_particle_count(StateLine.StateType.Both),
			same_hadron_particles.size(), degree
		)

		for attempt in range(ATTEMPTS_PER_DEGREE * (degree + 1)):
			var unique_interaction_matrix: InteractionMatrix = generate_unique_interaction_matrix(
					base_interaction_matrix, degree, possible_hadron_connections, possible_hadron_connection_count, unique_matrices,
					usable_interactions
			)
			if unique_interaction_matrix == null:
				print("Unable to find unique matrix")
				continue
				
			unique_matrices.append(unique_interaction_matrix)
			unique_interaction_matrix = connect_interaction_matrix(unique_interaction_matrix)
			
			if unique_interaction_matrix == null:
				print("Unable to connect matrix")
				continue
				
			print('Success! Found at degree ', degree,' which took ', attempt, ' attempts which took ', Time.get_ticks_usec() - start_time, ' usec')
			
			if !find_all:
				return unique_interaction_matrix.get_connection_matrix()
			
			generated_connection_matrices.append(unique_interaction_matrix.get_connection_matrix())
				
		
		print('Failed to find at degree ', degree)
	
	print('Generation failed')
	return null


func seperate_double_connections(matrix : Array):
	var N_interactions : int = matrix.size()
	var state_interactions := InitialState + FinalState
	
	for i in range(N_interactions):
		for j in range(N_interactions):
			if (i == j or (in_state(i) != STATE.neither and state_interactions[i])
			or (in_state(j) != STATE.neither and state_interactions[j])
			):
				continue
			
			while ((matrix[i][INDEX.connected][j] != [] and matrix[j][INDEX.connected][i] != []) or 
			matrix[i][INDEX.connected][j].size() > 1):
				matrix = seperate_connections(matrix, i, j)
	
	return matrix
	
func connect_interaction_matrix(unconnected_interaction_matrix: InteractionMatrix) -> InteractionMatrix:
	var entry_points := unconnected_interaction_matrix.get_entry_points()
	var initial_path_start_points : Array = [
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
			if connect_directional_particles(interaction_matrix, initial_path_start_points, entry_points) == FAILED:
				continue
		
		var has_directionless_particles: bool = interaction_matrix.get_unconnected_base_particles().any(
			func(particle): return particle not in GLOBALS.DIRECTIONAL_PARTICLES
		)
		
		if has_directionless_particles:
			if connect_directionless_particles(interaction_matrix) == FAILED:
				continue
				
		var diagram_connected := interaction_matrix.is_fully_connected()
		
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
	
func connect_directionless(matrix, index, no_states):
	var interaction = matrix[index]
	
	for particle in interaction[INDEX.unconnected]:
		if !base_particle(particle) in GLOBALS.DIRECTIONAL_PARTICLES:
			var available_to_connect = []
			for j in range(no_states - 1, matrix.size()):
				if index == j:
					continue
				if (particle in matrix[j][INDEX.unconnected]):
#				 (matrix[j][INDEX.connected][index].size() + matrix[index][INDEX.connected][j].size()) != (INTERACTION_SIZE - 1)):
					available_to_connect.append(j)
			
			if available_to_connect.size() == 0:
				return [INVALID]
				
			var random_connect = available_to_connect[randi() % available_to_connect.size()]
			
			matrix = connect_interactions(matrix, index, random_connect, particle)
	
	return matrix

func connect_directional_particles(
	interaction_matrix: InteractionMatrix, initial_shade_start_points: Array, forbidden_points: PackedInt32Array
) -> int:
	var path_start_points : Array = []
	
	for rotation_count in range(MAX_SHADE_CONNECTION_ROTATIONS):
		for shade in shades:
			if rotation_count == 0:
				path_start_points += initial_shade_start_points[shade]
				
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
	
	for shade in shades:
		if connect_shade_loops(interaction_matrix, shade) == FAILED:
			return FAILED
	
	return SUCCEEDED
	
func connect_shade_loops(interaction_matrix: InteractionMatrix, shade: Shade) -> int:
	var loop_start_points: Array = []

	for i in range(
		interaction_matrix.get_starting_state_id(StateLine.StateType.None),
		interaction_matrix.get_ending_state_id(StateLine.StateType.None)
	):
		if interaction_matrix.unconnected_matrix[i].any(func(particle): return particle in SHADED_PARTICLES[shade]):
			loop_start_points.append(i)
	
	for start_point in loop_start_points:
		if connect_shade_paths(interaction_matrix, loop_start_points, shade, []) == [CONNECTION_FAILED]:
			return FAILED
	
	return SUCCEEDED

func connect_directional_loops(matrix : Array, shade : int) -> Array:
	var shade_points := []
	var middle_points := []
	
	for i in range(matrix.size()):
		if in_state(i, InitialState, FinalState) == STATE.neither:
			if has_directional(matrix[i], INDEX.unconnected, shade):
				middle_points.append(i)
	
	shade_points += middle_points
	
	for point in shade_points:
		if has_directional(matrix[point], INDEX.unconnected, shade):
			var matrix_connecting_extrapoints = connect_path(matrix, point, [], shade_points, shade)

			if matrix_connecting_extrapoints == [INVALID]:
				return [INVALID]
			
			matrix = matrix_connecting_extrapoints[0]
			shade_points = matrix_connecting_extrapoints[1]
	
	return matrix

func connect_shade_paths(
	interaction_matrix: InteractionMatrix, start_points: Array, shade : Shade, forbidden_points : PackedInt32Array
) -> Array:
	
	var next_start_points : Array = []
	
	for start_point in start_points:
		next_start_points += connect_shade_path(interaction_matrix, start_point, shade, forbidden_points)
		if next_start_points == [CONNECTION_FAILED]:
			return [CONNECTION_FAILED]
	
	return next_start_points

func connect_shade_path(
	interaction_matrix: InteractionMatrix, start_point: int, shade : Shade, forbidden_points : PackedInt32Array
) -> Array:
	var extra_start_points : Array = []
	var current_point := start_point
	
	for _step in range(MAX_PATH_STEPS):
		var current_particle = choose_random_shade_particle(interaction_matrix, current_point, shade)
		if current_particle == GLOBALS.Particle.W and interaction_matrix.get_state_from_id(current_point) == StateLine.StateType.None:
			extra_start_points.append(current_point)
			
		var available_points := get_available_points(interaction_matrix, current_point, current_particle, forbidden_points)
		
		if available_points.size() == 0:
			return [CONNECTION_FAILED]
		
		var next_point : int = choose_random(available_points)[0]
		
		connect_shade_points(interaction_matrix, current_point, next_point, current_particle, shade)
		
		current_point = next_point
		var path_finished = interaction_matrix.unconnected_matrix[current_point].size() == 0
		
		if path_finished:
			break
	
	return extra_start_points

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

func connect_path(matrix: Array, start : int, end_points : Array, connecting_points_original : Array, shade : int) -> Array:
	var current_point := start
	var path := [current_point]
	var next_point : int
	var connecting_points = connecting_points_original.duplicate()
	var extra_start_points := []
	var extra_end_points := []
	
	for _step in range(MAX_STEPS):
		var directionals = get_directionals(matrix[current_point], INDEX.unconnected, shade)
		
		if directionals.size() == 0:
			return [INVALID]
		
		var current_particle = directionals[randi() % directionals.size()]
		
		next_point = connect_step(matrix, current_particle, current_point, connecting_points, shade)
		
		if next_point == INVALID:
			return [INVALID]
			
		if current_particle == GLOBALS.Particle.W:
			extra_start_points.append(current_point)
			extra_end_points.append(next_point)
			
			match shade:
				Shade.Dark:
					matrix = connect_interactions(matrix, current_point, next_point, current_particle)
				Shade.Bright:
					matrix = connect_interactions(matrix, next_point, current_point, current_particle)
		else:
			matrix = connect_interactions(matrix, current_point, next_point, current_particle)

		if all_connected(matrix[current_point]):
			connecting_points.erase(current_point)
		
		path.append(next_point)
		
		if next_point in end_points or next_point == start:
			if !has_directional(matrix[next_point], INDEX.unconnected, Shade.None):
				connecting_points.erase(next_point)
			return [matrix, connecting_points, [extra_start_points, extra_end_points]]
		
		current_point = next_point

	return [INVALID]

func get_directional_paths(matrix : Array, start_points : Array, end_points : Array, shade : int) -> Array:
	var shade_points := end_points
	var middle_points := []
	var extra_start_points := []
	var extra_end_points := []
	
	for i in range(matrix.size()):
		if !start_points.has(i) and !end_points.has(i):
			if has_directional(matrix[i], INDEX.unconnected, shade):
				middle_points.append(i)
	
	shade_points += middle_points

	for start in start_points:
		if has_directional(matrix[start], INDEX.unconnected, shade):
			if matrix[start][INDEX.unconnected].size() != 0:
				var matrix_connecting_extrapoints = connect_path(matrix, start, end_points, shade_points, shade)

				if matrix_connecting_extrapoints == [INVALID]:
						return [INVALID]
					
				matrix = matrix_connecting_extrapoints[0]
				shade_points = matrix_connecting_extrapoints[1]
				extra_start_points += matrix_connecting_extrapoints[2][0]
				extra_end_points += matrix_connecting_extrapoints[2][1]

	return [matrix, [extra_start_points, extra_end_points]]

func get_shade_start_points(interaction_matrix: InteractionMatrix, shade: Shade) -> Array:
	var start_points : Array = []
	
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

func get_startend_points(initial_state : Array, final_state : Array, combined_states : Array, shade : int) -> Array:
	var start_points := []
	var end_points := []
	
	for i in range(combined_states.size()):
		for j in range(combined_states[i].size()):
			var particle = combined_states[i][j]
			if base_particle(particle) in SHADED_PARTICLES[shade]:
				if base_particle(particle) == GLOBALS.Particle.W:
					match shade:
						Shade.Bright:
							if -1 * in_state(i, initial_state, final_state) * sign(particle) > 0:
								start_points.append(i)
							else:
								end_points.append(i)
						Shade.Dark:
							if in_state(i, initial_state, final_state) * sign(particle) > 0:
								start_points.append(i)
							else:
								end_points.append(i)
				
				else:
					if in_state(i, initial_state, final_state) * sign(particle) > 0:
						start_points.append(i)
					else:
						end_points.append(i)
	
	return [start_points, end_points]

func connect_directional_states(matrix : Array, initial_state : Array, final_state : Array, _weak : bool) -> Array:
	var combined_states : Array = initial_state + final_state
	var extra_points := [[],[]]
	var Break := false
	
	for i in range(MAX_ATTEMPTS):
		if Break:
			break
		for shade in [Shade.Bright, Shade.Dark]:
			var startend_points = [[],[]]
			
			if i == INDEX.START:
				startend_points = get_startend_points(initial_state, final_state, combined_states, shade)
			elif extra_points == [[],[]]:
				Break = true
				break
			
			var start_points = startend_points[INDEX.START] + extra_points[INDEX.START]
			var end_points = startend_points[INDEX.END] + extra_points[INDEX.END]
			
			if start_points != []:
				var matrix_extrapoints = get_directional_paths(matrix, start_points, end_points, shade)
				
				if matrix_extrapoints == [INVALID]:
					return [INVALID]
					
				matrix = matrix_extrapoints[0]
				extra_points = matrix_extrapoints[1]

		
	for shade in [Shade.Bright, Shade.Dark]:
		matrix = connect_directional_loops(matrix, shade)

	if matrix == [INVALID]:
		return [INVALID]

	return matrix

func get_usable_interactions(interaction_checks: Array[bool]) -> Array:
	var usable_interactions : Array = []
	
	for interaction_type_count in range(GLOBALS.INTERACTIONS.size()):
		if interaction_checks[interaction_type_count]:
			usable_interactions += GLOBALS.INTERACTIONS[interaction_type_count]
	
	return usable_interactions

func seperate_connections(matrix : Array, index1 : int, index2: int) -> Array:
	var seperating_particle := INVALID
	
	for particle in matrix[index1][INDEX.connected][index2]:
		if !particle in SHADED_PARTICLES[Shade.None]:
			seperating_particle = particle
			break
	
	if seperating_particle == INVALID:
		for particle in matrix[index2][INDEX.connected][index1]:
			if !particle in SHADED_PARTICLES[Shade.None]:
				seperating_particle = particle
				
				var temp_index = index1
				index1 = index2
				index2 = temp_index
				break
	
	if seperating_particle == INVALID:
		seperating_particle = matrix[index1][INDEX.connected][index2][0]
	
	matrix[index1][INDEX.connected][index2].erase(seperating_particle)
	
	var new_interaction : Array = create_interaction([], matrix.size())
	new_interaction[INDEX.connected][index2] += [seperating_particle]
	
	matrix = add_interaction(matrix, new_interaction, matrix.size())
	
	matrix[index1][INDEX.connected][-1] += [seperating_particle]
	
	return matrix

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
	var remaining_elements := array1.duplicate()
	
	for particle in array2:
		if particle in remaining_elements:
			remaining_elements.erase(particle)
			shared_elements.append(particle)
	
	return shared_elements

func get_shared_elements_count(array1 : Array, array2 : Array) -> int:
	var shared_element_count: int = 0
	var remaining_elements := array1.duplicate()
	
	for element in array2:
		if element in remaining_elements:
			remaining_elements.erase(element)
			shared_element_count += 1
	
	return shared_element_count

func add_interaction(matrix : Array, new_interaction : Array, index : int) -> Array:
	matrix.insert(index, new_interaction)
	
	for i in range(matrix.size()):
		matrix[i][INDEX.connected].insert(index, [])
	
	return matrix

func remove_interaction(matrix : Array, index : int) -> Array:
	matrix.remove_at(index)
	
	for i in range(matrix.size()):
		matrix[i][INDEX.connected].remove_at(index)
	
	return matrix

func convert_state_particles(particles : Array) -> Array:
	var converted_particles := []
	converted_particles.resize(particles.size())
	
	for i in range(particles.size()):
		if abs(particles[i]) == GLOBALS.Particle.photon:
			converted_particles[i] = GLOBALS.Particle.Z
		else:
			converted_particles[i] = particles[i]
	
	return converted_particles

func in_state(i : int, initial_state : Array = InitialState, final_state : Array = FinalState) -> int:
	if i < initial_state.size():
		return STATE.initial
	elif i < initial_state.size() + final_state.size():
		return STATE.final
	else:
		return STATE.neither

func connect_step(matrix : Array, particle : int, current_point : int,
 connecting_points : Array, _shade : int) -> int:
	var available_points := []
	
	for i in connecting_points:
		if i != current_point and !(in_state(i) != STATE.neither and in_state(current_point) != STATE.neither):
			if matrix[i][INDEX.unconnected].has(particle):
				available_points.append(i)
	
	if available_points.size() == 0:
		#print('No available points to connect')
		return INVALID
	
	var random_index := randi() % available_points.size()
	
	return available_points[random_index]

func print_time():
	print(Time.get_ticks_usec() - start_time)

func all_connected(interaction : Array) -> bool:
	return interaction[INDEX.unconnected].size() == 0


func connect_interactions(matrix : Array, index1 : int, index2 : int, particle : int) -> Array:
	
	matrix[index1][INDEX.unconnected].erase(particle)
	matrix[index2][INDEX.unconnected].erase(particle)
	
	matrix[index1][INDEX.connected][index2] += [particle]
	
	return matrix

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

func _generate_interaction_matrix(initial_state : Array, final_state : Array, degree_strength : int,
 same_hadronic_particles : Array, possible_hadron_connection_count: Array, unique_matrices : Array) -> Array:
	var interaction_matrix := []
	var state_interactions := initial_state.duplicate() + final_state.duplicate()
	var state_particles := []
	var connect_straight := false

	for i in range(state_interactions.size()):
		for j in range(state_interactions[i].size()):
			state_interactions[i][j] = base_particle(state_interactions[i][j])
			state_particles.append(state_interactions[i][j])

	var possible_N_same_connections := get_possible_N_same_connections(same_hadronic_particles.size(), state_particles.size(), degree_strength)
	possible_N_same_connections.shuffle()
	
	if degree_strength == 0 and initial_state.size() == 1 and final_state.size() == 1 and initial_state == final_state:
		connect_straight = true
		possible_N_same_connections.append(1)

	var test_interactions := []
	var hadron_connect_indicies := []
	
	if possible_N_same_connections.size() == 0 and !is_connection_number_possible(state_particles.size(), degree_strength):
		return [INVALID]
	
	for _attempt in range(MAX_INTERACTION_ATTEMPTS):
		for n in possible_N_same_connections:
			var temp_state_particles := state_particles.duplicate()
			
			hadron_connect_indicies = get_hadron_connect_indicies(initial_state, final_state, same_hadronic_particles, n)
			
			if connect_straight:
				hadron_connect_indicies.append([0, 1, initial_state[0][0]])
			
			for i in range(hadron_connect_indicies.size()):
				var particle : GLOBALS.Particle = base_particle(hadron_connect_indicies[i][2])
				temp_state_particles.erase(particle)
				temp_state_particles.erase(particle)
			
			test_interactions = get_interactions(temp_state_particles, degree_strength)
			
			if test_interactions != [INVALID]:
				break
				
		if test_interactions != [INVALID]:
			break
	if test_interactions == [INVALID]:
		return [INVALID]
	
	var N_interactions := test_interactions.size() + state_interactions.size()
	
	for interaction in state_interactions + test_interactions:
		interaction_matrix.append(create_interaction(interaction, N_interactions))
	
	for index in hadron_connect_indicies:
		interaction_matrix = connect_interactions(interaction_matrix, index[0], index[1], index[2])
	
	if interaction_matrix in unique_matrices:
		return [NOT_UNIQUE]

	return interaction_matrix

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
				if is_anti(particle*state_factor[state]):
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
	
	var possible_hadron_connection_count := range(
		max(ceil((unconnected_state_particle_count - INTERACTION_SIZE*degree)/2), 0),
		same_hadron_particles_count+1
	)
	
	possible_hadron_connection_count.shuffle()
	
	return possible_hadron_connection_count

func get_possible_N_same_connections(max_N : int, N_state_particles : int, degree : int) -> Array:
	var possible_N := []
	
	for i in range(max_N + 1):
		if is_connection_number_possible(N_state_particles - 2*i, degree):
			possible_N.append(i)
	
	return possible_N

func get_hadron_connect_indicies(initial_state_original : Array, final_state_original : Array, same_particles : Array, n : int):
	var indicies := []
	var initial_state := initial_state_original.duplicate()
	var initial_range := range(initial_state.size())
	initial_range.shuffle()
	var final_state := final_state_original.duplicate()
	var final_range := range(final_state.size())
	final_range.shuffle()
	same_particles.shuffle()
	
	for particle in same_particles.slice(0, n):
		for i in initial_range:
			if !particle in initial_state[i] or initial_state[i].size() == 1:
				continue
			for j in final_range:
				if !particle in final_state[j] or final_state[j].size() == 1:
					continue
				
				initial_state[i].erase(particle)
				final_state[j].erase(particle)
				
				if is_anti(particle):
					indicies.append([j + initial_state.size(), i, base_particle(particle)])
				else:
					indicies.append([i, j + initial_state.size(), base_particle(particle)])
	
	return indicies

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
	var possible_connection_count := []

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

func possible_interaction(current_num : int, connection_number : int,
 unconnected_particles : Array, num_interactions : int, four_interaction : bool) -> bool:
	var new_unconnected_size = (unconnected_particles.size() + (INTERACTION_SIZE + int(four_interaction) - connection_number)) - connection_number
	var num_interactions_left = num_interactions - (current_num + int(four_interaction))

	if connection_number == 0 or new_unconnected_size > INTERACTION_SIZE * num_interactions_left:
		return false

	if new_unconnected_size == 0 and num_interactions_left == 0:
		return true

	return is_connection_number_possible(new_unconnected_size, num_interactions_left)

func get_interactions(state_particles : Array, num_interactions : int) -> Array:
	var interactions := []
	var unconnected_particles := state_particles
	var chosen_interaction : Array = [[]]
	var skip := false
	
	for i in range(num_interactions):
		var possible_interactions := []
		if skip:
			skip = false
			continue
		for j in range(INTERACTIONS.size()):
			if Interaction_checks[j]:
				var interaction_type = INTERACTIONS[j]
				for interaction in interaction_type:
					var duplicate_interaction = interaction.duplicate()
					var four_interaction : bool = interaction.size() == 4
					
					if num_interactions - i < 2 and four_interaction:
						continue
					
					var connection_number = interaction_connection_number(duplicate_interaction, unconnected_particles.duplicate())
					
					if connection_number != 0:
						if connection_number == 1:
							if possible_interaction(i+1, connection_number, unconnected_particles, num_interactions, four_interaction):
								possible_interactions.append([duplicate_interaction, ALL])
						else:
							for cn in range(connection_number, 0, -1):
								if possible_interaction(i+1, cn, unconnected_particles, num_interactions, four_interaction):
									if cn == connection_number:
										possible_interactions.append([duplicate_interaction, ALL])
									else:
										possible_interactions.append([duplicate_interaction, cn])
							
				
		if possible_interactions.size() == 0:
			return [INVALID]

		chosen_interaction = possible_interactions[randi() % possible_interactions.size()]
		if chosen_interaction[0].size() == 4:
			skip = true
		unconnected_particles = connect_interaction(chosen_interaction, unconnected_particles.duplicate())
		interactions.append(chosen_interaction[0])
		
	return interactions

func interaction_connection_number(interaction : Array, particles : Array) -> int:
	var connection_number := 0
	
	for particle in interaction:
		if particle in particles:
			connection_number += 1
			particles.erase(particle)
	
	return connection_number

func connect_interaction(interaction_and_number : Array, particles : Array) -> Array:
	var unconnected_particles := []
	var interaction : Array = interaction_and_number[0].duplicate()
	var interaction_size := interaction.size()
	var connection_number : int = interaction_and_number[1]
	
	if connection_number != interaction_size:
		interaction.shuffle()

	var connection_counter := 0
	for i in range(interaction_size):
		var particle = interaction[i]
		if connection_counter < connection_number:
			if particles.has(particle):
				particles.erase(particle)
				connection_counter += 1
			else:
				unconnected_particles.append(particle)
		else:
			unconnected_particles.append(particle)

	return particles + unconnected_particles

func is_connection_number_possible(unconnected_particle_count : int, interaction_count : int) -> bool:
	if interaction_count == 1:
		return unconnected_particle_count == INTERACTION_SIZE

	return unconnected_particle_count <= interaction_count * INTERACTION_SIZE
# old
func _is_connection_number_possible(n_unconnected : int, n_interactions : int) -> bool:
	var counter = n_interactions * INTERACTION_SIZE
	
	
	while counter >= 0:
		if n_unconnected == counter:
			return true
		else:
			counter -= 2
	
	return false
	
func create_interaction(type : Array, size : int) -> Array:
	var empty_array = []
	empty_array.resize(size)
	empty_array.fill([].duplicate())

	return [type, empty_array]

func compare_quantum_numbers(initial_state : Array, final_state : Array) -> int:
	for quantum_number in range(GLOBALS.QuantumNumber.size()):
		if !is_equal_approx(calculate_quantum_sum(quantum_number, initial_state), calculate_quantum_sum(quantum_number, final_state)):
			if (
				quantum_number == GLOBALS.QuantumNumber.charge or
				quantum_number == GLOBALS.QuantumNumber.lepton or 
				quantum_number == GLOBALS.QuantumNumber.quark
			):
				return INVALID
			else:
				return WEAK
		
	return NOT_WEAK

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

func add_anti(particle) -> GLOBALS.Particle:
	return -abs(particle)

func create_particles(matrix: Array):
	var drawing_interactions := get_tree().get_nodes_in_group('drawing_interactions')
	
	for i in range(matrix.size()):
		for j in range(matrix.size()):
			var connection = matrix[i][INDEX.connected][j]
			if connection != []:
				diagram_actions.place_line(
					drawing_interactions[i].position,
					drawing_interactions[j].position,
					connection[0]
				)

func get_connection_ids(matrix: Array, index: int):
	var connections := []
	for connection in matrix[index][INDEX.connected]:
		if connection != []:
			connections.append(connection)
	
	return connections

func has_directional(interaction : Array, connection_index : int, shade : int) -> bool:
	var connections = interaction[connection_index]
	for connection in connections:
		match connection_index:
			INDEX.connected:
				for particle in connection:
					if base_particle(particle) in SHADED_PARTICLES[shade]:
						return true
			INDEX.unconnected:
				if base_particle(connection) in SHADED_PARTICLES[shade]:
						return true
	
	return false

func get_directionals(interaction : Array, connection_index : int, shade : int) -> Array:
	var directionals := []
	var connections : Array = interaction[connection_index]
	
	
	for connection in connections:
		match connection_index:
			INDEX.connected:
				for particle in connection:
					if particle in SHADED_PARTICLES[shade]:
						directionals.append(particle)
			INDEX.unconnected:
				if connection in SHADED_PARTICLES[shade]:
					directionals.append(connection)
	
	return directionals

func draw_directionless_particles(matrix):
	var j_index = 0
	var drawing_interactions = get_tree().get_nodes_in_group('drawing_interactions')
	for i in range(matrix.size()):
		for j in range(j_index, matrix.size()):
			if matrix[i][INDEX.connected][j] == []:
				continue
			var particle = base_particle(matrix[i][INDEX.connected][j][0])
			if !particle in GLOBALS.DIRECTIONAL_PARTICLES:
				diagram_actions.place_line(
					drawing_interactions[i].position,
					drawing_interactions[j].position,
					particle
				)

		j_index += 1

func matrix_connections(matrix : Array):
	var connections := []
	connections.resize(matrix.size())
	
	for i in range(matrix.size()):
		var temp_connections := []
		for j in range(matrix.size()):
			if !(matrix[i][INDEX.connected][j] == [] and matrix[j][INDEX.connected][i] == []):
				temp_connections.append(j)
		connections[i] = temp_connections
	
	return connections

func split_hadrons(matrix : Array, initial_state : Array, final_state : Array) -> Array:
	var state_interactions : Array = initial_state + final_state
	var N_added_interactions : int = 0

	for i in range(state_interactions.size()):
		if state_interactions[i].size() > 1:
			matrix = split_hadron(matrix, i + N_added_interactions, state_interactions[i])
			N_added_interactions += state_interactions[i].size() - 1
			continue
 
	return matrix

func split_hadron(matrix : Array, index : int, hadron : Array) -> Array:
	var hadron_size = hadron.size()
	var matrix_index_row : Array = matrix[index][INDEX.connected]
	
	var matrix_index_column := []
	
	for interaction in matrix:
		matrix_index_column.append(interaction[INDEX.connected][index])
	
	matrix = remove_interaction(matrix, index)
	
	for i in range(hadron_size - 1):
		matrix_index_row.insert(index, [])
		matrix_index_column.insert(index, [])
	
	for particle in hadron:
		matrix = add_interaction(matrix, create_interaction([particle], matrix.size()), index)
	
	print('Printing index connections')
	print(matrix_index_row)
	print(matrix_index_column)
	
	for h in range(hadron_size):
		print_matrix(matrix)
		
		var particle = hadron[h]
		
		for i in range(matrix.size()):
			if particle in matrix_index_row[i]:
				matrix = connect_interactions(matrix, index + h, i, particle)
				matrix_index_row[i].erase(particle)
				break
			
			elif particle in matrix_index_column[i]:
				matrix = connect_interactions(matrix, i, index + h, particle)
				matrix_index_column[i].erase(particle)
				break

	print_matrix(matrix)
	return matrix

func print_matrix(matrix : Array) -> void:
	print('Printing Matrix')
	for interaction in matrix:
		print(interaction)
