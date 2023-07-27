extends TextureRect

@onready var Level = get_tree().get_nodes_in_group('level')[0]
@onready var Equation : PanelContainer = Level.get_node('Equation')

func get_screenshot():
	var itex = ImageTexture.new()
	
	texture = itex.create_from_image(get_viewport().get_texture().get_data().get_rect(Equation.get_rect()))
	


