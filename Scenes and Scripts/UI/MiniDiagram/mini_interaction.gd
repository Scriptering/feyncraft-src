extends Sprite2D
class_name MiniInteraction

var Initial: Control
var Final: Control

func init(diagram: MiniDiagram) -> void:
	Initial = diagram.StateLines[StateLine.State.Initial]
	Final = diagram.StateLines[StateLine.State.Final]
	
func show_dot() -> void:
	$Dot.show()

func get_on_state_line() -> StateLine.State:
	if position.x == Initial.position.x and position.x == Final.position.x:
		return StateLine.State.Both
		
	if position.x == Initial.position.x:
		return StateLine.State.Initial
		
	if position.x == Final.position.x:
		return StateLine.State.Final
		
	return StateLine.State.None
