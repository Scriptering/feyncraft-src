extends PanelContainer

@onready var Down : PanelButton = $HBoxContainer/PanelContainer/HBoxContainer/VBoxContainer/Down
@onready var Up : PanelButton = $HBoxContainer/PanelContainer/HBoxContainer/VBoxContainer/Up

signal move
signal deleted
signal modify
signal play

var problem: Problem

func update() -> void:
	return

func toggle_edit_visiblity(can_edit: bool) -> void:
	$HBoxContainer/PanelContainer/HBoxContainer/Delete.visible = can_edit
	$HBoxContainer/PanelContainer/HBoxContainer/Modify.visible = can_edit

func set_index(index: int) -> void:
	$HBoxContainer/Index.text = str(index+1)
	
	Down.disabled = index == get_parent().get_child_count() - 1
	Up.disabled = index == 0

func load_problem(_problem: Problem) -> void:
	problem = _problem
	$HBoxContainer/PanelContainer/HBoxContainer/Equation.load_problem(problem)

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
		func(state_interaction: Array): return state_interaction.size() == 0
	)
