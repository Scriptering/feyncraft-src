extends PanelContainer

var ProblemSetItem: PackedScene = preload("res://Scenes and Scripts/UI/ProblemSelection/problem_set_item.tscn")

@onready var problem_container: VBoxContainer = $VBoxContainer/ProblemContainer

var problem_sets: Array[ProblemSet]

func load_problem_sets(_problem_sets: Array[ProblemSet]) -> void:
	problem_sets = _problem_sets
	
	for problem_set in problem_sets:
		add_problem_set(problem_set)
	
	update_index_labels()

func add_problem_set(problem_set: ProblemSet) -> void:
	var problem_set_item: PanelContainer = ProblemSetItem.instantiate()
	problem_set_item.load_problem_set(problem_set)
	
	problem_set_item.deleted.connect(_problem_set_deleted)
	
	problem_set_item.toggle_edit_visiblity(problem_set.is_custom)
	
	problem_container.add_child(problem_set_item)
	
	problem_set_item.set_index(problem_container.get_child_count())

func update_index_labels() -> void:
	for i in range(problem_container.get_child_count()):
		var problem_set: PanelContainer = problem_container.get_child(i)
		
		problem_set.set_index(i)
		problem_set.update_problem_index()

func _problem_set_deleted(problem_set_item: PanelContainer) -> void:
	var index: int = problem_container.get_children().find(problem_set_item)
	
	problem_container.remove_child(problem_set_item)
	problem_sets.remove_at(index)
	
	update_index_labels()

func create_problem_set() -> void:
	var problem_set: ProblemSet = ProblemSet.new()
	problem_set.is_custom = true

func _on_add_problem_set_pressed() -> void:
	create_problem_set()
