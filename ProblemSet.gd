class_name ProblemSet
extends Resource

signal end_reached

@export var title: String = ""
@export var problems: Array[Problem] = []
@export var highest_index_reached: int = 0
@export var current_index: int: set = _set_current_index
@export var current_problem: Problem:
	get:
		if problems.size() == 0:
			return null
			
		return problems[current_index]
	set(new_value):
		return
@export var limited_particles: bool = false
@export var custom_solutions: bool = false
@export var hidden_particles: bool = false
@export var is_custom: bool = true

func _set_current_index(new_value: int) -> void:
	if new_value >= problems.size():
		end_reached.emit()
	
	current_index = clamp(new_value, 0, problems.size()-1)
	highest_index_reached = max(highest_index_reached, current_index)

func previous_problem() -> Problem:
	self.current_index -= 1
	return self.current_problem

func next_problem() -> Problem:
	self.current_index += 1
	return self.current_problem
