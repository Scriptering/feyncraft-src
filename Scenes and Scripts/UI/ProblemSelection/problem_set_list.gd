extends PanelContainer

signal enter_problem_set(problem_set: ProblemSet, problem_set_file_path: String)
signal play_problem_set(mode: BaseMode.Mode, problem_set: ProblemSet, problem: Problem)
signal close

var problem_set_file_path: String = "res://saves/ProblemSets/"
var web_problem_set_file_path: String = "user://saves/ProblemSets/"
var ProblemSetItem: PackedScene = preload("res://Scenes and Scripts/UI/ProblemSelection/problem_set_item.tscn")

@export var problem_container:PanelItemList

var problem_sets: Array[ProblemSet]

func _ready() -> void:
	play_problem_set.connect(EventBus.enter_game)
	
	EventBus.save_files.connect(save_problem_sets)
	
	load_problem_sets()

func reload() -> void:
	for problem_set_item in problem_container.get_items():
		problem_set_item.reload()

func load_problem_sets() -> void:
	problem_container.clear_items()
	
	load_default_problem_sets()
	load_custom_problem_sets()
	
	update_index_labels()
	update_problem_sets()

func load_default_problem_sets() -> void:
	var file_path: String = problem_set_file_path if Globals.is_on_editor else web_problem_set_file_path
	
	load_problem_set(file_path + 'Default/electromagnetic.txt')
	load_problem_set(file_path + 'Default/strong.txt')
	load_problem_set(file_path + 'Default/hadronic.txt')

func load_custom_problem_sets() -> void:
	for file_path in FileManager.get_files_in_folder(get_custom_file_path()):
		load_problem_set(file_path)

func get_custom_file_path() -> String:
	return (problem_set_file_path + 'Custom/') if Globals.is_on_editor else (web_problem_set_file_path + 'Custom/')

func add_problem_set(problem_set: ProblemSet, problem_set_item: ListItem = ProblemSetItem.instantiate()) -> void:
	problem_set_item.load_problem_set(problem_set)
	
	problem_set_item.deleted.connect(_problem_set_deleted)
	problem_set_item.view.connect(_problem_set_viewed)
	problem_set_item.play.connect(_problem_set_resumed)
	
	problem_container.add_item(problem_set_item)
	
	problem_set_item.update()

func update_index_labels() -> void:
	var index: int = 0
	for i:int in range(problem_container.get_item_count()):
		var problem_set: PanelContainer = problem_container.get_item(i)
		
		if problem_set.is_queued_for_deletion():
			continue
		
		problem_set.update_problem_index()
		index += 1

func update_problem_sets() -> void:
	for problem_set in problem_container.get_items():
		problem_set.update()

func _problem_set_deleted(problem_set_item: PanelContainer) -> void:
	var index: int = problem_container.get_items().find(problem_set_item)
	FileManager.delete_file(problem_set_item.file_path)

	problem_sets.remove_at(index)
	problem_set_item.queue_free()
	
	update_index_labels()

func create_problem_set() -> void:
	var problem_set: ProblemSet = ProblemSet.new()
	problem_set.is_custom = true
	add_problem_set(problem_set)

func _problem_set_viewed(problem_set_item: PanelContainer) -> void:
	enter_problem_set.emit(problem_set_item.problem_set, problem_set_item.file_path)

func _problem_set_resumed(problem_set: ProblemSet) -> void:
	EventBus.signal_problem_set_played.emit(
		problem_set, 
		min(problem_set.highest_index_reached, problem_set.problems.size()-1)
	)

func update() -> void:
	update_index_labels()
	update_problem_sets()

func _on_close_pressed() -> void:
	close.emit()

func _on_load_button_submitted(submitted_text: String) -> void:
	var file_path: String = FileManager.get_unique_file_name(get_custom_file_path())
	FileManager.create_text_file(submitted_text, file_path)
	load_problem_set(file_path)

func load_problem_set(problem_set_path: String) -> void:
	var new_problem_set: ListItem = ProblemSetItem.instantiate()
	new_problem_set.file_path = problem_set_path
	
	var problem_set: ProblemSet = FileManager.load_txt(problem_set_path)
	if problem_set:
		add_problem_set(problem_set, new_problem_set)
	else:
		new_problem_set.queue_free()
		FileManager.delete_file(problem_set_path)

func save_problem_sets() -> void:
	for problem_set in problem_container.get_children():
		FileManager.save(problem_set.problem_set, problem_set.file_path)
	
func create_new_problem_set(problem_set_path: String) -> void:
	var new_problem_set: ListItem = ProblemSetItem.instantiate()
	new_problem_set.file_path = problem_set_path
	add_problem_set(ProblemSet.new(), new_problem_set)
	
	FileManager.create_file(problem_set_path)
	FileManager.save(new_problem_set.problem_set, problem_set_path)

func _on_add_button_pressed() -> void:
	create_new_problem_set(FileManager.get_unique_file_name(get_custom_file_path()))
