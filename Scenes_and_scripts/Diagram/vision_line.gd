extends Line2D

var shade: Vision.Shade = Vision.Shade.None
var colour: Color
var Arrow := preload("res://Scenes_and_scripts/Diagram/vision_line_arrow.tscn")

const black: Color = Color.BLACK
const white: Color = Color("fff7ed")

func _ready() -> void:
	material.set_shader_parameter("line_color", colour)
	
	if colour.is_equal_approx(Globals.vision_colours[Globals.Vision.Shade][Vision.Shade.Dark]):
		material.set_shader_parameter("outline_color", white)
		material.set_shader_parameter("palette_swap", false)
	elif colour.is_equal_approx(Globals.vision_colours[Globals.Vision.Shade][Vision.Shade.Bright]):
		material.set_shader_parameter("outline_color", black)
		material.set_shader_parameter("palette_swap", false)
	else:
		material.set_shader_parameter("outline_color", Color.BLACK)
		material.set_shader_parameter("palette_swap", true)
	create_arrows()

func create_arrows() -> void:
	for i:int in range(points.size()-1):
		var arrow : Sprite2D = Arrow.instantiate()
		arrow.position = points[i] + (points[i+1] - points[i])/2
		arrow.rotation = (points[i+1] - points[i]).angle()

		add_child(arrow)
	
	if closed:
		var arrow : Sprite2D = Arrow.instantiate()
		arrow.position = points[-1] + (points[0] - points[-1])/2
		arrow.rotation = (points[0] - points[-1]).angle()

		add_child(arrow)
