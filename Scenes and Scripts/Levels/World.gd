extends Node2D

@export var grid_size: int = 16

@onready var Vertex = preload("res://Scenes and Scripts/Diagram/interaction.tscn")
@onready var Line = preload("res://Scenes and Scripts/Diagram/line.tscn")
@onready var Info = preload("res://Scenes and Scripts/UI/Info/Info.tscn")
@onready var Interactions = $GridArea/Interactions
@onready var ParticleLines = $GridArea/ParticleLines

@onready var Crosshair = get_node("Crosshair")
@onready var Initial : StateLine = get_node("Initial")
@onready var Final : StateLine = get_node('Final')
@onready var FPS = get_node('FPS')
@onready var Cursor = get_node('Cursor')
@onready var Pathfinding = get_node('PathFinding')
@onready var Generation = get_node('Generation')
@onready var Equation = get_node('Equation')

@onready var States = $state_manager

enum PARTICLE {photon, gluon, Z, H, W, electron, muon, tau, electron_neutrino, muon_neutrino,
tau_neutrino, up, down, charm, strange, top, bottom, none = 100,
anti_bottom = -16, anti_top, anti_strange, anti_charm, anti_down, anti_up, anti_tau_neutrino,
anti_muon_neutrino, anti_electron_neutrino, anti_tau, anti_muon, anti_electron, anti_W}

var valid = false
var connected = false
var matching = false
var submitted_diagrams := []

var crosshair_just_moved := false
signal release_click

enum {INVALID = -1, VALID = 1}

var type : int = PARTICLE.electron
var mode: String = 'drawing'
var placed_interaction: bool = false
var just_changed = false

var old_interaction_size = 0
var old_lines_size = 0

var moving_count := 0

var colour_delay = 0.05

var interaction_matrix := ConnectionMatrix.new()

@export var info_gap : int

func _ready():
	States.init(Cursor, Crosshair, $diagram_actions)
	$diagram_actions.init($GridArea/Interactions, $GridArea/ParticleLines, $ParticleButtons, [Initial, Final])
	$ShaderControl.init($PalletteButtons)
	$Generation.init($GenerationButton)
	
	Generation.connect('draw_diagram', Callable(self, 'draw_diagram'))
	
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
func _process(_delta):
	FPS.text = str(Engine.get_frames_per_second())

func colourful() -> void:
	Pathfinding.colourful(true)

func state_changed(state_name : String, connections : Array):
	var particles_and_hadrons = Equation.get_particles_from_states(state_name, connections)
	Equation.make_equation(['Initial', 'Final'].find(state_name), particles_and_hadrons[0], particles_and_hadrons[1])

func is_hovering(group):
	for i in get_tree().get_nodes_in_group(group):
		if i.is_hovered():
			return true

	return false

func update_statelines() -> void:
	await get_tree().process_frame
	Initial.update_stateline()
	Final.update_stateline()

func show_colour():
	Pathfinding.showing_type = GLOBALS.VISION_TYPE.COLOUR
	await get_tree().create_timer(0.01).timeout
	Pathfinding.colourful(false)

func show_shade():
	Pathfinding.showing_type = GLOBALS.VISION_TYPE.SHADE
	Pathfinding.colourful(false)

func is_valid() -> bool:
	for i in get_tree().get_nodes_in_group('interactions'):
		if !i.valid:
			return false
	return true

func draw_diagram(connection_matrix : ConnectionMatrix) -> void:
	var MAX_ATTEMPTS := 100
	
	if connection_matrix == null:
		return
	
	var drawable_matrix : ConnectionMatrix = connection_matrix.duplicate()
	drawable_matrix.seperate_double_connections()
	
	var hadron_ids : Array[int] = drawable_matrix.get_hadron_ids()
	var hadron_sizes : Array[int] = []
	
	for hadron_id in hadron_ids:
		hadron_sizes.append(drawable_matrix.get_connection_count(hadron_id, true))
	
	for hadron_size in hadron_sizes:
		var cumulative_hadron_shift_size : int = 0
		for i in range(hadron_ids.size()):
			hadron_ids[i] += cumulative_hadron_shift_size
		
		cumulative_hadron_shift_size += hadron_size-1
	
	drawable_matrix.split_hadrons()
	
	var generation_valid : bool
	
	for attempt in range(MAX_ATTEMPTS):
		var temp_matrix : ConnectionMatrix = drawable_matrix.duplicate()
		
		var drawing_interactions : Array[Interaction] = draw_diagram_interactions(temp_matrix, attempt, hadron_ids, hadron_sizes)
		var drawing_particles : Array[ParticleLine] = draw_diagram_particles(temp_matrix, drawing_interactions)
		
		for drawing_particle in drawing_particles:
			$diagram_actions.place_line(
				drawing_particle.points[ParticleLine.Point.Start],
				drawing_particle.points[ParticleLine.Point.End],
				drawing_particle.base_particle
			)
		for drawing_interaction in drawing_interactions:
			$diagram_actions.place_interaction(drawing_interaction.position, true)
		
		generation_valid = true
		for interaction in drawing_interactions:
			if !interaction.valid and interaction.valid_colourless:
				generation_valid = false
				break
		
		if generation_valid:
			for drawing_particle in drawing_particles:
				drawing_particle.show()
			for drawing_interaction in drawing_interactions:
				drawing_interaction.show()
			break
		
		if attempt != MAX_ATTEMPTS - 1:
			clear()

func draw_diagram_interactions(
	connection_matrix: ConnectionMatrix, attempt: int, hadron_ids : Array[int], hadron_sizes : Array[int]
) -> Array[Interaction]:
	var drawing_interactions : Array[Interaction] = []
	
	for state in [StateLine.StateType.Initial, StateLine.StateType.Final]:
		drawing_interactions += draw_state_diagram_interactions(connection_matrix, state, hadron_ids, hadron_sizes)
	
	var degree_radius := 90 - 5 * (attempt % 10)
	
	drawing_interactions += draw_middle_diagram_interactions(connection_matrix)
	
	return drawing_interactions

func draw_middle_diagram_interactions(connection_matrix: ConnectionMatrix) -> Array[Interaction]:
	var degree_pos : Array[float ] = []
	var degree_step : float = 2 * PI / (connection_matrix.get_state_count(StateLine.StateType.None))
	var degree_start : float = randf() * 2 * PI
	
	for i in range(connection_matrix.get_state_count(StateLine.StateType.None)):
		degree_pos.append(i * degree_step + degree_start)
		
	var radius : float = 90
	var circle_y_start : int = 16 * 9
	
	var drawing_middle_interactions : Array[Interaction] = []
	
	for j in range(connection_matrix.get_state_count(StateLine.StateType.None)):
		var interaction : Interaction = Interaction.new()

		interaction.position.x = snapped((Initial.position.x + Final.position.x) / 2 + radius * cos(degree_pos[j]), 16)
		interaction.position.y = snapped(circle_y_start +  + radius * sin(degree_pos[j]), 16)
		interaction.visible = false
		drawing_middle_interactions.append(interaction)
	
	return drawing_middle_interactions

func draw_state_diagram_interactions(
	connection_matrix: ConnectionMatrix, state: StateLine.StateType, hadron_ids: Array[int], hadron_sizes: Array[int]
) -> Array[Interaction]:
	var current_y : int = snapped(Initial.position.y, 16) + 32
	var state_lines : Array = [Initial, Final]
	
	var drawing_state_interactions : Array[Interaction] = []
	
	for state_id in connection_matrix.get_state_ids(state):
		var interaction: Interaction = Interaction.new()
		interaction.position.x = state_lines[state].position.x
		interaction.position.y = current_y
		interaction.visible = false
		drawing_state_interactions.append(interaction)
		
		current_y += 32
		
		for hadron_id in hadron_ids:
			if (state_id - hadron_id > 0) and (state_id - hadron_id < hadron_sizes[hadron_ids.find(hadron_id)]):
				current_y -= 16

	return drawing_state_interactions

func draw_diagram_particles(connection_matrix: ConnectionMatrix, drawing_interactions: Array[Interaction]) -> Array[ParticleLine]:
	var drawing_lines : Array[ParticleLine] = []
	print(range(connection_matrix.size()))
	for i in range(connection_matrix.size()):
		for j in range(connection_matrix.size()):
			if !connection_matrix.are_interactions_connected(i, j):
				continue
			
			var drawing_line : ParticleLine = ParticleLine.new()

			drawing_line.base_particle = connection_matrix.connection_matrix[i][j][0]

			drawing_line.points[ParticleLine.Point.Start] = drawing_interactions[i].position
			drawing_line.points[ParticleLine.Point.End] = drawing_interactions[j].position
			
			drawing_lines.append(drawing_line)

	return drawing_lines


#func _draw_diagram(matrix : ConnectionMatrix, initial_state : Array, final_state : Array):
#	Equation.make_equation(GLOBALS.STATE_LINE.INITIAL, [], [])
#	Equation.make_equation(GLOBALS.STATE_LINE.FINAL, [], [])
#
#	for state in [initial_state, final_state]:
#		for i in range(state.size()):
#			for j in range(state[i].size()):
#				state[i][j] = abs(state[i][j])
#
#	var state_y_start = snapped(Initial.position.y, 16) + 32
#
#	var state_lines : Array = [Initial, Final]
#	var states : Array = [initial_state, final_state]
#
#	var MAX_ATTEMPTS := 100
#
#	var degree_radius := 90
#
#	Equation.set_symbols_visible(GLOBALS.STATE_LINE.INITIAL, false)
#	Equation.set_symbols_visible(GLOBALS.STATE_LINE.FINAL, false)
#
#	var generation_valid : bool
#
#	for attempt in range(MAX_ATTEMPTS):
#		var temp_matrix := matrix.duplicate(true)
#		await get_tree().process_frame
#
#		Equation.set_symbols_visible(GLOBALS.STATE_LINE.INITIAL, false)
#		Equation.set_symbols_visible(GLOBALS.STATE_LINE.FINAL, false)
#
#		for state in [GLOBALS.STATE_LINE.INITIAL, GLOBALS.STATE_LINE.FINAL]:
#			var y = state_y_start
#			for state_interaction in states[state]:
#				for particle in state_interaction:
#					var interaction: Interaction = Vertex.instantiate()
#					interaction.position.x = state_lines[state].position.x
#					interaction.position.y = y
#					y += 16
#					interaction.visible = false
#					interaction.add_to_group('drawing_interactions')
#					Interactions.add_child(interaction)
#
#				y += 32
#
#		if connection_matrix.get_state_count(StateLine.StateType.None) != 0:
#			var degree_pos = []
#			var degree_step = 2 * PI / (connection_matrix.get_state_count(StateLine.StateType.None))
#			var degree_start = randf() * 2 * PI
#
#			for i in range(connection_matrix.get_state_count(StateLine.StateType.None)):
#				degree_pos.append(i * degree_step + degree_start)
#
#			var radius = degree_radius
#			var circle_y_start = 16 * 9
#
#			for j in range(connection_matrix.get_state_count(StateLine.StateType.None)):
#				var interaction : Interaction = Vertex.instantiate()
#
#				interaction.position.x = snapped((Initial.position.x + Final.position.x) / 2 + radius * cos(degree_pos[j]), 16)
#				interaction.position.y = snapped(circle_y_start +  + radius * sin(degree_pos[j]), 16)
#				interaction.visible = false
#				interaction.add_to_group('drawing_interactions')
#
#				Interactions.add_child(interaction)
#
#		temp_matrix = Generation.split_hadrons(temp_matrix, initial_state, final_state)
#
#		print('paths')
#
#		Generation.create_particles(temp_matrix)
#
#		Equation.set_symbols_visible(GLOBALS.STATE_LINE.INITIAL, false)
#		Equation.set_symbols_visible(GLOBALS.STATE_LINE.FINAL, false)
#
#		await get_tree().process_frame
#		get_tree().call_group('lines', 'move_text', true)
#		get_tree().call_group('lines', 'movey_text', true)
#
#		Equation.set_symbols_visible(GLOBALS.STATE_LINE.INITIAL, false)
#		Equation.set_symbols_visible(GLOBALS.STATE_LINE.FINAL, false)
#
#		await get_tree().process_frame
#		get_tree().call_group('lines', 'move_text', true)
#		get_tree().call_group('lines', 'movey_text', true)
#
#		generation_valid = true
#		for interaction in get_tree().get_nodes_in_group('interactions'):
#			if !interaction.valid and interaction.valid_colourless:
#				generation_valid = false
#				break
#
#		Equation.set_symbols_visible(GLOBALS.STATE_LINE.INITIAL, false)
#		Equation.set_symbols_visible(GLOBALS.STATE_LINE.FINAL, false)
#
#		if generation_valid:
#			break
#
#		if attempt % 10 == 0:
#			degree_radius -= 5
#
#		if attempt != MAX_ATTEMPTS - 1:
#			clear()
#
#	if !generation_valid:
#		Generation.print_matrix(matrix)
#
#	for interaction in get_tree().get_nodes_in_group('interactions'):
#		interaction.visible = true
#
#	for line in get_tree().get_nodes_in_group('lines'):
#		line.visible = true
#
#	Equation.set_symbols_visible(GLOBALS.STATE_LINE.INITIAL, false)
#	Equation.set_symbols_visible(GLOBALS.STATE_LINE.FINAL, false)
#
#	await get_tree().create_timer(0.01).timeout
#	get_tree().call_group('state_lines', 'update', true)
#	Equation.set_symbols_visible(GLOBALS.STATE_LINE.INITIAL, false)
#	Equation.set_symbols_visible(GLOBALS.STATE_LINE.FINAL, false)
#	await get_tree().create_timer(0.01).timeout
#	Equation.set_symbols_visible(GLOBALS.STATE_LINE.INITIAL, true)
#	Equation.set_symbols_visible(GLOBALS.STATE_LINE.FINAL, true)

func show_vision(state : int, is_show : bool) -> void:
	if !is_show:
		Pathfinding.showing_type = GLOBALS.VISION_TYPE.NONE
	
	else:
		match state:
			GLOBALS.VISION_TYPE.COLOUR:
				show_colour()
			GLOBALS.VISION_TYPE.SHADE:
				show_shade()

func generate(initialState : Array, finalState : Array, minDegree : int, maxDegree : int, interaction_checks : Array):
	clear()
	
	await get_tree().create_timer(0.01).timeout
	
	match (Generation.generate_diagram(initialState, finalState, minDegree, maxDegree, interaction_checks)):
		INVALID:
			get_node('Buttons/GenerationButton/GenerationUI').display_text('Failed to find')
		0:
			get_node('Buttons/GenerationButton/GenerationUI').display_text('Wrong quantum numbers')

func clear():
	mode = 'drawing'
	get_tree().call_group("interactions", "queue_free")
	get_tree().call_group("lines", "queue_free")
	get_tree().call_group("colour_lines", "queue_free")
	await get_tree().create_timer(0.01).timeout
	submitted_diagrams = []
