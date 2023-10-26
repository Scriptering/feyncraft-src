extends Control

@onready var Level = get_tree().get_nodes_in_group('level')[0]
@onready var Initial = Level.get_node('Initial')
@onready var Final = Level.get_node('Final')
@onready var Dialog = get_node('VBoxContainer/PanelContainer/Popupcontainer')
@onready var DegreeRange = get_node('VBoxContainer/PanelContainer/VBoxContainer/OptionsContainer/DegreeSlider/VBoxContainer/RangeSlider')
@onready var Equation = get_node('Equation')
@onready var EM_check := get_node('VBoxContainer/PanelContainer/VBoxContainer/OptionsContainer/GridContainer/em')
@onready var strong_check := get_node('VBoxContainer/PanelContainer/VBoxContainer/OptionsContainer/GridContainer/strong')
@onready var weak_check := get_node('VBoxContainer/PanelContainer/VBoxContainer/OptionsContainer/GridContainer/weak')
@onready var electroweak_check := get_node('VBoxContainer/PanelContainer/VBoxContainer/OptionsContainer/GridContainer/electroweak')
@onready var Cursor = Level.get_node('Cursor')
@onready var OptionsContainer = get_node('VBoxContainer/PanelContainer/VBoxContainer/OptionsContainer')

@export var InitialState : Array[ParticleData.Particle]
@export var FinalState : Array[ParticleData.Particle]


@export var min_degree : int = -1
@export var max_degree : int = -1

var state_lines : Array = [Initial, Final]

var can_generate := false
var hovering := false

@onready var minDegree : int
@onready var maxDegree : int

signal generate

const MARGIN = 4

func _ready():
	# warning-ignore:return_value_discarded
	connect('generate', Callable(Level, 'generate'))
	
	Dialog.add_theme_constant_override('offset_top', -10)
	can_generate = !(InitialState == [] and FinalState == [])
	
	set_can_generate(can_generate)
	
	if min_degree != -1 and max_degree != -1:
		DegreeRange.set_minValue(min_degree)
		DegreeRange.set_maxValue(max_degree)
		
	minDegree = DegreeRange.minValue
	maxDegree = DegreeRange.maxValue

func _process(_delta):
	get_node('Equation').global_position = get_node('VBoxContainer/PanelContainer/VBoxContainer/EquationHolder').global_position
	get_node('Equation').global_position.x -= 1
	get_node('Equation').global_position.y -= 2
	
	
func _on_Save_pressed() -> void:
	var particles_hadrons = Equation.get_particles_from_states('Initial', Initial.connections)
	Equation.make_equation(GLOBALS.STATE_LINE.INITIAL, particles_hadrons[0], particles_hadrons[1])
	InitialState = get_state_interactions(particles_hadrons)
	
	particles_hadrons = Equation.get_particles_from_states('Final', Final.connections)
	Equation.make_equation(GLOBALS.STATE_LINE.FINAL, particles_hadrons[0], particles_hadrons[1])
	FinalState = get_state_interactions(particles_hadrons)
	
	if InitialState.size() == 0 and FinalState.size() == 0:
		display_text('No particles to save')
		set_can_generate(false)
	else:
		display_text('Saved!')
		set_can_generate(true)
		
		set_checks(Initial.connections + Final.connections)

func get_state_interactions(particles_hadrons : Array) -> Array:
	var particles : Array = particles_hadrons[0]
	var hadrons : Array = particles_hadrons[1]
	var state_interactions := []
	
	for particle in particles:
		state_interactions.append([particle.antitype()])
	
	for hadron in hadrons:
		var quarks := []
		for line in hadron.quarks:
			quarks.append(line.antitype())
		
		state_interactions.append(quarks)
		
	return state_interactions

func _on_Generate_pressed() -> void:
	if can_generate:
		emit_signal('generate', InitialState, FinalState, DegreeRange.minValue, DegreeRange.maxValue,
		[EM_check.pressed, strong_check.pressed, weak_check.pressed, electroweak_check.pressed])

func display_text(text : String):
	Dialog.get_node('Text').text = text
	Dialog.visible = true
	await get_tree().create_timer(2).timeout
	Dialog.visible = false

func set_can_generate(new_value : bool) -> void:
	get_node('VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Generate').set_disabled(!new_value)
	can_generate = new_value

func is_hovered():
	return hovering

func _on_MouseTrap_mouse_entered():
	hovering = true

func _on_MouseTrap_mouse_exited():
	hovering = false

func _on_PanelContainer_mouse_entered():
	hovering = true

func _on_PanelContainer_mouse_exited():
	hovering = false

func _on_electroweaktype_pressed():
	Cursor.button_press()
	if electroweak_check.pressed:
		electroweak_check.button_pressed = (EM_check.pressed and weak_check.pressed)

func _on_electroweak_pressed():
	Cursor.button_press()
	if electroweak_check.pressed:
		EM_check.button_pressed = true
		weak_check.button_pressed = true

func set_checks(state_connections : Array):
	var particles := []
	for line in state_connections:
		particles.append(line.antitype())
	
	if ParticleData.Particle.photon in particles:
		EM_check.button_pressed = true
	if ParticleData.Particle.gluon in particles:
		strong_check.button_pressed = true
	if ParticleData.Particle.W in particles or ParticleData.Particle.anti_W in particles:
		weak_check.button_pressed = true
	if ParticleData.Particle.H in particles or ParticleData.Particle.Z in particles:
		electroweak_check.button_pressed = true
		_on_electroweak_pressed()

func _on_strong_pressed():
	Cursor.button_press()

func _on_options_pressed():
	OptionsContainer.visible = !OptionsContainer.visible
