extends PanelContainer

@onready var Down : PanelButton = $HBoxContainer/PanelContainer/HBoxContainer/VBoxContainer/Down
@onready var Up : PanelButton = $HBoxContainer/PanelContainer/HBoxContainer/VBoxContainer/Up
@onready var Play: PanelContainer = $HBoxContainer/PanelContainer/HBoxContainer/HBoxContainer/Play
@onready var Delete: PanelContainer = $HBoxContainer/PanelContainer/HBoxContainer/HBoxContainer/Delete
@onready var Modify: PanelContainer = $HBoxContainer/PanelContainer/HBoxContainer/HBoxContainer/Modify

signal move
signal deleted
signal modify
signal play
signal save_problem_set

var problem: Problem
var index: int: set = _set_index

func _set_index(new_value: int) -> void:
	index = new_value
	
	$HBoxContainer/Index.text = str(index+1)
	
	Down.disabled = index == get_parent().get_child_count() - 1
	Up.disabled = index == 0
	
func update() -> void:
	return

func toggle_play_disabled(toggle: bool) -> void:
	Play.disabled = toggle

func toggle_completed(toggle: bool) -> void:
	$HBoxContainer/Completed.visible = toggle

func toggle_edit_visiblity(can_edit: bool) -> void:
	Delete.visible = can_edit
	Modify.visible = can_edit
	$HBoxContainer/PanelContainer/HBoxContainer/VBoxContainer.visible = can_edit

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
		func(state_interaction: Array) -> bool:
			return state_interaction.size() == 0
	)

func save() -> void:
	save_problem_set.emit(self)
