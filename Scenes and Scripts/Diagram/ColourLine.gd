extends Line2D

@onready var Arrow = get_node('Arrow')
@onready var Line = get_parent()

var reverse = false
var colour
var shade

func _ready():
	Line.connect('move', Callable(self, 'move'))
	Line.colour = colour
	
	Arrow.position = (points[1] - points[0]) / 2 + points[0]
	Arrow.look_at(points[1] + position)
	Arrow.modulate = default_color
	
	match shade:
		0:
			Arrow.texture = load('res://Textures/ParticlesAndLines/colour_lines/arrow_white.png')
			Arrow.scale = Vector2(0.5, 0.5)
		
		1:
			Arrow.texture = load('res://Textures/ParticlesAndLines/colour_lines/arrow_black.png')
			Arrow.scale = Vector2(0.5, 0.5)
		
func move():
	if !reverse:
		points = Line.points
	
	else:
		points[0] = Line.points[1]
		points[1] = Line.points[0]
	
	position = 3 * (points[1] - points[0]).orthogonal().normalized()
	
	Arrow.position = (points[1] - points[0]) / 2 + points[0]
	Arrow.look_at(points[1] + position)
