extends Node

enum HadronFrequency {Always, Allowed, Never}

const MAX_REQUIRED_SOLUTION_COUNT : int = 4

const MAX_NEXT_INTERACTION_ATTEMPTS : int = 100
const MAX_INTERACTION_GENERATION_ATTEMPTS : int = 1000

var SolutionGeneration: Node

func init(solution_generation: Node) -> void:
	SolutionGeneration = solution_generation

func generate(
	min_particle_count: int = 3, max_particle_count: int = 6, use_hadrons: HadronFrequency = HadronFrequency.Allowed,
	useable_particles: Array[ParticleData.Particle] = get_all_particles()
) -> Problem:
	var problem := Problem.new()

	var state_interactions : Array
	var useable_state_interactions: Array = get_useable_state_interactions(use_hadrons, useable_particles)
	
	if !useable_particles.any(
		func(particle: ParticleData.Particle) -> bool:
			return particle in ParticleData.BOSONS
	):
		return null
	
	for _interaction_generation_attempt in MAX_INTERACTION_GENERATION_ATTEMPTS:
		print("problem generation attempt")
		
		for _attempt in MAX_INTERACTION_GENERATION_ATTEMPTS:
			state_interactions = generate_state_interactions(min_particle_count, max_particle_count, useable_state_interactions, use_hadrons)

			if state_interactions != [] and is_energy_conserved(state_interactions):
				break
		
		if state_interactions == []:
			break
		
		if SolutionGeneration.generate_diagrams(
			state_interactions[StateLine.StateType.Initial], state_interactions[StateLine.StateType.Final], 0, 6,
			SolutionGeneration.generate_useable_interactions_from_particles(useable_particles), SolutionGeneration.Find.One
		) != [null]:
			break
	
	problem.state_interactions = state_interactions
	problem.allowed_particles = useable_particles
	
	print("problem found")
	
	return problem

func get_useable_particles_from_interaction_checks(checks: Array[bool]) -> Array[ParticleData.Particle]:
	var useable_particles: Array[ParticleData.Particle] = []
	
	useable_particles += ParticleData.FERMIONS
	
	if checks[0]:
		useable_particles.append(ParticleData.Particle.photon)
	if checks[1]:
		useable_particles.append(ParticleData.Particle.gluon)
	if checks[2]:
		useable_particles.append(ParticleData.Particle.W)
	if checks[3]:
		useable_particles.append(ParticleData.Particle.Z)
		useable_particles.append(ParticleData.Particle.H)
	
	return useable_particles

func is_energy_conserved(state_interactions: Array) -> bool:
	if state_interactions.all(
		func(state_interaction: Array) -> bool:
			return state_interaction.size() != 1
	):
		return true
	
	var state_base_particles: Array = state_interactions.map(
		func(state_interaction: Array) -> Array:
			return ArrayFuncs.flatten(state_interaction).map(
			func(particle: ParticleData.Particle) -> ParticleData.Particle: 
				return abs(particle) as ParticleData.Particle
	))
	
	var state_masses: Array = state_base_particles.map(
		func(base_particles: Array) -> float: 
			return base_particles.reduce(
				func(accum: float, particle: ParticleData.Particle) -> float:
					return accum + ParticleData.PARTICLE_MASSES[particle], 0.0
		)
	)
	
	for state:StateLine.StateType in StateLine.STATES:
		if state_base_particles[state].size() != 1:
			continue
		
		if state_masses[state] < state_masses[(state + 1) % 2] - 0.005:
			return false
	
	return true

func get_all_particles() -> Array[ParticleData.Particle]:
	var all_particles: Array[ParticleData.Particle] = []
	
	for particle:ParticleData.Particle in ParticleData.Particle.values():
		if particle == ParticleData.Particle.none:
			continue
		
		if base_particle(particle) in ParticleData.GENERAL_PARTICLES:
			continue
		
		all_particles.push_back(particle)
	
	return all_particles

func anti(particle: ParticleData.Particle) -> int:
	return sign(particle)

func anti_particle(particle: ParticleData.Particle) -> ParticleData.Particle:
	return -particle as ParticleData.Particle

func base_particle(particle: ParticleData.Particle) -> ParticleData.Particle:
	return abs(particle)

func get_useable_state_interactions(use_hadrons: HadronFrequency, useable_particles: Array[ParticleData.Particle]) -> Array:
	
	var useable_state_interactions: Array = []
	
	for particle:ParticleData.Particle in useable_particles:
		useable_state_interactions.push_back([particle])
		
		if particle in ParticleData.SHADED_PARTICLES:
			useable_state_interactions.push_back([anti_particle(particle)])
	
	if use_hadrons == HadronFrequency.Never:
		return useable_state_interactions
	
	useable_state_interactions.append_array(get_useable_hadrons(useable_particles))
	
	return useable_state_interactions

func calc_W_count(state_factor: int, state_interaction: Array) -> int:
	return state_factor * (state_interaction.count(ParticleData.Particle.W) - state_interaction.count(ParticleData.Particle.anti_W))

func get_useable_hadrons(useable_particles: Array[ParticleData.Particle]) -> Array:
	var useable_hadrons : Array = []
	
	for hadron:ParticleData.Hadrons in ParticleData.Hadrons.values():
		for hadron_content:Array in ParticleData.HADRON_QUARK_CONTENT[hadron]:
			if hadron_content.all(
				func(quark: ParticleData.Particle) -> bool:
					return abs(quark) in useable_particles
			):
				useable_hadrons.push_back(hadron_content)
	
	return useable_hadrons

func get_possible_interaction_count(degree: int) -> Array:
	return range(ceil(3*degree/2.0), 3*degree, 2)

func generate_state_interactions(
	min_particle_count: int, max_particle_count: int, useable_state_interactions: Array, use_hadrons: HadronFrequency
) -> Array:
	var quantum_number_difference: Array = []
	quantum_number_difference.resize(ParticleData.QuantumNumber.size())
	quantum_number_difference.fill(0)
	
	var interaction_count: int = randi_range(min_particle_count, max_particle_count)
	var interaction_count_left: int = interaction_count
	var state_interactions : Array = [[], []]
	var current_state : StateLine.StateType = StateLine.StateType.Initial
	var W_count : int = 0
	
	for particle_count in max_particle_count:
		var state_factor : int = StateLine.state_factor[current_state]
		
		var next_state_interaction: Array
		if particle_count == 0 and use_hadrons == HadronFrequency.Always:
			next_state_interaction = get_next_state_interaction(
				quantum_number_difference,
				useable_state_interactions.filter(
					func(state_interaction: Array) -> bool:
						return state_interaction.size() > 1
			),
			interaction_count_left,
			W_count,
			state_factor
			)

		else:
			next_state_interaction = get_next_state_interaction(
				quantum_number_difference, useable_state_interactions, interaction_count_left, W_count, state_factor
			)
		
		current_state = (current_state + 1) % 2 as StateLine.StateType
		
		if next_state_interaction == []:
			return []
		
		interaction_count_left -= 1
		quantum_number_difference = accum_state_interaction_quantum_numbers(next_state_interaction, quantum_number_difference, state_factor)
		state_interactions[current_state].push_back(next_state_interaction)
		W_count += calc_W_count(state_factor, next_state_interaction)
		
		if interaction_count_left == 0:
			return state_interactions
	
	return []

func get_next_state_interaction(
	quantum_number_difference: Array, useable_state_interactions: Array, interaction_count_left: int,
	W_count: int, state_factor: int
) -> Array:
	
	var possible_next_state_interactions := useable_state_interactions.filter(
		func(state_interaction: Array) -> bool:
			return is_state_interaction_possible(
				state_interaction,
				quantum_number_difference,
				interaction_count_left,
				W_count,
				state_factor
			)
	)
	
	return possible_next_state_interactions.pick_random() if possible_next_state_interactions.size() != 0 else []

func accum_state_interaction_quantum_numbers(state_interaction: Array, accum_quantum_numbers: Array, state_factor: int) -> Array:
	var new_quantum_numbers := accum_quantum_numbers.duplicate(true)
	
	for particle:ParticleData.Particle in state_interaction:
		for quantum_number:ParticleData.QuantumNumber in ParticleData.QuantumNumber.values():
			new_quantum_numbers[quantum_number] += (
				anti(particle) * state_factor * ParticleData.QUANTUM_NUMBERS[base_particle(particle)][quantum_number]
			)
	
	return new_quantum_numbers

func is_state_interaction_possible(
	state_interaction: Array, quantum_number_difference: Array, interaction_count_left: int, W_count: int,
	state_factor: int
) -> bool:
	
	var new_interaction_count_left : int = interaction_count_left - 1
	var new_quantum_number_difference := accum_state_interaction_quantum_numbers(state_interaction, quantum_number_difference, state_factor)
	var new_W_count := W_count + calc_W_count(state_factor, state_interaction)
	
	for quantum_number:ParticleData.QuantumNumber in ParticleData.QuantumNumber.values():
		if !is_quantum_number_difference_possible(
			new_quantum_number_difference[quantum_number], quantum_number, new_interaction_count_left, new_W_count
		):
			return false
	
	return true

func is_quantum_number_difference_possible(
	quantum_number_difference: float, quantum_number: ParticleData.QuantumNumber, state_interaction_count_left: int, W_count: int
) -> bool:
	
	var can_be_different: bool = quantum_number in ParticleData.WEAK_QUANTUM_NUMBERS and W_count != 0
	
	var difference_allowed: int = 1 if quantum_number in [ParticleData.QuantumNumber.electron, ParticleData.QuantumNumber.muon, ParticleData.QuantumNumber.tau] else 3
	
	if abs(quantum_number_difference) > state_interaction_count_left * difference_allowed + int(can_be_different) * abs(W_count):
		return false
	
	return true

func setup_new_problem(problem: Problem) -> Problem:
	if !problem:
		return null
	
	var min_degree: int = problem.degree if problem.custom_degree else 1
	var max_degree: int = problem.degree if problem.custom_degree else 6
	
	var find: int = SolutionGeneration.Find.One if problem.state_interactions.any(
		func(state_interaction: Array) -> bool:
			return state_interaction.any(
				func(interaction: Array) -> bool:
					return interaction.size() > 1
	)) else SolutionGeneration.Find.LowestOrder
	
	var generated_solutions: Array[ConnectionMatrix] = SolutionGeneration.generate_diagrams(
		problem.state_interactions[StateLine.StateType.Initial],
		problem.state_interactions[StateLine.StateType.Final],
		min_degree, max_degree,
		SolutionGeneration.get_useable_interactions_from_particles(problem.allowed_particles),
		find
	)
	
	if generated_solutions == [null]:
		return null
	
	problem.degree = generated_solutions.front().state_count[StateLine.StateType.None]
	problem.solution_count = calculate_solution_count(problem.degree, generated_solutions.size())
	
	return problem

func calculate_solution_count(degree: int, generated_solution_count: int) -> int:
	if degree <= 4:
		return min(generated_solution_count, MAX_REQUIRED_SOLUTION_COUNT)
	
	return 1
