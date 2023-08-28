extends PanelContainer

enum STATE {INITIAL, FINAL}

@onready var Level = get_tree().get_nodes_in_group('level')[0]

var current_particles : Array = [[], []]
var current_hadrons : Array = [[], []]

@onready var InitialContainer = get_node('VBoxContainer/EquationContainer/InitialScrollContainer')
@onready var FinalContainer = get_node('VBoxContainer/EquationContainer/FinalScrollContainer')

@onready var containers : Array = [InitialContainer.get_node('HBoxContainer/StateContainer'), FinalContainer.get_node('HBoxContainer/StateContainer')]

var PlusTexture = preload('res://Textures/UI/Equation/plus.png')
var Symbol = preload("res://Scenes and Scripts/UI/Equations/EquationSymbol.tscn")

var hovering := false

var Initial: StateLine
var Final: StateLine

func init(diagram: DiagramBase) -> void:
	Initial = diagram.StateLines[StateLine.StateType.Initial]
	Final = diagram.StateLines[StateLine.StateType.Final]

func get_particles_from_states(stateName : String, stateConnections : Array) -> Array:
	return [get_particles(stateName, stateConnections), get_hadrons(stateName)]

func make_equation(state : int, particles : Array, hadrons: Array) -> void:
	if particles == current_particles[state] and hadrons == current_hadrons[state]:
		return

	current_particles[state] = particles.duplicate(true)
	current_hadrons[state] = hadrons.duplicate(true)
	
	clear_symbols(state)
		
	for i in range(hadrons.size()):
		add_hadron(state, hadrons[i])
		
		if i != (particles + hadrons).size() - 1:
			add_plus(state)

	for i in range(particles.size()):
		add_particle(state, particles[i])
		
		if i != particles.size() - 1:
			add_plus(state)


func clear_symbols(state : int) -> void:
	for symbol in containers[state].get_children():
		symbol.queue_free()

func get_particles(stateName : String, stateConnections : Array) -> Array:
	var particles := []
	for line in stateConnections:
		if line.in_equation[stateName] and is_instance_valid(line):
			particles.append(line)
	
	return particles

func get_hadrons(stateName : String) -> Array:
	return get_tree().get_nodes_in_group(stateName + 'hadronlabels')

func add_particle(state : int, particle : Object) -> void:
	var symbol = Symbol.instantiate()
	
	symbol.texture = particle.get_node('text').texture

	containers[state].add_child(symbol)
	
func add_hadron(state : int, hadron : Object) -> void:
	var symbol = Symbol.instantiate()
	
	symbol.texture = hadron.texture
	
	symbol.hadron = true
	symbol.quarks = hadron.quarks
	
	symbol.tooltip_text = 'gogo'
	
	containers[state].add_child(symbol)

func add_plus(state : int) -> void:
	var symbol = Symbol.instantiate()
	
	symbol.texture = PlusTexture

	containers[state].add_child(symbol)
	
func is_hovered() -> bool:
	return hovering

func _on_Equation_mouse_entered():
	hovering = true

func _on_Equation_mouse_exited():
	hovering = false

func set_symbols_visible(state : int, vis : bool):
	for symbol in containers[state].get_children():
		symbol.visible = vis
