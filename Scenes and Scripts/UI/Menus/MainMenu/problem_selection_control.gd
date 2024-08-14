extends GrabbableControl

signal close
enum Tab {ProblemSetList, ProblemList}

func reload() -> void:
	$ProblemSelection/ProblemSetList.load_problem_sets()
	$ProblemSelection/ProblemList.reload()


@onready var ProblemSetList := $ProblemSelection/ProblemSetList
@onready var ProblemList := $ProblemSelection/ProblemList
@onready var tab_container:= $ProblemSelection

func _on_problem_set_list_enter_problem_set(problem_set: ProblemSet, problem_set_file_path: String) -> void:
	enter_problem_set(problem_set, problem_set_file_path)

func enter_problem_set(problem_set: ProblemSet, problem_set_file_path: String) -> void:
	ProblemList.load_problem_set(problem_set, problem_set_file_path)
	tab_container.current_tab = Tab.ProblemList

func _on_problem_list_back() -> void:
	tab_container.current_tab = Tab.ProblemSetList
	ProblemSetList.reload()

func _on_problem_set_list_close() -> void:
	close.emit()

func _on_problem_list_problem_deleted() -> void:
	ProblemSetList.update()

func _on_tree_entered() -> void:
	await get_tree().process_frame
	
	reload()
