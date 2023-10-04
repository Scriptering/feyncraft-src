extends PanelContainer

signal enter_problem_set(problem_set: ProblemSet)
signal play_problem_set(mode, problem_set, problem)
signal close

var problem_set_file_path: String = "res://saves/ProblemSets/"
var ProblemSetItem: PackedScene = preload("res://Scenes and Scripts/UI/ProblemSelection/problem_set_item.tscn")

@onready var problem_container: VBoxContainer = $VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer/ProblemContainer

var problem_sets: Array[ProblemSet]

func _ready() -> void:
	play_problem_set.connect(EVENTBUS.enter_game)
	
func load_problem_sets(_problem_sets: Array[ProblemSet]) -> void:
	problem_sets = _problem_sets
	
	clear_problem_sets()
	
	for problem_set in problem_sets:
		add_problem_set(problem_set)
	
	update_index_labels()
	update_problem_sets()

func clear_problem_sets() -> void:
	for child in problem_container.get_children():
		child.queue_free()

func add_problem_set(problem_set: ProblemSet, problem_set_item: ListItem = ProblemSetItem.instantiate()) -> void:
	problem_set_item.load_problem_set(problem_set)
	
	problem_set_item.deleted.connect(_problem_set_deleted)
	problem_set_item.view.connect(_problem_set_viewed)
	problem_set_item.play.connect(_problem_set_resumed)
	
	problem_set_item.toggle_edit_visibility(problem_set.is_custom)
	
	problem_container.add_child(problem_set_item)
	
	var count: int = problem_container.get_child_count()
	
	problem_set_item.set_index(problem_container.get_child_count()-1)
	problem_set_item.update()

func update_index_labels() -> void:
	for i in range(problem_container.get_child_count()):
		var problem_set: PanelContainer = problem_container.get_child(i)
		
		if problem_set.is_queued_for_deletion():
			continue
		
		problem_set.set_index(i)
		problem_set.update_problem_index()

func update_problem_sets() -> void:
	for problem_set in problem_container.get_children():
		problem_set.update()

func _problem_set_deleted(problem_set_item: PanelContainer) -> void:
	var index: int = problem_container.get_children().find(problem_set_item)
	
	problem_container.remove_child(problem_set_item)
	problem_sets.remove_at(index)
	
	update_index_labels()

func create_problem_set() -> void:
	var problem_set: ProblemSet = ProblemSet.new()
	problem_set.is_custom = true
	add_problem_set(problem_set)

func _on_add_problem_set_pressed() -> void:
	create_problem_set()

func _problem_set_viewed(problem_set_item: PanelContainer) -> void:
	enter_problem_set.emit(problem_set_item.problem_set)

func _problem_set_resumed(problem_set: ProblemSet) -> void:
	play_problem_set.emit(BaseMode.Mode.ProblemSolving, problem_set, problem_set.problems[problem_set.highest_index_reached])

func update() -> void:
	update_index_labels()
	update_problem_sets()

func _on_close_pressed() -> void:
	close.emit()

func _on_load_button_submitted(submitted_text) -> void:
	var file_path: String = GLOBALS.get_unique_file_name(problem_set_file_path + 'Custom/')
	GLOBALS.create_text_file(submitted_text, file_path)
	load_problem_set(file_path)

func on_load_error() -> void:
	($problem_setList/VBoxContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/HBoxContainer/LoadButton
	.load_error())

func load_problem_set(problem_set_path: String) -> void:
	var new_problem_set: ListItem = ProblemSetItem.instantiate()
	new_problem_set.file_path = problem_set_path
	
	var problem_set: ProblemSet = GLOBALS.load_data(problem_set_path)
	if problem_set:
		add_problem_set(GLOBALS.load_data(problem_set_path), new_problem_set)
	else:
		new_problem_set.queue_free()
		GLOBALS.delete_file(problem_set_path)
		on_load_error()

func save_problem_sets() -> void:
	var save_error: Error
	for problem_set in problem_container.get_children():
		if !problem_set.problem_set.is_custom:
			continue

		save_error = GLOBALS.save_data(problem_set.problem_set, problem_set.file_path)
	
	print(save_error)
	
func create_new_problem_set(problem_set_path: String) -> void:
	var new_problem_set: ListItem = ProblemSetItem.instantiate()
	new_problem_set.file_path = problem_set_path
	GLOBALS.create_file(problem_set_path)
	GLOBALS.save_data(new_problem_set.problem_set, problem_set_path)
	add_problem_set(ProblemSet.new(), new_problem_set)
	new_problem_set.randomise()
