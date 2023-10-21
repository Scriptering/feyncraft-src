extends PanelContainer

@export var scale_factor: float = 1.0

@onready var Symbol := preload("res://Scenes and Scripts/UI/Equations/EquationSymbol.tscn")

@onready var LeftEquation: HBoxContainer = $HBoxContainer/LeftMarginContainer/LeftScrollContainer/MarginContainer/LeftEquation
@onready var RightEquation: HBoxContainer = $HBoxContainer/RightMarginContainer/RightScrollContainer/MarginContainer/RightEquation
@onready var StateEquations : Array[HBoxContainer] = [LeftEquation, RightEquation]

const States = [StateLine.StateType.Initial, StateLine.StateType.Final]

func load_problem(problem: Problem) -> void:
	for state in States:
		load_state_symbols(state, problem.get_state_interaction(state))

func clear_equation(state: StateLine.StateType) -> void:
	for child in StateEquations[state].get_children():
		child.queue_free()

func load_state_symbols(state: StateLine.StateType, state_interactions: Array) -> void:
	clear_equation(state)
	for i in range(state_interactions.size()):
		var interaction: Array = state_interactions[i]
		
		if i != 0:
			StateEquations[state].add_child(create_plus())
		
		StateEquations[state].add_child(create_particle_symbol(interaction))

func create_plus() -> TextureRect:
	var plus := Symbol.instantiate()
	plus.texture = load("res://Textures/UI/Equation/plus.png")
	
	return plus

func create_particle_symbol(interaction: Array) -> TextureRect:
	var particle := Symbol.instantiate()
	
	particle.texture = ParticleData.PARTICLE_TEXTURES[get_particle_name(interaction)]
	particle.custom_minimum_size = particle.texture.get_size() * scale_factor
	
	if interaction.size() != 1:
		particle.init(get_hadron(interaction))
	
	return particle

func get_particle_name(interaction: Array) -> String:
	if interaction.size() == 1:
		return ParticleData.Particle.keys()[ParticleData.Particle.values().find(interaction.front())]
	
	return ParticleData.HADRON_NAMES[get_hadron(interaction)]

func get_hadron(interaction: Array) -> ParticleData.Hadrons:
	for hadron in ParticleData.HADRON_QUARK_CONTENT.keys():
		if interaction in ParticleData.HADRON_QUARK_CONTENT[hadron]:
			return hadron
	
	return ParticleData.Hadrons.Invalid

func _on_scroll_container_child_entered_tree(node: Node) -> void:
	node.use_parent_material = true
