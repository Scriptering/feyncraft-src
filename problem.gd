class_name Problem
extends Resource

const LOWEST_ORDER: int = 0

@export var custom_solutions: bool = false
@export var allow_other_solutions: bool = false
@export var custom_solution_count: bool = false
@export var custom_degree: bool = false
@export var limited_particles: bool = false
@export var hide_unavailable_particles: bool = false
@export var title: String = ''
@export var solutions : Array[DrawingMatrix] = []
@export var allowed_particles : Array[ParticleData.Particle] = []
@export var state_interactions : Array = [[], []]
@export var degree : int = LOWEST_ORDER
@export var solution_count : int = 0:
	get:
		if custom_solution_count or !custom_solutions:
			return solution_count
		
		return solutions.size()

func is_submission_valid(submission: DrawingMatrix) -> bool:
	if !is_submission_solution(submission):
		return false
	
	return true

func is_submission_solution(submission: DrawingMatrix) -> bool:
	var reduced_submission: ConnectionMatrix = submission.reduce_to_connection_matrix()
	
	if !custom_solutions or custom_solutions and allow_other_solutions:
		return is_matching_states(reduced_submission)
	
	return solutions.any(
		func(solution: DrawingMatrix) -> bool:
			return solution.reduce_to_connection_matrix().is_duplicate(reduced_submission)
	)

func get_state_interaction(state: StateLine.State) -> Array:
	return state_interactions[state]

func get_sorted_states(states: Array) -> Array:
	return states.map(func(interactions:Array) -> Array:
		return interactions.map(func(state_interaction: Array) -> ParticleData.Hadron:
			if state_interaction.size() == 1:
				return state_interaction.front()
			
			return ParticleData.find_hadron(state_interaction)
		)
	)

func is_matching_states(reduced_submission: ConnectionMatrix) -> bool:
	var sorted_submitted_states: Array = get_sorted_states([
		reduced_submission.get_state_interactions(StateLine.State.Initial),
		reduced_submission.get_state_interactions(StateLine.State.Final)
	])
	var sorted_states: Array = get_sorted_states(state_interactions)
	
	for state:StateLine.State in StateLine.STATES:
		if (
			sorted_submitted_states[state].any(
				func(state_particle: int) -> bool:
					return state_particle not in sorted_states[state]
		) ||
			sorted_states[state].any(
				func(state_particle: int) -> bool:
					return state_particle not in sorted_submitted_states[state]
		)):
			return false
	
	return true
