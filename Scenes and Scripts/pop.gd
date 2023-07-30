extends Node2D

var list = [false, false, true, false, false, true]

var min = -2
var max = 2

var array = [0, 1, 0, 0, 1]
var g = [0, 1, 2, 3, 4]
var anti = [-1, -1, -1]
var b = [[1, 2], [3, 4]]
var d = [[], [], [], []]
var a = 0
var key = 'something_anti'
var c = ['something', 'something_anti', 'photon']

enum boo {t, h, e, q = -6, u, i, c, k}

var clicks : int = 0
var unclicks : int = 0

var i1 : InteractionMatrix = InteractionMatrix.new()
var i2 : InteractionMatrix = InteractionMatrix.new()

func _ready() -> void:
	print(min%2)
	
	i1.add_unconnected_interaction([GLOBALS.Particle.gluon])
	i2 = i1.duplicate(true)
	
	i2.add_unconnected_interaction([GLOBALS.Particle.photon])
	
	print(i1.get_unconnected_base_particles())
	print(i2.get_unconnected_base_particles())
	

func is_anti(particle):
	return sign(particle)

func remove_anti(particle):
	if is_anti(particle):
		return particle.trim_suffix('_anti')
	return particle

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			clicks +=1
			$HBoxContainer/clicks.text = str(clicks)
		else:
			unclicks += 1
			$HBoxContainer/unclicks.text = str(unclicks)
			
	
#	if Input.is_action_just_pressed("click"):
#		clicks += 1
#		$HBoxContainer/clicks.text = str(clicks)
#	elif Input.is_action_just_released("click"):
#		unclicks += 1
#		$HBoxContainer/unclicks.text = str(unclicks)
