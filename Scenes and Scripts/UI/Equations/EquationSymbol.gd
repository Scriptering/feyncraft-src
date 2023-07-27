extends TextureRect

var hadron : bool = false
var quarks : Array
var shrink : bool = false

func _make_custom_tooltip(_for_text):
	var s = Vector2(0.8, 0.8)
	if shrink:
		s = Vector2(0.55, 0.55)
	
	shrink = !shrink
	
	var tooltip = preload("res://Scenes and Scripts/Diagram/Hadrons/HadronTooltip.tscn").instantiate()
	for line in quarks:
		var image = TextureRect.new()
		image.texture = line.get_node('text').texture
		image.expand = true
		image.set_stretch_mode(TextureRect.STRETCH_SCALE)
		image.custom_minimum_size = image.texture.get_size() * s
		
		tooltip.get_node('VBoxContainer/HBoxContainer').add_child(image)
	
	for child in tooltip.get_node('VBoxContainer/HBoxContainer').get_children():
		print(child.custom_minimum_size)
	return tooltip
