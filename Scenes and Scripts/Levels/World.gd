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
	
	Generation.connect('draw_diagram', Callable($diagram_actions, 'draw_raw_diagram'))
	
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
