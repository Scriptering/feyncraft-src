extends Node2D

@onready var Diagram : MiniDiagram = get_parent().get_parent()
@onready var Initial = Diagram.StateLines[StateLine.StateType.Initial]
@onready var Final = Diagram.StateLines[StateLine.StateType.Final]

func get_on_state_line() -> StateLine.StateType:
	if position.x == Initial.position.x and position.x == Final.position.x:
		return StateLine.StateType.Both
		
	if position.x == Initial.position.x:
		return StateLine.StateType.Initial
		
	if position.x == Final.position.x:
		return StateLine.StateType.Final
		
	return StateLine.StateType.None
