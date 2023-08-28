extends Control
class_name PullOutTab

enum Direction {LEFT, UP, RIGHT, DOWN}

@export var ContentContainer: Control
@export var TabButton: Control
@export var MovingContainer: Control
@export var moving_container_margins: Vector2
@export var move_direction: Direction
@export var tab_out: bool = false
@export var time_to_pull_out: float = 0.25
@export var time_to_push_in: float = 0.25

var starting_moving_container_position: Vector2

func _ready() -> void:
	TabButton.connect("pressed", Callable(self, "_tab_button_pressed"))
	starting_moving_container_position = MovingContainer.position

func _tab_button_pressed() -> void:
	tab_out = !tab_out
	TabButton.change_state(tab_out)
	if tab_out:
		pull_out()
	else:
		push_in()

func pull_out() -> void:
	SOUNDBUS.pull_out_tab()
	
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SPRING)
	tween.tween_property(MovingContainer, "position", get_pull_out_position(), time_to_pull_out)

func push_in() -> void:
	SOUNDBUS.push_in_tab()
	
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SPRING)
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
