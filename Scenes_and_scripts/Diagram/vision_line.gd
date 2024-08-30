extends Line2D

var shade: Vision.Shade = Vision.Shade.None
var colour: Color
var Arrow := preload("res://Scenes_and_scripts/Diagram/vision_line_arrow.tscn")

const black: Color = "#ffff00"
const white: Color = "#7e3f00"

func _ready() -> void:
	material.set_shader_parameter("line_color", colour)
	
	if colour.is_equal_approx(Globals.vision_colours[Globals.Vision.Shade][Vision.Shade.Dark]):
		material.set_shader_parameter("outline_color", white)
	elif colour.is_equal_approx(Globals.vision_colours[Globals.Vision.Shade][Vision.Shade.Bright]):
		material.set_shader_parameter("outline_color", black)
	else:
		material.set_shader_parameter("outline_color", Color.BLACK)
	create_arrows()

func create_arrows() -> void:
	for i:int in range(points.size()-1):
		var arrow : Sprite2D = Arrow.instantiate()
		arrow.position = points[i] + (points[i+1] - points[i])/2
		arrow.rotation = (points[i+1] - points[i]).angle()

		add_child(arrow)
