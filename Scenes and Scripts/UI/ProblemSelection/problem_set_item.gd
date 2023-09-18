extends PanelContainer

signal title_changed
signal deleted

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
	
func _on_delete_pressed() -> void:
	deleted.emit(self)

func _on_title_text_changed(new_text: String) -> void:
	title_changed.emit(new_text)
