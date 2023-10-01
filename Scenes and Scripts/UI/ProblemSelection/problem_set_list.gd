extends PanelContainer

signal enter_problem_set(problem_set: ProblemSet)
signal play_problem_set(mode, problem_set, problem)
signal close

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

func add_problem_set(problem_set: ProblemSet) -> void:
	var problem_set_item: PanelContainer = ProblemSetItem.instantiate()
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
