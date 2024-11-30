extends Sprite2D
class_name MiniInteraction

var dot: Texture2D = preload("res://Textures/UI/MiniDiagram/mini_interaction_dot.png")
var double_dot : Texture2D = preload("res://Textures/Interactions/mini_interaction_double_dot.png")
var state_dot: Texture2D = preload("res://Textures/Interactions/mini_interaction_state_dot.png")

var Initial: Control
var Final: Control

func init(diagram: MiniDiagram) -> void:
	Initial = diagram.StateLines[StateLine.State.Initial]
	Final = diagram.StateLines[StateLine.State.Final]
	
func get_on_state_line() -> StateLine.State:
	if position.x == Initial.position.x and position.x == Final.position.x:
		return StateLine.State.Both
		
	if position.x == Initial.position.x:
		return StateLine.State.Initial
		
	if position.x == Final.position.x:
		return StateLine.State.Final
		
	return StateLine.State.None
