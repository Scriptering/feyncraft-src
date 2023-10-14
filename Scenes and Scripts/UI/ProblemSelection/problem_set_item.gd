extends ListItem

signal view
signal play

var problem_set: ProblemSet
var file_path: String
var is_custom: bool

func _ready() -> void:
	toggle_edit_visibility(problem_set.is_custom)
	update()

func toggle_edit_visibility(can_edit: bool) -> void:
	$HBoxContainer/PanelContainer/HBoxContainer/Title.editable = can_edit
	$HBoxContainer/PanelContainer/HBoxContainer/Delete.visible = can_edit
	$HBoxContainer/PanelContainer/HBoxContainer/Upload.visible = can_edit

func set_index(new_index: int) -> void:
	$HBoxContainer/Index.text = str(new_index+1)

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
	
	update_problem_index()

func _on_delete_pressed() -> void:
	deleted.emit(self)

func _on_title_text_changed(new_text: String) -> void:
	problem_set.title = new_text

func _on_view_pressed() -> void:
	view.emit(self)

func _on_play_pressed() -> void:
	play.emit(problem_set)

func _on_upload_toggled(button_pressed) -> void:
	if !button_pressed:
		return
	
	await get_tree().process_frame
	
	$HBoxContainer/PanelContainer/HBoxContainer/Upload.set_text(
		GLOBALS.get_resource_save_data(problem_set)
	)
