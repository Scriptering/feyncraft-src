extends PanelContainer

signal back
signal problem_deleted

var ProblemSelector: PackedScene = preload("res://Scenes and Scripts/UI/ProblemSelection/problem_selector.tscn")

@onready var problem_container: VBoxContainer = $VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer/ProblemContainer

var problem_set: ProblemSet
var problem_set_file: String

func _ready() -> void:
	$VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer.get_v_scroll_bar().use_parent_material = true

func delete_empty_problems() -> void:
	for problem_item in get_problem_items():
		if problem_item.is_empty():
			delete_problem(problem_item)

func reload() -> void:
	if !problem_set:
		return
	
	load_problem_set(GLOBALS.load_txt(problem_set_file), problem_set_file)
	
	for problem_item in get_problem_items():
		problem_item.toggle_completed(!problem_set.is_custom and problem_item.index < problem_set.highest_index_reached)
		problem_item.toggle_play_disabled(!problem_set.is_custom and problem_item.index > problem_set.highest_index_reached)

func get_problem_items() -> Array:
	return problem_container.get_children().filter(
		func(child): return !child.is_queued_for_deletion()
	)

func load_problem_set(_problem_set: ProblemSet, p_problem_set_file_path: String) -> void:
	problem_set = _problem_set
	problem_set_file = p_problem_set_file_path
	
	if problem_set.title == '':
		$VBoxContainer/TitleContainer/HBoxContainer/Title.text = 'Problem Set'
	else:
		$VBoxContainer/TitleContainer/HBoxContainer/Title.text = problem_set.title
	
	clear_problems()
	
	for problem in problem_set.problems:
		add_problem(problem, problem_set.is_custom)
	
	$VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer/AddProblem.visible = problem_set.is_custom
	
	update_index_labels()

func clear_problems() -> void:
	for child in get_problem_items():
		child.queue_free()

func add_problem(problem: Problem, is_custom: bool = false) -> void:
	var problem_select: PanelContainer = ProblemSelector.instantiate()
	
	problem_select.move.connect(_problem_moved)
	problem_select.deleted.connect(_problem_deleted)
	problem_select.play.connect(_problem_played)
	problem_select.modify.connect(_problem_modified)
	problem_select.save_problem_set.connect(_problem_saved)
	
	problem_container.add_child(problem_select)
	
	problem_select.toggle_edit_visiblity(problem_set.is_custom)
	
	problem_select.load_problem(problem)
	problem_select.index = get_problem_items().size()-1
	
	problem_select.toggle_completed(!problem_set.is_custom and problem_select.index < problem_set.highest_index_reached)
	problem_select.toggle_play_disabled(!problem_set.is_custom and problem_select.index > problem_set.highest_index_reached)
	
	update()

func update() -> void:
	update_index_labels()
	
	for problem in get_problem_items():
		problem.update()

func update_index_labels() -> void:
	var index: int = 0
	for i in get_problem_items().size():
		get_problem_items()[i].index = index
		index += 1

func _problem_moved(problem_select: PanelContainer, index_change: int) -> void:
	var current_index: int = get_problem_items().find(problem_select)
	var new_index: int = current_index + index_change
	
	problem_container.move_child(problem_select, new_index)
	
	var temp_problem: Problem = problem_set.problems[new_index]
	problem_set.problems[new_index] = problem_set.problems[current_index]
	problem_set.problems[current_index] = temp_problem
	
	update_index_labels()
	save()

func delete_problem(problem_select: PanelContainer) -> void:
	var index: int = get_problem_items().find(problem_select)
	
	problem_set.problems.remove_at(index)
	problem_select.queue_free()
	
	update_index_labels()
	problem_deleted.emit()
	save()

func _problem_deleted(problem_select: PanelContainer) -> void:
	delete_problem(problem_select)

func create_problem() -> void:
	var problem: Problem = Problem.new()
	problem_set.problems.push_back(problem)
	add_problem(problem, true)

func _on_add_problem_pressed() -> void:
	create_problem()

func _problem_played(problem: Problem) -> void:
	EVENTBUS.problem_set_played(problem_set, problem_set.problems.find(problem))

func _on_back_pressed() -> void:
	back.emit()

func _problem_modified(problem_item) -> void:
	EVENTBUS.problem_modified(problem_item)

func _problem_saved(problem_item) -> void:
	save()

func save() -> void:
	GLOBALS.save(problem_set, problem_set_file)
