extends Node

func generate(use_hadrons: bool, min_degree: int, max_degree: int, useable_particles: Array[GLOBALS.Particle]) -> Problem:
	var problem := Problem.new()
	
	var state_interactions : Array = generate_state_interactions(
		get_useable_state_interactions(use_hadrons, useable_particles),
		randi_range(min_degree, max_degree),
		GLOBALS.Particle.W in useable_particles
	)
	
	return problem

func anti(particle: GLOBALS.Particle) -> int:
	return sign(particle)

func anti_particle(particle: GLOBALS.Particle) -> GLOBALS.Particle:
	return -particle

func base_particle(particle: GLOBALS.Particle) -> GLOBALS.Particle:
	return abs(particle)

func get_useable_state_interactions(use_hadrons: bool, useable_particles: Array[GLOBALS.Particle]) -> Array:
	
	var useable_state_interactions: Array = []
	
	for particle in useable_particles:
		useable_state_interactions.push_back([particle])
		
		if particle in GLOBALS.SHADED_PARTICLES:
			useable_state_interactions.push_back([anti_particle(particle)])
	
	if !use_hadrons:
		return useable_state_interactions
	
	useable_state_interactions.append_array(get_useable_hadrons(useable_particles))
	
	return useable_state_interactions

func get_useable_hadrons(useable_particles: Array[GLOBALS.Particle]) -> Array:
	var useable_hadrons : Array = []
	
	for hadron in GLOBALS.HADRON_QUARK_CONTENT:
		for hadron_content in hadron:
			if hadron_content.all(func(quark: GLOBALS.Particle): return quark in useable_particles):
				useable_hadrons.push_back(hadron_content)
	
	return useable_hadrons

func get_possible_interaction_count(degree: int) -> Array:
	return range(ceil(3*degree/2), 3*degree, 2)

func generate_state_interactions(useable_state_interactions: Array, degree: int, can_weak: bool) -> Array:
	var interaction_count : int = get_possible_interaction_count(degree).pick_random()
	var quantum_number_difference: Array = []
	quantum_number_difference.resize(GLOBALS.QuantumNumber.size())
	quantum_number_difference.fill(0)
	
	var state_interactions : Array = [[], []]
	var current_state : StateLine.StateType = StateLine.StateType.Initial
	var interaction_count_left : int = interaction_count
	
	for i in range(interaction_count):
		var state_factor : int = StateLine.state_factor[current_state]
		var next_state_interaction := get_next_state_interaction(
			quantum_number_difference, useable_state_interactions, interaction_count_left, can_weak, state_factor
		)
		
		
	
	
	return []

func get_next_state_interaction(
	quantum_number_difference: Array, useable_state_interactions: Array, interaction_count_left: int, can_weak: bool, state_factor: int
) -> Array:
	return useable_state_interactions.filter(
		func(state_interaction: Array):
			return is_state_interaction_possible(
				state_interaction, quantum_number_difference, interaction_count_left, can_weak, state_factor
			)
	).pick_random()

func accum_state_interaction_quantum_numbers(state_interaction: Array, accum_quantum_numbers: Array, state_factor: int) -> Array:
	var new_quantum_numbers := accum_quantum_numbers.duplicate(true)
	
	for particle in state_interaction:
		for quantum_number in GLOBALS.QuantumNumber:
			new_quantum_numbers[quantum_number] += (
				anti(particle) * state_factor * GLOBALS.QUANTUM_NUMBERS[base_particle(particle)][quantum_number]
			)
	
	return new_quantum_numbers

func is_state_interaction_possible(
	state_interaction: Array, quantum_number_difference: Array, interaction_count_left: int, can_weak: bool, state_factor: int
) -> bool:
	
	if interaction_count_left < state_interaction.size():
		return false
	
	var new_interaction_count_left : int = interaction_count_left - state_interaction.size()
	var new_quantum_number_difference := accum_state_interaction_quantum_numbers(state_interaction, quantum_number_difference, state_factor)
	
	if !is_quantum_number_difference_possible(new_quantum_number_difference, new_interaction_count_left, can_weak):
		return false
	
	
	return true

func is_quantum_number_difference_possible(quantum_number_difference: Array, state_interaction_count_left: int, can_weak: bool) -> bool:
	
	var can_be_different: Callable = func(quantum_number: int): return quantum_number in GLOBALS.WEAK_QUANTUM_NUMBERS and can_weak
	
	for quantum_number in range(GLOBALS.QuantumNumber.size()):
		if can_be_different.call(quantum_number)
	
	if state_interaction_count_left == 0 and !quantum_number_difference.all(func(quantum_number: float): return quantum_number == 0):
		return false
	
	if quantum_number_difference.any(
		func(quantum_number: float):
			abs(quantum_number) > state_interaction_count_left
	):
		return false
	
	return true


















