extends TabContainer

enum Tab {ProblemSetList, ProblemList}

@onready var ProblemSetList = $ProblemSetList
@onready var ProblemList = $ProblemList

func _on_problem_set_list_enter_problem_set(problem_set: ProblemSet) -> void:
	enter_problem_set(problem_set)

func enter_problem_set(problem_set: ProblemSet) -> void:
	ProblemList.load_problem_set(problem_set)
	current_tab = Tab.ProblemList

func _on_problem_set_list_back() -> void:
	hide()

func _on_problem_list_back() -> void:
	current_tab = Tab.ProblemSetList
	ProblemSetList.update()
