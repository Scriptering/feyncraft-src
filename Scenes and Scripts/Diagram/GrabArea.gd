extends Node

signal mouse_entered
signal mouse_exited

@export var Areas : Array[Node]

func init() -> void:
	for area in Areas:
		area.mouse_entered.connect(
			func(): emit_signal("mouse_entered")
		)
		
		area.mouse_exited.connect(
			func(): emit_signal("mouse_exited")
		)
