class_name Problem
extends Resource

@export var limited_particles: bool = false
@export var custom_solutions: bool = false

@export var submitted_diagrams : Array[DrawingMatrix] = []
@export var solutions : Array[DrawingMatrix] = []
@export var allowed_particles : Array[GLOBALS.Particle] = []
@export var state_interactions : Array = [[], []]

func is_submission_valid(submission: DrawingMatrix) -> bool:
	if is_submission_duplicate(submission):
		return false
	
	if !is_submission_solution(submission):
		return false
	
	return true

func is_submission_duplicate(submission: DrawingMatrix) -> bool:
	var reduced_submission: ConnectionMatrix = submission.reduce_to_connection_matrix()
	
	return submitted_diagrams.any(
		func(submitted_diagram: DrawingMatrix):
			return submitted_diagram.reduce_to_connection_matrix().is_duplicate(reduced_submission)
	)

func is_submission_solution(submission: DrawingMatrix) -> bool:
	var reduced_submission: ConnectionMatrix = submission.reduce_to_connection_matrix()
	
	if !custom_solutions:
		return is_matching_states(reduced_submission)
	
	return solutions.any(
		func(solution: DrawingMatrix):
			return solution.reduce_to_connection_matrix().is_duplicate(reduced_submission)
	)

func submit_diagram(submission: DrawingMatrix) -> void:
	submitted_diagrams.append(submission)

func get_state_interaction(state: StateLine.StateType) -> Array:
	return state_interactions[state]

func get_sorted_states(states: Array) -> Array:
	return states.map(func(interactions):
		return interactions.map(func(state_interaction):
			var sorted_interaction = state_interaction.duplicate(true)
			sorted_interaction.sort()
			return sorted_interaction
		)
	)

func is_matching_states(reduced_submission: ConnectionMatrix) -> bool:
	var sorted_submitted_states: Array = get_sorted_states([
		reduced_submission.get_state_interactions(StateLine.StateType.Initial),
		reduced_submission.get_state_interactions(StateLine.StateType.Final)
	])
	var sorted_states: Array = get_sorted_states(state_interactions)
	
	for state in [StateLine.StateType.Initial, StateLine.StateType.Final]:
		if (
			sorted_submitted_states[state].any(
				func(state_interaction: Array): return state_interaction not in sorted_states[state]
			) or
			sorted_states[state].any(
				func(state_interaction: Array): return state_interaction not in sorted_submitted_states[state]
			)
		):
			return false
	
	return true

