extends ListItem

signal view
signal play

@export_group("Children")
@export var title:LineEdit
@export var delete:PanelButton
@export var upload:PanelButton
@export var index_label: Label
@export var completed:TextureRect
@export var play_button:PanelButton

var problem_set: ProblemSet
var file_path: String
var is_custom: bool

func _ready() -> void:
	toggle_edit_visibility(problem_set.is_custom, !problem_set.is_default)
	update()

func toggle_edit_visibility(can_edit: bool, can_delete: bool = can_edit) -> void:
	if can_edit:
		%View.icon = load("res://Textures/Buttons/icons/hammer.png")
		%View.icon_use_parent_material = true
		%View.expand_icon = true
	else:
		%View.icon = load("res://Textures/Buttons/eye/eye_open.png")
		%View.icon_use_parent_material = false
		%View.expand_icon = false
	
	delete.visible = can_delete
	title.editable = can_edit
	upload.visible = can_edit
	
func update_problem_index() -> void:
	index_label.text = (
		str(problem_set.highest_index_reached) + "/" + str(problem_set.problems.size())
	)

func load_problem_set(_problem_set: ProblemSet) -> void:
	problem_set = _problem_set
	title.text = problem_set.title

func update() -> void:
	var no_problems : bool = problem_set.problems.size() == 0
	
	play_button.disabled = no_problems
	upload.disabled = no_problems
	completed.visible = (
		!no_problems and problem_set.highest_index_reached >= problem_set.problems.size()
	)
	
	update_problem_index()

func reload() -> void:
	problem_set = load(file_path)
	
	await get_tree().process_frame
	
	update()

func _on_delete_pressed() -> void:
	deleted.emit(self)

func _on_view_pressed() -> void:
	view.emit(self)

func _on_play_pressed() -> void:
	play.emit(problem_set)

func save() -> void:
	ResourceSaver.save(problem_set, file_path)

func _on_title_text_submitted(new_text: String) -> void:
	problem_set.title = new_text
	save()

func _on_upload_pressed() -> void:
	var to_share_problem_set : ProblemSet = problem_set.duplicate(true)
	to_share_problem_set.prepare_for_export()
	
	ClipBoard.copy(
		FileManager.get_resource_save_data(to_share_problem_set)
	)
