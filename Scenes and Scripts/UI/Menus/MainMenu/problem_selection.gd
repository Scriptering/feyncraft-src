extends TabContainer

enum Tab {ProblemSetList, ProblemList}

signal closed

@onready var ProblemSetList = $ProblemSetList
@onready var ProblemList = $ProblemList

func _on_problem_set_list_enter_problem_set(problem_set: ProblemSet, problem_set_file_path: String) -> void:
	enter_problem_set(problem_set, problem_set_file_path)

func enter_problem_set(problem_set: ProblemSet, problem_set_file_path: String) -> void:
	ProblemList.load_problem_set(problem_set, problem_set_file_path)
	current_tab = Tab.ProblemList

func _on_problem_list_back() -> void:
	current_tab = Tab.ProblemSetList
	ProblemSetList.load_problem_sets()

func _on_problem_set_list_close() -> void:
	closed.emit()

func _on_problem_list_problem_deleted() -> void:
	ProblemSetList.update()
