extends Node

enum INTERACTION_TYPE {electroweak, strong, higgs, weak}

enum SHADE {NONE, BRIGHT, DARK}

const SHADED_PARTICLES := [GLOBALS.DIRECTIONAL_PARTICLES, GLOBALS.BRIGHT_PARTICLES, GLOBALS.DARK_PARTICLES]

const INTERACTION_SIZE = 3.0

var INTERACTIONS := GLOBALS.INTERACTIONS
var TOTAL_INTERACTIONS : Array

@onready var Level = get_tree().get_nodes_in_group('level')[0]

signal draw_diagram

enum INDEX {unconnected, connected, ID = 0, TYPE, START = 0, END}
enum {WEAK, NOT_WEAK}

enum STATE {final = -1, neither, initial}

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

func generate_diagram(initial_state_original: Array, final_state_original: Array, minDegree: int, maxDegree: int, interaction_checks: Array):
	start_time = Time.get_ticks_usec()
	
	var num_state_particles := 0
	
	var initial_state := initial_state_original.duplicate(true)
	var final_state := final_state_original.duplicate(true)
	
	for state in [initial_state, final_state]:
		for interaction in state:
			for particle in interaction:
				num_state_particles += 1

	var state_interactions : Array = initial_state + final_state
	var weak : bool
	
	InitialState = initial_state
	FinalState = final_state
	
	Interaction_checks = interaction_checks
	
	match compare_quantum_numbers(initial_state, final_state):
		WEAK:
			weak = true
		NOT_WEAK:
			weak = false
		INVALID:
			print('Initial state quantum numbers do not match final state')
			return 0
	
	var same_hadronic_particles = get_same_hadronic_particles(initial_state, final_state)
	
	var interaction_matrix : Array
	
	var unique_matrices := []
	
	var degreeRange = range(minDegree, maxDegree + 1)
	
	if minDegree == maxDegree:
		degreeRange = [minDegree]
	
	var failed : bool = false
	for degree in degreeRange:
		failed = false
		
		if num_state_particles % 2 != degree % 2:
			print('Skipped degree ' + String(degree))
			continue
		
		for attempt in range(ATTEMPTS_PER_DEGREE * (degree + 1)):
			failed = false
			var uniquefailed = false
			for _attempt in range(ATTEMPTS_FOR_UNIQUE_MATRIX_PER_DEGREE):
				uniquefailed = false
				interaction_matrix = generate_interaction_matrix(
					initial_state.duplicate(true), final_state.duplicate(true), degree, same_hadronic_particles, unique_matrices
					)
				if interaction_matrix == [NOT_UNIQUE]:
					uniquefailed = true
					continue
				elif interaction_matrix == [INVALID]:
					failed = true
					break
				else:
					break
			
			if uniquefailed:
				print('Failed to find unique diagram')
				failed = true
				continue
			
			if failed:
				print('Failed to find any diagram')
				break

			unique_matrices.append(interaction_matrix)
			
			weak = false
			var directional := false
			if !weak:
				for interaction in interaction_matrix:
					for particle in interaction[INDEX.unconnected]:
						if particle == GLOBALS.Particle.W:
							weak = true
						if particle in GLOBALS.DIRECTIONAL_PARTICLES:
							directional = true
			
			var failed_to_connect := true
			var temp_matrix : Array
			for _attempt in range(ATTEMPTS_PER_DIAGRAM_PER_DEGREE * (degree + 1)):
				if !failed_to_connect:
					break
				
				var directional_attempt_matrix = interaction_matrix.duplicate(true)
				
				if directional:
					directional_attempt_matrix = connect_directional_states(directional_attempt_matrix, initial_state, final_state, state_interactions, weak)
			
				if directional_attempt_matrix == [INVALID]:
					continue
				
				for __attempt in range(ATTEMPTS_FOR_DIRECTIONLESS_PER_ATTEMPT):
					var directionless_attempt_matrix = directional_attempt_matrix.duplicate(true)
					for i in range(directionless_attempt_matrix.size()):
						if directionless_attempt_matrix[i][INDEX.unconnected].size() != 0:
							directionless_attempt_matrix = connect_directionless(directionless_attempt_matrix, i, state_interactions.size())
							
							if directionless_attempt_matrix == [INVALID]:
								break
					
					if directionless_attempt_matrix != [INVALID]:
						temp_matrix = directionless_attempt_matrix
						break
				
				if temp_matrix == [INVALID]:
					continue
				
				var is_all_connected = true
				for interaction in temp_matrix:
					if interaction[INDEX.unconnected].size() != 0:
						is_all_connected = false
						break
				
				if !is_all_connected:
					continue

				if !Level.get_node('PathFinding').test_non(matrix_connections(temp_matrix)):
					continue
				
				failed_to_connect = false
			
			if failed_to_connect:
				print('Failed to connect')
				continue
			else:
				interaction_matrix = temp_matrix
				
			if !failed:
				print('Success! Found at degree ', degree,' which took ', attempt, ' attempts which took ', Time.get_ticks_usec() - start_time, ' usec')
				break

		if !failed:
			break
		
		print('Failed to find at degree ', degree)
	
	if failed:
		return INVALID

	interaction_matrix = seperate_double_connections(interaction_matrix)
	emit_signal('draw_diagram', interaction_matrix, initial_state, final_state)
	return VALID

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

func seperate_connections(matrix : Array, index1 : int, index2: int) -> Array:
	var seperating_particle := INVALID
	
	for particle in matrix[index1][INDEX.connected][index2]:
		if !particle in SHADED_PARTICLES[SHADE.NONE]:
			seperating_particle = particle
			break
	
	if seperating_particle == INVALID:
		for particle in matrix[index2][INDEX.connected][index1]:
			if !particle in SHADED_PARTICLES[SHADE.NONE]:
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

func get_same_hadronic_particles(initial_state_original : Array, final_state_original : Array) -> Array:
	var initial_hadrons := []
	var final_hadrons := []
	var same_particles := []
	var initial_state := initial_state_original.duplicate(true)
	var final_state := final_state_original.duplicate(true)
	
	for interaction in initial_state:
		if interaction.size() > 1:
			initial_hadrons.append(interaction)
	
	for interaction in final_state:
		if interaction.size() > 1:
			final_hadrons.append(interaction)
	
	for i in range(initial_hadrons.size()):
		for particle in initial_hadrons[i]:
			for j in range(final_hadrons.size()):
				if particle in final_hadrons[j]:
					same_particles.append(particle)
					final_hadrons[j].erase(particle)
	
	return same_particles

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

func connect_directional_states(matrix : Array, initial_state : Array, final_state : Array, combined_states : Array, _weak : bool) -> Array:
	var extra_points := [[],[]]
	var Break := false
	
	for i in range(MAX_ATTEMPTS):
		if Break:
			break
		for shade in [SHADE.BRIGHT, SHADE.DARK]:
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

		
	for shade in [SHADE.BRIGHT, SHADE.DARK]:
		matrix = connect_directional_loops(matrix, shade)

	if matrix == [INVALID]:
		return [INVALID]

	return matrix

func get_startend_points(initial_state : Array, final_state : Array, combined_states : Array, shade : int) -> Array:
	var start_points := []
	var end_points := []
	
	for i in range(combined_states.size()):
		for j in range(combined_states[i].size()):
			var particle = combined_states[i][j]
			if remove_anti(particle) in SHADED_PARTICLES[shade]:
				if remove_anti(particle) == GLOBALS.Particle.W:
					match shade:
						SHADE.BRIGHT:
							if -1 * in_state(i, initial_state, final_state) * sign(particle) > 0:
								start_points.append(i)
							else:
								end_points.append(i)
						SHADE.DARK:
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

func in_state(i : int, initial_state : Array = InitialState, final_state : Array = FinalState) -> int:
	if i < initial_state.size():
		return STATE.initial
	elif i < initial_state.size() + final_state.size():
		return STATE.final
	else:
		return STATE.neither

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
				SHADE.DARK:
					matrix = connect_interactions(matrix, current_point, next_point, current_particle)
				SHADE.BRIGHT:
					matrix = connect_interactions(matrix, next_point, current_point, current_particle)
		else:
			matrix = connect_interactions(matrix, current_point, next_point, current_particle)
			
			
			#matrix = connect_interactions(matrix, next_point, current_point, current_particle)

		if all_connected(matrix[current_point]):
			connecting_points.erase(current_point)
		
		path.append(next_point)
		
		if next_point in end_points or next_point == start:
			if !has_directional(matrix[next_point], INDEX.unconnected, SHADE.NONE):
				connecting_points.erase(next_point)
			return [matrix, connecting_points, [extra_start_points, extra_end_points]]
		
		current_point = next_point

	return [INVALID]

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

func connect_directionless(matrix, index, no_states):
	var interaction = matrix[index]
	
	for particle in interaction[INDEX.unconnected]:
		if !remove_anti(particle) in GLOBALS.DIRECTIONAL_PARTICLES:
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

func connect_interactions(matrix : Array, index1 : int, index2 : int, particle : int) -> Array:
	
	matrix[index1][INDEX.unconnected].erase(particle)
	matrix[index2][INDEX.unconnected].erase(particle)
	
	matrix[index1][INDEX.connected][index2] += [particle]
	
	return matrix

func generate_interaction_matrix(initial_state : Array, final_state : Array, degree_strength : int,
 same_hadronic_particles : Array, unique_matrices : Array) -> Array:
	var interaction_matrix := []
	var state_interactions := initial_state.duplicate(true) + final_state.duplicate(true)
	var state_particles := []
	var connect_straight := false

	for i in range(state_interactions.size()):
		for j in range(state_interactions[i].size()):
			state_interactions[i][j] = remove_anti(state_interactions[i][j])
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
			var temp_state_particles := state_particles.duplicate(true)
			
			hadron_connect_indicies = get_hadron_connect_indicies(initial_state, final_state, same_hadronic_particles, n)
			
			if connect_straight:
				hadron_connect_indicies.append([0, 1, initial_state[0][0]])
			
			for i in range(hadron_connect_indicies.size()):
				var particle : GLOBALS.Particle = remove_anti(hadron_connect_indicies[i][2])
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

func get_possible_N_same_connections(max_N : int, N_state_particles : int, degree : int) -> Array:
	var possible_N := []
	
	for i in range(max_N + 1):
		if is_connection_number_possible(N_state_particles - 2*i, degree):
			possible_N.append(i)
	
	return possible_N

func get_hadron_connect_indicies(initial_state_original : Array, final_state_original : Array, same_particles : Array, n : int):
	var indicies := []
	var initial_state := initial_state_original.duplicate(true)
	var initial_range := range(initial_state.size())
	initial_range.shuffle()
	var final_state := final_state_original.duplicate(true)
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
					indicies.append([j + initial_state.size(), i, remove_anti(particle)])
				else:
					indicies.append([i, j + initial_state.size(), remove_anti(particle)])
	
	return indicies

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

func possible_interaction(current_num : int, connection_number : int,
 unconnected_particles : Array, num_interactions : int, four_interaction : bool) -> bool:
	var new_unconnected_size = (unconnected_particles.size() + (INTERACTION_SIZE + int(four_interaction) - connection_number)) - connection_number
	var num_interactions_left = num_interactions - (current_num + int(four_interaction))
	
	if connection_number == 0 or new_unconnected_size > INTERACTION_SIZE * num_interactions_left:
		return false
	
	if new_unconnected_size == 0 and num_interactions_left == 0:
		return true
	
	return is_connection_number_possible(new_unconnected_size, num_interactions_left)

func is_connection_number_possible(n_unconnected : int, n_interactions : int) -> bool:
	var counter = n_interactions * INTERACTION_SIZE
	
	if n_interactions == 1:
		return n_unconnected == INTERACTION_SIZE
	
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

func compare_quantum_numbers(state1 : Array, state2 : Array) -> int:
	for i in range(1, NUM_QUANTUM_NUMBERS):
		var state1_quantum_sum = 0
		var state2_quantum_sum = 0
		
		for interaction in state1:
			for particle in interaction:
				state1_quantum_sum += sign(particle) * GLOBALS.QUANTUM_NUMBERS[remove_anti(particle)][i]
			
		for interaction in state2:
			for particle in interaction:
				state2_quantum_sum += sign(particle) * GLOBALS.QUANTUM_NUMBERS[remove_anti(particle)][i]
		
		if !is_equal_approx(state1_quantum_sum, state2_quantum_sum):
			if i <= 6:
				return INVALID
			else:
				return WEAK
		
	return NOT_WEAK

func is_anti(particle) -> bool:
	return particle < 0.0

func remove_anti(particle) -> GLOBALS.Particle:
	return abs(particle)

func add_anti(particle) -> GLOBALS.Particle:
	return -abs(particle)

func create_particles(matrix: Array):
	var drawing_interactions := get_tree().get_nodes_in_group('drawing_interactions')
	
	for i in range(matrix.size()):
		for j in range(matrix.size()):
			var connection = matrix[i][INDEX.connected][j]
			if connection != []:
				var particle = connection[0]
				var l = Line.instantiate()
				l.points[0] = drawing_interactions[i].position
				l.points[1] = drawing_interactions[j].position
				l.type = particle
				l.placed = true
				l.visible = false
				
				Level.add_child(l)

func get_connections(matrix: Array, index: int):
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
					if remove_anti(particle) in SHADED_PARTICLES[shade]:
						return true
			INDEX.unconnected:
				if remove_anti(connection) in SHADED_PARTICLES[shade]:
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
			var particle = remove_anti(matrix[i][INDEX.connected][j][0])
			if !particle in GLOBALS.DIRECTIONAL_PARTICLES:
				var l = Line.instantiate()
				l.points[0] = drawing_interactions[i].position
				l.points[1] = drawing_interactions[j].position
				
				l.placed = true
				l.type = particle
				
				Level.add_child(l)
				
		j_index += 1
	
	Level.colourful()

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
