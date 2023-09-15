extends Node
class_name BaseState

signal change_cursor

enum State {
	Null,
	Idle,
	Hovering,
	Placing,
	Deleting,
	Drawing
}

var crosshair : Node2D
var state_manager : Node
var Diagram : MainDiagram
var Controls : Node

@export var cursor_state : GLOBALS.CURSOR

func enter() -> void:
	emit_signal("change_cursor", cursor_state)

func exit() -> void:
	pass

func input(_event: InputEvent) -> State:
	return State.Null

func process(_delta: float) -> State:
	return State.Null

func physics_process(_delta: float) -> State:
	return State.Null

func is_hovering(group: String) -> bool:
	for groupee in get_tree().get_nodes_in_group(group):
		if groupee.is_hovered():
			return true

	return false

func crosshair_moved(_current_position : Vector2, _old_position : Vector2) -> void:
	return
