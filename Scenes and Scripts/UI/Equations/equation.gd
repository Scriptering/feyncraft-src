extends PanelContainer

@onready var Symbol = preload("res://symbol.tscn")
@onready var Plus = preload('res://Textures/plus.png')
@onready var Level = get_tree().get_nodes_in_group('level')[0]

@onready var Point1 = get_node('CursorPoint')
@onready var Point2 = get_node('CursorPoint2')

var particles := {'Initial': [], 'Final': []}
@export var initial : PackedStringArray
@export var final : PackedStringArray

var offset: int
var goal := {'Initial': [], 'Final': []}

@export var gap : int
@export var initial_gap : int

func _ready():
	initial.sort()
	final.sort()

	goal['Initial'] = initial
	goal['Final'] = final

func make_equation(state_name, connections):
	if state_name == 'Initial':
		offset = -1
		for i in get_children():
			if i.position.x < -1:
				i.queue_free()

	elif state_name == 'Final':
		offset = 1
		for i in get_children():
			if i.position.x > 1:
				i.queue_free()

	var valid_connections = []
	for i in range(connections.size()):
		if connections[i].in_equation[state_name] and is_instance_valid(connections[i]):
			valid_connections.append(connections[i])
	
	var h_labels = get_tree().get_nodes_in_group(state_name + 'hadronlabels')

	var state_labels : PackedStringArray = []
	
	var last_position = offset * initial_gap
	
	var N = h_labels.size() + valid_connections.size() - 1
	var n = 0
	
	for i in h_labels:
		state_labels.append(i.name)
		last_position = add_symbol(i.texture, 1.5, last_position)
		if n != N:
			last_position = add_symbol(Plus, 0.75, last_position)
		n += 1
		
	for i in valid_connections:
		state_labels.append(i.get_name())
		last_position = add_symbol(i.Text.texture, 0.75, last_position)
		#Point1.position.x = last_position
		if n != N:
			last_position = add_symbol(Plus, 0.75, last_position)
		n += 1
	
	state_labels.sort()
	particles[state_name] = state_labels

func add_symbol(texture, scale, last_position):
	var symbol = Symbol.instantiate()
	
	symbol.texture = texture
	symbol.offset.x = offset * texture.get_size().x / 2
	symbol.scale = Vector2(scale, scale)
	
	symbol.position.x = last_position + offset * gap
	
	#Point2.position.x = symbol.position.x
	
	add_child(symbol)
	
	return symbol.position.x + offset*texture.get_size().x * scale

func check_matching():
	if particles['Initial'].size() != 0 and particles['Final'].size() != 0:
		return (goal['Initial'] == particles['Initial']) and (goal['Final'] == particles['Final'])
	else:
		return false
