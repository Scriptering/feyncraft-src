class_name ProblemSet

var title: String = ""
var problems: Array[Problem] = []
var highest_index_reached: int = 0
var current_index: int: set = _set_current_index
var current_problem: Problem:
	get:
		return problems[current_index]

func _set_current_index(new_value: int) -> void:
	current_index = clamp(new_value, 0, problems.size()-1)
	highest_index_reached = max(highest_index_reached, current_index)

func previous_problem() -> Problem:
	self.current_index -= 1
	return self.current_problem

func next_problem() -> Problem:
	self.current_index += 1
	return self.current_problem
