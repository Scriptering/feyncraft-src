extends Sprite2D

var Initial: Control
var Final: Control

func init(diagram: MiniDiagram) -> void:
	Initial = diagram.StateLines[StateLine.StateType.Initial]
	Final = diagram.StateLines[StateLine.StateType.Final]
	
func show_dot() -> void:
	$Dot.show()

func get_on_state_line() -> StateLine.StateType:
	if position.x == Initial.position.x and position.x == Final.position.x:
		return StateLine.StateType.Both
		
	if position.x == Initial.position.x:
		return StateLine.StateType.Initial
		
	if position.x == Final.position.x:
		return StateLine.StateType.Final
		
	return StateLine.StateType.None
