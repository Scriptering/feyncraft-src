extends PullOutTab

@onready var Level = get_tree().get_nodes_in_group('level')[0]
@onready var Initial : StateLine = Level.get_node('Initial')
@onready var Final : StateLine = Level.get_node('Final')
@onready var DegreeRange = $MovingContainer/PanelContainer/VBoxContainer/OptionsContainer/DegreeSlider/VBoxContainer/RangeSlider
@onready var EM_check := $MovingContainer/PanelContainer/VBoxContainer/OptionsContainer/GridContainer/em
@onready var strong_check := $MovingContainer/PanelContainer/VBoxContainer/OptionsContainer/GridContainer/strong
@onready var weak_check := $MovingContainer/PanelContainer/VBoxContainer/OptionsContainer/GridContainer/weak
@onready var electroweak_check := $MovingContainer/PanelContainer/VBoxContainer/OptionsContainer/GridContainer/electroweak
@onready var OptionsContainer = $MovingContainer/PanelContainer/VBoxContainer/OptionsContainer
@onready var GenerateButton := $MovingContainer/PanelContainer/VBoxContainer/HBoxContainer/Generate

@export var InitialState : Array[Array]
@export var FinalState : Array[Array]

@export var min_degree : int = -1
@export var max_degree : int = -1

var state_lines : Array = [Initial, Final]

var can_generate : bool = false : set = _set_can_generate
var hovering := false

signal generate

const MARGIN = 4

func _ready():
	self.connect('generate', Callable(Level, 'generate'))
	
	can_generate = !(InitialState == [] and FinalState == [])
	
	self.can_generate = can_generate
	
	if min_degree != -1 and max_degree != -1:
		DegreeRange.minValue = min_degree
		DegreeRange.maxValue = max_degree

func _set_can_generate(new_value: bool) -> void:
	can_generate = new_value
	GenerateButton.disabled = new_value
	
func _on_Save_pressed() -> void:
	InitialState = get_state_interactions(Initial)
	FinalState = get_state_interactions(Final)
	
	if InitialState.size() == 0 and FinalState.size() == 0:
		self.can_generate = false
	else:
		self.can_generate = true
		set_checks(Initial.connections + Final.connections)

func get_state_interactions(state_line: StateLine) -> Array[Array]:
	var state_interactions : Array[Array] = []
	
	for particle in state_line.get_connected_lone_particles():
		state_interactions.append([particle])
	
	for hadron in state_line.hadrons:
		state_interactions.append(hadron.quarks)
		
	return state_interactions

func _on_Generate_pressed() -> void:
	if can_generate:
		emit_signal('generate', InitialState, FinalState, DegreeRange.minValue, DegreeRange.maxValue,
		[EM_check.pressed, strong_check.pressed, weak_check.pressed, electroweak_check.pressed])

func _on_electroweaktype_pressed():
	if electroweak_check.pressed:
		electroweak_check.button_pressed = (EM_check.pressed and weak_check.pressed)

func _on_electroweak_pressed():
	if electroweak_check.pressed:
		EM_check.button_pressed = true
		weak_check.button_pressed = true

func set_checks(state_connections : Array):
	var particles := []
	for line in state_connections:
		particles.append(line.antitype())
	
	if GLOBALS.Particle.photon in particles:
		EM_check.button_pressed = true
	if GLOBALS.Particle.gluon in particles:
		strong_check.button_pressed = true
	if GLOBALS.Particle.W in particles or GLOBALS.Particle.anti_W in particles:
		weak_check.button_pressed = true
	if GLOBALS.Particle.H in particles or GLOBALS.Particle.Z in particles:
		electroweak_check.button_pressed = true
		_on_electroweak_pressed()

func _on_options_pressed():
	OptionsContainer.visible = !OptionsContainer.visible
