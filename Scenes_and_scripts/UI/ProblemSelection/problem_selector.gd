extends PanelContainer

@export_group("Children")
@export var up_button: PanelButton
@export var down_button: PanelButton
@export var play_button: PanelButton
@export var delete_button: PanelButton
@export var modify_button: PanelButton
@export var equation: PanelContainer

signal move
signal deleted
signal modify
signal play
signal modification_finished(problem_item: PanelContainer)

var problem: Problem
var index: int: set = _set_index

func _set_index(new_value: int) -> void:
	index = new_value
	
	$VBoxContainer/HBoxContainer/HBoxContainer2/Index.text = str(index+1)
	
	down_button.disabled = index == get_parent().get_child_count() - 1
	up_button.disabled = index == 0
	
func update() -> void:
	play_button.disabled = is_empty()

func toggle_play_disabled(toggle: bool) -> void:
	play_button.disabled = toggle

func toggle_completed(toggle: bool) -> void:
	$VBoxContainer/HBoxContainer/HBoxContainer2/Completed.visible = toggle

func toggle_edit_visiblity(can_edit: bool) -> void:
	delete_button.visible = can_edit
	modify_button.visible = can_edit
	up_button.visible = can_edit
	down_button.visible = can_edit

func load_problem(_problem: Problem) -> void:
	problem = _problem
	equation.load_problem(problem)

func _on_up_pressed() -> void:
	move.emit(self, -1)

func _on_down_pressed() -> void:
	move.emit(self, +1)

func _on_delete_pressed() -> void:
	deleted.emit(self)

func _on_modify_pressed() -> void:
	modify.emit(self)

func _on_play_pressed() -> void:
	play.emit(problem)

func is_empty() -> bool:
	return problem.state_interactions.all(
		func(state_interaction: Array) -> bool:
			return state_interaction.size() == 0
	)

func finish_modification() -> void:
	equation.load_problem(problem)
	modification_finished.emit(self)
	update()
