extends Control
class_name PullOutTab

signal pull_out_finished
signal push_in_finished

enum Direction {LEFT, UP, RIGHT, DOWN}

@export var ContentContainer: Control
@export var TabButton: Control = null
@export var MovingContainer: Control
@export var moving_container_margins: Vector2
@export var move_direction: Direction

@export var tab_out: bool = false:
	set(new_value):
		tab_out = new_value
		tab_out_changed = true

@export var time_to_pull_out: float = 0.25
@export var time_to_push_in: float = 0.25
@export var stay_out_time: float = 0.0

var starting_moving_container_position: Vector2
var tab_out_changed: bool = false

func _ready() -> void:
	if TabButton:
		TabButton.pressed.connect(_tab_button_pressed)
	
	ContentContainer.resized.connect(readjust)

	starting_moving_container_position = MovingContainer.position

func _tab_button_pressed() -> void:
	if tab_out:
		push_in()
	else:
		pull_out()
	
	TabButton.change_state(tab_out)

func pull_out() -> void:
	if tab_out or !is_inside_tree():
		return
		
	self.tab_out = true
	
	SOUNDBUS.pull_out_tab()
	
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SPRING)
	tween.finished.connect(_on_pull_out_finished)
	tween.tween_property(MovingContainer, "position", get_pull_out_position(), time_to_pull_out)

func readjust() -> void:
	if !tab_out:
		return
	
	MovingContainer.position = get_pull_out_position()

func close() -> void:
	if !tab_out:
		return
	
	self.tab_out = false
	MovingContainer.position = starting_moving_container_position

func stay_out_timer_finished() -> void:
	if tab_out_changed:
		return
	
	push_in()

func push_in() -> void:
	if !tab_out or !is_inside_tree():
		return
	
	self.tab_out = false
	
	SOUNDBUS.push_in_tab()
	
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SPRING)
	tween.finished.connect(
		func() -> void:
			push_in_finished.emit()
	)
	tween.tween_property(MovingContainer, "position", starting_moving_container_position, time_to_push_in)


func get_pull_out_position() -> Vector2:
	var pull_out_position := starting_moving_container_position
	pull_out_position[move_direction%2] += negative_direction() * (
		ContentContainer.size[move_direction%2] +
		moving_container_margins[move_direction%2]
	)
	return pull_out_position

func negative_direction() -> int:
	if move_direction < 2:
		return -1
	return +1

func _on_pull_out_finished() -> void:
	pull_out_finished.emit()
	
	if stay_out_time != 0.0:
		tab_out_changed = false
		await get_tree().create_timer(stay_out_time).timeout
		stay_out_timer_finished()
