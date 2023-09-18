extends PanelContainer

var ProblemSelector: PackedScene = preload("res://Scenes and Scripts/UI/ProblemSelection/problem_selector.tscn")

@onready var problem_container: VBoxContainer = $VBoxContainer/ProblemContainer

var problem_set: ProblemSet

func load_problem_set(_problem_set: ProblemSet) -> void:
	problem_set = _problem_set
	
	for problem in problem_set.problems:
		add_problem(problem, problem_set.is_custom)
	
	update_index_labels()

func add_problem(problem: Problem, is_custom: bool = false) -> void:
	var problem_select: PanelContainer = ProblemSelector.instantiate()
	problem_select.load_problem(problem)
	
	problem_select.move.connect(_problem_moved)
	problem_select.deleted.connect(_problem_deleted)
	
	problem_select.toggle_edit_visiblity(problem_set.is_custom)
	
	problem_container.add_child(problem_select)
	
	problem_select.set_index(problem_container.get_child_count())

func update_index_labels() -> void:
	for i in range(problem_container.get_child_count()):
		problem_container.get_child(i).set_index(i)

func _problem_moved(problem_select: PanelContainer, index_change: int) -> void:
	var current_index: int = problem_container.get_children().find(problem_select)
	var new_index: int = current_index + index_change
	
	move_child(problem_select, new_index)
	
	var temp_problem: Problem = problem_set.problems[new_index]
	problem_set.problems[new_index] = problem_set.problems[current_index]
	problem_set.problems[current_index] = temp_problem
	
	update_index_labels()

func _problem_deleted(problem_select: PanelContainer) -> void:
	var index: int = problem_container.get_children().find(problem_select)
	
	problem_container.remove_child(problem_select)
	problem_set.problems.remove_at(index)
	
	update_index_labels()
