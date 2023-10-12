extends Node

const MAX_REQUIRED_SOLUTION_COUNT : int = 4

const MAX_NEXT_INTERACTION_ATTEMPTS : int = 100
const MAX_INTERACTION_GENERATION_ATTEMPTS : int = 100
const MAX_SOLUTION_GENERATION_ATTEMPTS : int = 100

const MIN_PARTICLE_COUNT: int = 3
const MAX_PARTICLE_COUNT: int = 6

var SolutionGeneration: Node

func init(solution_generation: Node) -> void:
	SolutionGeneration = solution_generation

func generate(
	use_hadrons: bool, useable_particles: Array[GLOBALS.Particle] = get_all_particles()
) -> Problem:
	var problem := Problem.new()
	
	var state_interactions : Array
	for _interaction_generation_attempt in range(MAX_INTERACTION_GENERATION_ATTEMPTS):
		state_interactions = generate_state_interactions(get_useable_state_interactions(use_hadrons, useable_particles))
		
		if state_interactions == []:
			continue
		
		var solution_found: bool = true
		for _solution_generation_attempt in range(MAX_SOLUTION_GENERATION_ATTEMPTS):
			if SolutionGeneration.generate_diagrams(
				state_interactions[StateLine.StateType.Initial], state_interactions[StateLine.StateType.Final], 0, 6,
				SolutionGeneration.generate_useable_interactions_from_particles(useable_particles), SolutionGeneration.Find.One
			) == [null]:
				solution_found = false
			
			break
		
		if solution_found:
			break
	
	problem.state_interactions = state_interactions
	problem.allowed_particles = useable_particles
	
	return problem

func get_all_particles() -> Array[GLOBALS.Particle]:
	var all_particles: Array[GLOBALS.Particle] = []
	
	for particle in GLOBALS.Particle.values():
		if particle == GLOBALS.Particle.none:
			continue
		
		if base_particle(particle) in GLOBALS.GENERAL_PARTICLES:
			continue
		
		all_particles.push_back(particle)
	
	return all_particles

func anti(particle: GLOBALS.Particle) -> int:
	return sign(particle)

func anti_particle(particle: GLOBALS.Particle) -> GLOBALS.Particle:
	return -particle as GLOBALS.Particle

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

func calc_W_count(state_factor: int, state_interaction: Array) -> int:
	return state_factor * (state_interaction.count(GLOBALS.Particle.W) - state_interaction.count(GLOBALS.Particle.anti_W))

func get_useable_hadrons(useable_particles: Array[GLOBALS.Particle]) -> Array:
	var useable_hadrons : Array = []
	
	for hadron in GLOBALS.Hadrons.values():
		for hadron_content in GLOBALS.HADRON_QUARK_CONTENT[hadron]:
			if hadron_content.all(func(quark: GLOBALS.Particle): return quark in useable_particles):
				useable_hadrons.push_back(hadron_content)
	
	return useable_hadrons

func get_possible_interaction_count(degree: int) -> Array:
	return range(ceil(3*degree/2.0), 3*degree, 2)

func generate_state_interactions(useable_state_interactions: Array) -> Array:
	var quantum_number_difference: Array = []
	quantum_number_difference.resize(GLOBALS.QuantumNumber.size())
	quantum_number_difference.fill(0)
	
	var interaction_count: int = randi_range(MIN_PARTICLE_COUNT, MAX_PARTICLE_COUNT)
	var interaction_count_left: int = interaction_count
	var state_interactions : Array = [[], []]
	var current_state : StateLine.StateType = StateLine.StateType.Initial
	var W_count : int = 0
	
	for _attempt in range(MAX_NEXT_INTERACTION_ATTEMPTS):
		var state_factor : int = StateLine.state_factor[current_state]
		var next_state_interaction := get_next_state_interaction(
			quantum_number_difference, useable_state_interactions, interaction_count, interaction_count_left, W_count, state_factor
		)
		
		current_state = (current_state + 1) % 2 as StateLine.StateType
		
		if next_state_interaction == []:
			continue
		
		interaction_count_left -= 1
		quantum_number_difference = accum_state_interaction_quantum_numbers(next_state_interaction, quantum_number_difference, state_factor)
		state_interactions[current_state].push_back(next_state_interaction)
		W_count += calc_W_count(state_factor, next_state_interaction)
		
		if interaction_count_left == 0:
			return state_interactions
	
	return []

func get_next_state_interaction(
	quantum_number_difference: Array, useable_state_interactions: Array, interaction_count: int, interaction_count_left: int,
	W_count: int, state_factor: int
) -> Array:
	
	var possible_next_state_interactions := useable_state_interactions.filter(
		func(state_interaction: Array):
			return is_state_interaction_possible(
				state_interaction, quantum_number_difference, interaction_count, interaction_count_left, W_count, state_factor
			)
	)
	
	return possible_next_state_interactions.pick_random() if possible_next_state_interactions.size() != 0 else []

func accum_state_interaction_quantum_numbers(state_interaction: Array, accum_quantum_numbers: Array, state_factor: int) -> Array:
	var new_quantum_numbers := accum_quantum_numbers.duplicate(true)
	
	for particle in state_interaction:
		for quantum_number in GLOBALS.QuantumNumber.values():
			new_quantum_numbers[quantum_number] += (
				anti(particle) * state_factor * GLOBALS.QUANTUM_NUMBERS[base_particle(particle)][quantum_number]
			)
	
	return new_quantum_numbers

func is_state_interaction_possible(
	state_interaction: Array, quantum_number_difference: Array, interaction_count: int, interaction_count_left: int, W_count: int,
	state_factor: int
) -> bool:
	
	var new_interaction_count_left : int = interaction_count_left - 1
	var new_quantum_number_difference := accum_state_interaction_quantum_numbers(state_interaction, quantum_number_difference, state_factor)
	var new_W_count = W_count + calc_W_count(state_factor, state_interaction)
	
	for quantum_number in GLOBALS.QuantumNumber.values():
		if !is_quantum_number_difference_possible(
			new_quantum_number_difference[quantum_number], quantum_number, new_interaction_count_left, new_W_count
		):
			return false
	
	return true

func is_quantum_number_difference_possible(
	quantum_number_difference: float, quantum_number: GLOBALS.QuantumNumber, state_interaction_count_left: int, W_count: int
) -> bool:
	
	var can_be_different: bool = quantum_number in GLOBALS.WEAK_QUANTUM_NUMBERS and W_count != 0
	
	if abs(quantum_number_difference) > state_interaction_count_left * 3 + int(can_be_different) * abs(W_count):
		return false
	
	return true

func calculate_solution_count(degree: int, generated_solution_count: int) -> int:
	if degree <= 4:
		return min(generated_solution_count, MAX_REQUIRED_SOLUTION_COUNT)
	
	return 1
















