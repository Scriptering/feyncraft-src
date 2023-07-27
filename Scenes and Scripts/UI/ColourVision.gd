extends 'res://ButtonBase.gd'

const STATE = GLOBALS.VISION_TYPE.COLOUR

func _process(_delta):
	var has_colour = false
	var valid = true
	for i in get_tree().get_nodes_in_group('interactions'):
		if i.has_colour:
			has_colour = true
		if !i.valid:
			valid = false
	
	if !has_colour:
		set_disabled(true)
	else:
		set_disabled(false)
