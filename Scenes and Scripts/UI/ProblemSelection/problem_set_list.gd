extends PanelContainer

signal enter_problem_set(problem_set: ProblemSet, problem_set_file_path: String)
signal play_problem_set(mode, problem_set, problem)
signal close

@export var LoadButton: PanelButton

var problem_set_file_path: String = "res://saves/ProblemSets/"
var web_problem_set_file_path: String = "user://saves/ProblemSets/"
var ProblemSetItem: PackedScene = preload("res://Scenes and Scripts/UI/ProblemSelection/problem_set_item.tscn")

@onready var problem_container: VBoxContainer = $VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer/ProblemContainer

var problem_sets: Array[ProblemSet]

func _ready() -> void:
	play_problem_set.connect(EVENTBUS.enter_game)
	
	EVENTBUS.signal_save_files.connect(save_problem_sets)
	
	load_problem_sets()
	
	$VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer.get_v_scroll_bar().use_parent_material = true

func reload() -> void:
	for problem_set_item in problem_container.get_children():
		problem_set_item.reload()

func load_problem_sets() -> void:
	clear_problem_sets()
	
	load_default_problem_sets()
	load_custom_problem_sets()
	
	update_index_labels()
	update_problem_sets()

func load_default_problem_sets() -> void:
	var file_path: String = problem_set_file_path if GLOBALS.is_on_editor else web_problem_set_file_path
	
	load_problem_set(file_path + 'Default/electromagnetic.txt')
	load_problem_set(file_path + 'Default/strong.txt')
	load_problem_set(file_path + 'Default/hadronic.txt')

func load_custom_problem_sets() -> void:
	for file_path in GLOBALS.get_files_in_folder(get_custom_file_path()):
		load_problem_set(file_path)

func clear_problem_sets() -> void:
	for child in problem_container.get_children():
		child.queue_free()

func get_custom_file_path() -> String:
	return (problem_set_file_path + 'Custom/') if GLOBALS.is_on_editor else (web_problem_set_file_path + 'Custom/')

func add_problem_set(problem_set: ProblemSet, problem_set_item: ListItem = ProblemSetItem.instantiate()) -> void:
	problem_set_item.load_problem_set(problem_set)
	
	problem_set_item.deleted.connect(_problem_set_deleted)
	problem_set_item.view.connect(_problem_set_viewed)
	problem_set_item.play.connect(_problem_set_resumed)
	
	problem_container.add_child(problem_set_item)
	
	problem_set_item.set_index(problem_container.get_child_count()-1)
	problem_set_item.update()

func update_index_labels() -> void:
	var index: int = 0
	for i in range(problem_container.get_child_count()):
		var problem_set: PanelContainer = problem_container.get_child(i)
		
		if problem_set.is_queued_for_deletion():
			continue
		
		problem_set.set_index(index)
		problem_set.update_problem_index()
		index += 1

func update_problem_sets() -> void:
	for problem_set in problem_container.get_children():
		problem_set.update()

func _problem_set_deleted(problem_set_item: PanelContainer) -> void:
	var index: int = problem_container.get_children().find(problem_set_item)
	GLOBALS.delete_file(problem_set_item.file_path)

	problem_sets.remove_at(index)
	problem_set_item.queue_free()
	
	update_index_labels()

func create_problem_set() -> void:
	var problem_set: ProblemSet = ProblemSet.new()
	problem_set.is_custom = true
	add_problem_set(problem_set)

func _on_add_problem_set_pressed() -> void:
	create_new_problem_set(GLOBALS.get_unique_file_name(get_custom_file_path()))

func _problem_set_viewed(problem_set_item: PanelContainer) -> void:
	enter_problem_set.emit(problem_set_item.problem_set, problem_set_item.file_path)

func _problem_set_resumed(problem_set: ProblemSet) -> void:
	EVENTBUS.signal_problem_set_played.emit(
		problem_set, 
		min(problem_set.highest_index_reached, problem_set.problems.size()-1)
	)

func update() -> void:
	update_index_labels()
	update_problem_sets()

func _on_close_pressed() -> void:
	close.emit()

func _on_load_button_submitted(submitted_text) -> void:
	var file_path: String = GLOBALS.get_unique_file_name(get_custom_file_path())
	GLOBALS.create_text_file(submitted_text, file_path)
	load_problem_set(file_path)

func on_load_error(valid: bool) -> void:
	LoadButton.load_result(valid)

func load_problem_set(problem_set_path: String) -> void:
	var new_problem_set: ListItem = ProblemSetItem.instantiate()
	new_problem_set.file_path = problem_set_path
	
	var problem_set: ProblemSet = GLOBALS.load_txt(problem_set_path)
	if problem_set:
		add_problem_set(problem_set, new_problem_set)
		on_load_error(true)
	else:
		new_problem_set.queue_free()
		GLOBALS.delete_file(problem_set_path)
		on_load_error(false)

func save_problem_sets() -> void:
	for problem_set in problem_container.get_children():
		GLOBALS.save(problem_set.problem_set, problem_set.file_path)
	
func create_new_problem_set(problem_set_path: String) -> void:
	var new_problem_set: ListItem = ProblemSetItem.instantiate()
	new_problem_set.file_path = problem_set_path
	add_problem_set(ProblemSet.new(), new_problem_set)
	
	GLOBALS.create_file(problem_set_path)
	GLOBALS.save(new_problem_set.problem_set, problem_set_path)
