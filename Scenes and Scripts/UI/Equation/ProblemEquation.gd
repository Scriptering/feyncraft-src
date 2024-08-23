extends PanelContainer

@export var scale_factor: float = 1.0

@onready var Symbol := preload("res://Scenes and Scripts/UI/Equation/EquationSymbol.tscn")

@onready var LeftEquation: HBoxContainer = $HBoxContainer/LeftMarginContainer/LeftScrollContainer/MarginContainer/LeftEquation
@onready var RightEquation: HBoxContainer = $HBoxContainer/RightMarginContainer/RightScrollContainer/MarginContainer/RightEquation
@onready var StateEquations : Array[HBoxContainer] = [LeftEquation, RightEquation]

func load_problem(problem: Problem) -> void:
	for state:StateLine.State in StateLine.STATES:
		load_state_symbols(state, problem.get_state_interaction(state))

func clear_equation(state: StateLine.State) -> void:
	for child:TextureRect in StateEquations[state].get_children():
		child.queue_free()

func load_state_symbols(state: StateLine.State, state_interactions: Array) -> void:
	clear_equation(state)
	for i:int in state_interactions.size():
		var interaction: Array = state_interactions[i]
		interaction.sort()
		if i != 0:
			StateEquations[state].add_child(create_plus())
		
		StateEquations[state].add_child(create_particle_symbol(interaction))

func create_plus() -> TextureRect:
	var plus := Symbol.instantiate()
	plus.texture = load("res://Textures/UI/Equation/plus.png")
	
	return plus

func create_particle_symbol(interaction: Array) -> TextureRect:
	var particle := Symbol.instantiate()
	
	particle.texture = ParticleData.particle_textures[get_particle_name(interaction)]
	particle.custom_minimum_size = particle.texture.get_size() * scale_factor
	
	if interaction.size() != 1:
		particle.init(get_hadron(interaction))
	
	return particle

func get_particle_name(interaction: Array) -> String:
	if interaction.size() == 1:
		return ParticleData.Particle.keys()[ParticleData.Particle.values().find(interaction.front())]
	
	return ParticleData.HADRON_NAMES[get_hadron(interaction)]

func get_hadron(interaction: Array) -> ParticleData.Hadron:
	for hadron:ParticleData.Hadron in ParticleData.HADRON_QUARK_CONTENT:
		if interaction in ParticleData.HADRON_QUARK_CONTENT[hadron]:
			return hadron
	
	return ParticleData.Hadron.Invalid

func _on_scroll_container_child_entered_tree(node: Node) -> void:
	node.use_parent_material = true
