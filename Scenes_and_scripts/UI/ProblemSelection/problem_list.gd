extends PanelContainer

signal back
signal problem_deleted

@export_group("Children")
@export var title: Label
@export var add_button: PanelButton

var ProblemSelector: PackedScene = preload("res://Scenes_and_scripts/UI/ProblemSelection/problem_item.tscn")

@onready var problem_container: PanelItemList = $VBoxContainer/PanelItemList

var problem_set: ProblemSet
var problem_set_file: String

func delete_empty_problems() -> void:
	for problem_item:PanelContainer in get_problem_items():
		if problem_item.is_empty():
			delete_problem(problem_item)

func reload() -> void:
	if !problem_set:
		return
	
	load_problem_set(load(problem_set_file), problem_set_file)
	
	for problem_item:PanelContainer in get_problem_items():
		problem_item.toggle_completed(!problem_set.is_custom and problem_item.index < problem_set.highest_index_reached)
		problem_item.toggle_play_disabled(!problem_set.is_custom and problem_item.index > problem_set.highest_index_reached)

func get_problem_items() -> Array:
	return problem_container.get_items().filter(
		func(child:PanelContainer) -> bool:
			return !child.is_queued_for_deletion()
	)

func load_problem_set(_problem_set: ProblemSet, p_problem_set_file_path: String) -> void:
	problem_set = _problem_set
	problem_set_file = p_problem_set_file_path
	
	if problem_set.title == '':
		title.text = 'Problem Set'
	else:
		title.text = problem_set.title
	
	problem_container.clear_items()
	
	for problem in problem_set.problems:
		add_problem(problem, problem_set.is_custom)
	
	add_button.visible = problem_set.is_custom
	
	update()

func create_problem_item() -> PanelContainer:
	var problem_item: PanelContainer = ProblemSelector.instantiate()
	
	problem_item.move.connect(_problem_moved)
	problem_item.deleted.connect(_problem_deleted)
	problem_item.play.connect(_problem_played)
	problem_item.modify.connect(_problem_modified)
	problem_item.modification_finished.connect(_problem_modification_finished)
	
	return problem_item

func add_problem(
	problem: Problem,
	is_custom: bool = false,
	problem_item: PanelContainer = create_problem_item()
) -> PanelContainer:
	problem_container.add_item(problem_item)
	
	problem_item.toggle_edit_visiblity(problem_set.is_custom)
	
	problem_item.load_problem(problem)
	problem_item.index = get_problem_items().size()-1
	
	problem_item.toggle_completed(!problem_set.is_custom and problem_item.index < problem_set.highest_index_reached)
	problem_item.toggle_play_disabled(!problem_set.is_custom and problem_item.index > problem_set.highest_index_reached)
	
	return problem_item

func update() -> void:
	update_index_labels()
	
	for problem_item:PanelContainer in get_problem_items():
		problem_item.update()

func update_index_labels() -> void:
	var index: int = 0
	for i:int in get_problem_items().size():
		get_problem_items()[i].index = index
		index += 1

func _problem_moved(problem_select: PanelContainer, index_change: int) -> void:
	var current_index: int = get_problem_items().find(problem_select)
	var new_index: int = current_index + index_change
	
	problem_container.move_item(problem_select, new_index)
	
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
	var new_problem := Problem.new()
	problem_set.problems.push_back(new_problem)
	EventBus.problem_modified.emit(add_problem(new_problem, true))
	update()

func _on_add_problem_pressed() -> void:
	create_problem()

func _problem_played(problem: Problem) -> void:
	EventBus.problem_set_played.emit(problem_set, problem_set.problems.find(problem))

func _problem_modified(problem_item: PanelContainer) -> void:
	EventBus.problem_modified.emit(problem_item)

func _problem_modification_finished(
	problem_item: PanelContainer,
	completed: bool
) -> void:
	if completed:
		problem_set.problems[get_problem_items().find(problem_item)] = problem_item.problem
		save()
	
	elif problem_item.is_empty():
		delete_problem(problem_item)

func save() -> void:
	ResourceSaver.save(problem_set, problem_set_file)

func _on_close_pressed() -> void:
	back.emit()
