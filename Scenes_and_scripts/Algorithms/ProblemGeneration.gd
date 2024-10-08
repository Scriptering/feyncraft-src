extends Node

enum HadronFrequency {Always, Allowed, Never}

const MAX_REQUIRED_SOLUTION_COUNT : int = 4

const MASS_PRECISION: float = 1e-4

const MAX_NEXT_INTERACTION_ATTEMPTS : int = 100
const MAX_INTERACTION_GENERATION_ATTEMPTS : int = 300

const g_min_degree: int = 2
const g_max_degree: int = 5

var g_useable_particles : PackedInt32Array = []

var chance_of_hadrons: float = 0.4

var total_tries: int = 0

func generate(
	min_particle_count: int = 4,
	max_particle_count: int = 5,
	use_hadrons: HadronFrequency = HadronFrequency.Allowed,
	useable_particles: Array[ParticleData.Particle] = get_all_particles(),
	set_seed: int = Time.get_ticks_usec()
) -> Problem:
	
	#set_seed = 31607767
	seed(set_seed)
	
	total_tries = 0
	
	if !useable_particles.any(
		func(particle: ParticleData.Particle) -> bool:
			return particle in ParticleData.BOSONS
	):
		return null
	
	g_useable_particles = useable_particles

	var problem := Problem.new()

	var useable_state_interactions := get_useable_state_interactions(use_hadrons, useable_particles)
	var state_particles : Array[Array] = get_state_particles(
		min_particle_count, max_particle_count, useable_state_interactions, use_hadrons
	)
	
	problem.state_interactions = state_particles
	problem.allowed_particles = useable_particles
	
	print("problem found")
	
	print(total_tries)
	
	return problem

func are_state_interactions_valid(state_interactions: Array) -> bool:
	if state_interactions.is_empty():
		return false
	
	if !is_energy_conserved(state_interactions):
		return false
		
	if is_lone_hadron_decay(state_interactions):
		return false
	
	return true

func get_useable_particles_from_interaction_checks(checks: Array[bool]) -> Array[ParticleData.Particle]:
	var useable_particles: Array[ParticleData.Particle] = []
	
	var add_charged_leptons: bool = false
	var add_quarks: bool = false
	var add_neutrinos: bool = false
	
	if checks[ParticleData.Force.electromagnetic]:
		useable_particles.append(ParticleData.Particle.photon)
		add_charged_leptons = true
		add_quarks = true
	if checks[ParticleData.Force.strong]:
		useable_particles.append(ParticleData.Particle.gluon)
		add_quarks = true
	if checks[ParticleData.Force.weak]:
		useable_particles.append(ParticleData.Particle.W)
		add_charged_leptons = true
		add_quarks = true
		add_neutrinos = true
		
	if checks[ParticleData.Force.electroweak]:
		useable_particles.append(ParticleData.Particle.Z)
		useable_particles.append(ParticleData.Particle.H)
		add_charged_leptons = true
		add_quarks = true
		add_neutrinos = true
	
	if add_charged_leptons:
		useable_particles += ParticleData.CHARGED_LEPTONS
	if add_quarks:
		useable_particles += ParticleData.QUARKS
	if add_neutrinos:
		useable_particles += ParticleData.NEUTRINOS

	return useable_particles

func is_energy_conserved(state_interactions: Array) -> bool:
	if state_interactions.all(
		func(state_interaction: Array) -> bool:
			return state_interaction.size() != 1
	):
		return true
	
	var state_base_particles: Array = [[],[]]
	
	for state:StateLine.State in StateLine.STATES:
		for interaction:Array in state_interactions[state]:
			if interaction.size() == 1:
				state_base_particles[state].push_back(ParticleData.base(interaction.front()))
			
			else:
				state_base_particles[state].push_back(ParticleData.base_hadron(
					ParticleData.find_hadron(interaction)
				))
	
	state_base_particles[StateLine.State.Initial].sort_custom(ParticleData.sort_particles)
	state_base_particles[StateLine.State.Final].sort_custom(ParticleData.sort_particles)
	
	if (
		state_base_particles[StateLine.State.Initial]
		== state_base_particles[StateLine.State.Final]
	):
		return true
	
	var state_masses: Array = state_base_particles.map(
		func(base_particles: Array) -> float: 
			return base_particles.reduce(
				func(accum: float, particle: ParticleData.Particle) -> float:
					return accum + ParticleData.PARTICLE_MASSES[particle], 0.0
		)
	)
	
	for state:StateLine.State in StateLine.STATES:
		if state_base_particles[state].size() != 1:
			continue
		
		if state_masses[state] - state_masses[(state + 1) % 2] <= MASS_PRECISION:
			return false
	
	return true

func is_lone_hadron_decay(state_interactions: Array) -> bool:
	if state_interactions[StateLine.State.Initial].size() != 1:
		return false
	
	if state_interactions[StateLine.State.Initial].front().size() == 1:
		return false
	
	if state_interactions[StateLine.State.Final].any(
		func(interaction: Array) -> bool:
			if interaction.size() > 1:
				return true
			
			var particle:ParticleData.Particle = interaction.front()
			return ParticleData.base(particle) not in ParticleData.QUARKS
	):
		return false
	
	var hadron: Array = state_interactions[StateLine.State.Initial].front()
	hadron.sort()
	
	var quarks: Array = []
	for interaction: Array in state_interactions[StateLine.State.Final]:
		quarks += interaction
	quarks.sort()

	return hadron == quarks

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

func get_useable_state_interactions(
	use_hadrons: HadronFrequency,
	useable_particles: Array[ParticleData.Particle]
) -> Array[PackedInt32Array]:
	var useable_state_interactions: Array[PackedInt32Array] = []
	
	for particle:ParticleData.Particle in useable_particles:
		useable_state_interactions.push_back(PackedInt32Array([particle]))
		
		if particle in ParticleData.SHADED_PARTICLES:
			useable_state_interactions.push_back(PackedInt32Array([anti_particle(particle)]))
	
	if use_hadrons == HadronFrequency.Never:
		return useable_state_interactions
	
	useable_state_interactions.append_array(get_useable_hadrons(useable_particles))
	
	return useable_state_interactions

func _calc_W_count(state_factor: int, state_interaction: Array) -> int:
	return state_factor * (state_interaction.count(ParticleData.Particle.W) - state_interaction.count(ParticleData.Particle.anti_W))

func get_useable_hadrons(useable_particles: PackedInt32Array) -> Array:
	var useable_hadrons : Array[PackedInt32Array] = []
	
	for hadron:ParticleData.Hadron in ParticleData.Hadron.values():
		for hadron_content:PackedInt32Array in ParticleData.HADRON_QUARK_CONTENT[hadron]:
			if ArrayFuncs.packed_int_any(
				hadron_content,
				func(quark: ParticleData.Particle) -> bool:
					return abs(quark) not in useable_particles
			):
				continue
			
			useable_hadrons.push_back(hadron_content)
	
	return useable_hadrons

func add_quantum_numbers(
	qnsA: PackedFloat32Array,
	qnsB: PackedFloat32Array,
	factor: int
) -> PackedFloat32Array:
	var sum := qnsA.duplicate()
	
	for i:int in qnsB.size():
		sum[i] += factor * qnsB[i]
	
	return sum

func get_empty_quantum_numbers() -> PackedFloat32Array:
	var quantum_numbers : PackedFloat32Array = []
	quantum_numbers.resize(ParticleData.QuantumNumber.size())
	quantum_numbers.fill(0.0)
	return quantum_numbers

func get_quantum_numbers(particle: PackedInt32Array) -> PackedFloat32Array:
	var quantum_numbers := get_empty_quantum_numbers()
	
	for p:ParticleData.Particle in particle:
		quantum_numbers = add_quantum_numbers(
			quantum_numbers,
			ParticleData.quantum_numbers(p),
			sign(p)
		)
	
	return quantum_numbers

func add_particle(
	particle: PackedInt32Array,
	state_particles: Array[Array],
	state: StateLine.State,
	quantum_number_difference: PackedFloat32Array
) -> void:
	state_particles[state].push_back(particle)
	quantum_number_difference = add_quantum_numbers(
		quantum_number_difference,
		get_quantum_numbers(particle),
		StateLine.state_factor[state]
	)

func get_possible_interaction_count(degree: int) -> Array:
	return range(ceil(3*degree/2.0), 3*degree, 2)

func is_hadron(particles: PackedInt32Array) -> bool:
	return particles.size() > 1

func is_not_hadron(particles: PackedInt32Array) -> bool:
	return !is_hadron(particles)

func rand_state() -> StateLine.State:
	return randi() % 2 as StateLine.State

func get_hadron_count(particle_count:int, use_hadrons: HadronFrequency) -> int:
	if (
		use_hadrons == HadronFrequency.Never
		or use_hadrons == HadronFrequency.Allowed and randf() > chance_of_hadrons
	):
		return 0
	
	return randi_range(1, particle_count)

func get_state_particles(
	min_particle_count: int,
	max_particle_count: int,
	useable_state_particles: Array[PackedInt32Array],
	use_hadrons: HadronFrequency
) -> Array[Array]:
	
	var quantum_number_difference := get_empty_quantum_numbers()
	var particle_count := randi_range(min_particle_count, max_particle_count)
	var hadron_count := get_hadron_count(particle_count, use_hadrons)
	
	if hadron_count == 0:
		useable_state_particles = useable_state_particles.filter(is_not_hadron)
	
	useable_state_particles.shuffle()
	
	var state_particles: Array[Array] = [[], []]
	return get_next_state_particles(
		particle_count,
		quantum_number_difference,
		useable_state_particles,
		state_particles,
		hadron_count
	)

func calc_W_count(particle:PackedInt32Array, W_count: int, state:StateLine.State) -> int:
	if !ParticleData.is_particle(particle[0], ParticleData.Particle.W):
		return W_count
	
	return W_count + sign(particle[0]) * StateLine.state_factor[state]

func get_next_state_particles(
	particle_count: int,
	quantum_number_difference: PackedFloat32Array,
	useable_state_particles: Array[PackedInt32Array],
	state_particles: Array[Array],
	hadron_count: int,
	W_count: int = 0
) -> Array[Array]:
	
	if particle_count == 0:
		total_tries += 1
		if !are_state_interactions_valid(state_particles):
			return []
		
		var solution : ConnectionMatrix = SolutionGeneration.generate_diagrams(
			state_particles[StateLine.State.Initial],
			state_particles[StateLine.State.Final],
			g_min_degree,
			g_max_degree,
			g_useable_particles,
			SolutionGeneration.Find.One
		)[0]
		
		if !solution:
			#print("solution not found")
			#print(state_particles)
			return []
		#print("solution found")
		#print(state_particles)
		return state_particles
	
	var state := rand_state()
	if state_particles[StateLine.State.Initial].is_empty():
		state = StateLine.State.Initial
	elif state_particles[StateLine.State.Final].is_empty():
		state = StateLine.State.Final
	
	var next_useable_state_particles := useable_state_particles.duplicate(true)
	next_useable_state_particles.shuffle()
	for particle: PackedInt32Array in next_useable_state_particles:
		if hadron_count > 0 and is_not_hadron(particle):
			continue

		var new_quantum_number_difference := add_quantum_numbers(
			quantum_number_difference,
			get_quantum_numbers(particle),
			StateLine.state_factor[state]
		)
		
		var next_W_count := calc_W_count(particle, W_count, state)
		
		if !is_quantum_number_difference_possible(
			new_quantum_number_difference, particle_count - 1, next_W_count, hadron_count
		):
			continue
		
		var new_state_particles := state_particles.duplicate(true)
		new_state_particles[state].push_back(particle)
		
		new_state_particles = get_next_state_particles(
			particle_count - 1,
			new_quantum_number_difference,
			useable_state_particles if hadron_count != 1 else useable_state_particles.filter(is_not_hadron),
			new_state_particles,
			hadron_count - int(is_hadron(particle)),
			next_W_count
		)
		
		if new_state_particles.is_empty():
			continue
		
		return new_state_particles
		
	return []

func generate_state_interactions(
	min_particle_count: int, max_particle_count: int, useable_state_interactions: Array, use_hadrons: HadronFrequency
) -> Array:
	var quantum_number_difference: Array = []
	quantum_number_difference.resize(ParticleData.QuantumNumber.size())
	quantum_number_difference.fill(0)
	
	var interaction_count: int = randi_range(min_particle_count, max_particle_count)
	var interaction_count_left: int = interaction_count
	var state_interactions : Array = [[], []]
	var W_count : int = 0
	
	for particle_count in max_particle_count:
		var current_state : int = randi() % 2
		
		if particle_count < 2:
			current_state = (particle_count % 2) as StateLine.State
		
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
		
		if next_state_interaction == []:
			return []
		
		interaction_count_left -= 1
		quantum_number_difference = accum_state_interaction_quantum_numbers(next_state_interaction, quantum_number_difference, state_factor)
		state_interactions[current_state].push_back(next_state_interaction)
		#W_count += calc_W_count(state_factor, next_state_interaction)
		
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
	var new_W_count := W_count
	
	return !is_quantum_number_difference_possible(
		new_quantum_number_difference, new_interaction_count_left, new_W_count, 0
	)

func is_quantum_number_difference_possible(
	quantum_number_difference: PackedFloat32Array,
	particle_count: int,
	W_count: int,
	hadron_count: int
) -> bool:
	
	for quantum_number:ParticleData.QuantumNumber in ParticleData.QuantumNumber.values():
		var can_be_different: bool = W_count != 0 and quantum_number in ParticleData.WEAK_QUANTUM_NUMBERS
		
		var difference_allowed: int = particle_count
		if hadron_count > 0 and ParticleData.is_quark_quantum_number(quantum_number):
			difference_allowed += 2 * hadron_count

		if abs(quantum_number_difference[quantum_number]) > difference_allowed + int(can_be_different) * abs(W_count):
			return false
		
	return true

func setup_new_problem(problem: Problem) -> Problem:
	if !problem:
		return null
	
	if problem.state_interactions.is_empty():
		return null
	
	if problem.state_interactions == [[],[]]:
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
		problem.state_interactions[StateLine.State.Initial],
		problem.state_interactions[StateLine.State.Final],
		min_degree, max_degree,
		problem.allowed_particles,
		find
	)
	
	if generated_solutions == [null]:
		return null
	
	problem.degree = generated_solutions.front().state_count[StateLine.State.None]
	problem.solution_count = calculate_solution_count(problem.degree, generated_solutions.size())
	
	return problem

func calculate_solution_count(degree: int, generated_solution_count: int) -> int:
	if degree <= 4:
		return min(generated_solution_count, MAX_REQUIRED_SOLUTION_COUNT)
	
	return 1
