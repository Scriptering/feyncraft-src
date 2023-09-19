extends PanelContainer

signal problem_played
signal back

var ProblemSelector: PackedScene = preload("res://Scenes and Scripts/UI/ProblemSelection/problem_selector.tscn")

@onready var problem_container: VBoxContainer = $VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer/ProblemContainer

var problem_set: ProblemSet

func _ready() -> void:
	problem_played.connect(EVENTBUS.enter_game)
	
func load_problem_set(_problem_set: ProblemSet) -> void:
	problem_set = _problem_set
	
	$VBoxContainer/HBoxContainer/Title.text = problem_set.title
	
	clear_problems()
	
	for problem in problem_set.problems:
		add_problem(problem, problem_set.is_custom)
	
	update_index_labels()

func clear_problems() -> void:
	for child in problem_container.get_children():
		child.queue_free()

func add_problem(problem: Problem, is_custom: bool = false) -> void:
	var problem_select: PanelContainer = ProblemSelector.instantiate()
	
	problem_set.problems.push_back(problem)
	
	problem_select.move.connect(_problem_moved)
	problem_select.deleted.connect(_problem_deleted)
	problem_select.play.connect(play_problem)
	
	problem_select.toggle_edit_visiblity(problem_set.is_custom)
	
	problem_container.add_child(problem_select)
	
	problem_select.load_problem(problem)
	problem_select.set_index(problem_container.get_child_count()-1)
	
	update()

func update() -> void:
	update_index_labels()
	
	for problem in problem_container.get_children():
		problem.update()

func update_index_labels() -> void:
	for i in range(problem_container.get_child_count()):
		problem_container.get_child(i).set_index(i)

func _problem_moved(problem_select: PanelContainer, index_change: int) -> void:
	var current_index: int = problem_container.get_children().find(problem_select)
	var new_index: int = current_index + index_change
	
	problem_container.move_child(problem_select, new_index)
	
	var temp_problem: Problem = problem_set.problems[new_index]
	problem_set.problems[new_index] = problem_set.problems[current_index]
	problem_set.problems[current_index] = temp_problem
	
	update_index_labels()

func _problem_deleted(problem_select: PanelContainer) -> void:
	var index: int = problem_container.get_children().find(problem_select)
	
	problem_container.remove_child(problem_select)
	problem_set.problems.remove_at(index)
	
	update_index_labels()

func create_problem() -> void:
	var problem: Problem = Problem.new()
	add_problem(problem, true)

func _on_add_problem_pressed() -> void:
	create_problem()

func play_problem(problem: Problem) -> void:
	problem_played.emit(BaseMode.Mode.ProblemSolving, problem_set, problem)

func _on_back_pressed() -> void:
	back.emit()
