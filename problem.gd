class_name Problem

var submitted_diagrams : Array[DrawingMatrix] = []
var solutions : Array[DrawingMatrix] = []
var allowed_particles : Array[GLOBALS.Particle] = []
var initial_state : Array = []
var final_state : Array = []

func is_submission_valid(submission: DrawingMatrix) -> bool:
	if is_submission_duplicate(submission):
		return false
	
	if !is_submission_solution(submission):
		return false
	
	return true

func is_submission_duplicate(submission: DrawingMatrix) -> bool:
	return submitted_diagrams.any(
		func(submitted_diagram: DrawingMatrix):
			return submitted_diagram.is_duplicate(submission)
	)

func is_submission_solution(submission: DrawingMatrix) -> bool:
	if solutions.size() == 0:
		return true
	
	return solutions.any(
		func(solution: DrawingMatrix):
			return solution.is_duplicate(submission)
	)
	
