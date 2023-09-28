extends PanelContainer

signal view
signal title_changed
signal deleted
signal play

var problem_set: ProblemSet

func toggle_edit_visibility(can_edit: bool) -> void:
	$HBoxContainer/PanelContainer/HBoxContainer/Title.editable = can_edit
	$HBoxContainer/PanelContainer/HBoxContainer/Delete.visible = can_edit
	$HBoxContainer/PanelContainer/HBoxContainer/Upload.visible = can_edit

func set_index(index: int) -> void:
	$HBoxContainer/Index.text = str(index+1)

func update_problem_index() -> void:
	$HBoxContainer/PanelContainer/HBoxContainer/IndexLabel.text = (
		str(problem_set.highest_index_reached) + "/" + str(problem_set.problems.size())
	)

func load_problem_set(_problem_set: ProblemSet) -> void:
	problem_set = _problem_set
	$HBoxContainer/PanelContainer/HBoxContainer/Title.text = problem_set.title

func update() -> void:
	var no_problems : bool = problem_set.problems.size() == 0
	
	$HBoxContainer/PanelContainer/HBoxContainer/Play.disabled = no_problems
	$HBoxContainer/PanelContainer/HBoxContainer/Upload.disabled = no_problems

func _on_delete_pressed() -> void:
	deleted.emit(self)

func _on_title_text_changed(new_text: String) -> void:
	title_changed.emit(new_text)

func _on_view_pressed() -> void:
	view.emit(self)

func _on_play_pressed() -> void:
	play.emit(problem_set)
