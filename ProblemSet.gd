class_name ProblemSet
extends Resource

signal end_reached

@export var title: String = ""
@export var problems: Array[Problem] = []
@export var highest_index_reached: int = 0
@export var current_index: int: set = _set_current_index
var current_problem: Problem:
	get:
		if problems.size() == 0:
			return null

		return problems[current_index]
	set(_new_value):
		return
@export var is_custom: bool = true
@export var is_default: bool = false

func _set_current_index(new_value: int) -> void:
	current_index = clamp(new_value, 0, problems.size()-1)
	highest_index_reached = max(highest_index_reached, new_value)

	if new_value == problems.size():
		end_reached.emit()

func previous_problem() -> Problem:
	self.current_index -= 1
	return self.current_problem

func next_problem() -> Problem:
	self.current_index += 1
	return self.current_problem

func prepare_for_export() -> void:
	highest_index_reached = 0
	current_index = 0
	is_custom = false
