extends Control

@onready var Level = get_tree().get_nodes_in_group('level')[0]
@onready var Initial = Level.get_node('Initial')
@onready var Final = Level.get_node('Final')
@onready var Dialog = get_node('VBoxContainer/PanelContainer/Popupcontainer')
@onready var DegreeSlider = get_node('VBoxContainer/PanelContainer/VBoxContainer/OptionsContainer/DegreeSlider/VBoxContainer/RangeSlider')
@onready var Equation = get_node('Equation')
@onready var EM_check := get_node('VBoxContainer/PanelContainer/VBoxContainer/OptionsContainer/GridContainer/em')
@onready var strong_check := get_node('VBoxContainer/PanelContainer/VBoxContainer/OptionsContainer/GridContainer/strong')
@onready var weak_check := get_node('VBoxContainer/PanelContainer/VBoxContainer/OptionsContainer/GridContainer/weak')
@onready var electroweak_check := get_node('VBoxContainer/PanelContainer/VBoxContainer/OptionsContainer/GridContainer/electroweak')
@onready var Cursor = Level.get_node('Cursor')
@onready var OptionsContainer = get_node('VBoxContainer/PanelContainer/VBoxContainer/OptionsContainer')

@export var InitialState : Array[GLOBALS.Particle]
@export var FinalState : Array[GLOBALS.Particle]

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
	
	display_text('Not yet functional :)')

	Dialog.add_theme_constant_override('offset_top', -10)

	if min_degree != -1 and max_degree != -1:
		DegreeSlider.minValue = min_degree
		DegreeSlider.maxValue = max_degree
		
	minDegree = DegreeSlider.minValue
	maxDegree = DegreeSlider.maxValue

func _process(_delta):
	get_node('Equation').global_position = get_node('VBoxContainer/PanelContainer/VBoxContainer/EquationHolder').global_position
	get_node('Equation').global_position.x -= 1
	get_node('Equation').global_position.y -= 2


func display_text(text : String):
	Dialog.get_node('Text').text = text
	Dialog.visible = true
#	yield(get_tree().create_timer(2), 'timeout')
#	Dialog.visible = false

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

func _on_strong_pressed():
	Cursor.button_press()

func _on_Options_pressed():
	OptionsContainer.visible = !OptionsContainer.visible
