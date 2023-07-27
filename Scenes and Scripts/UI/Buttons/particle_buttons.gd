extends Control

var selected_particle: int = GLOBALS.Particle.none
var particle_buttons: Array[PanelButton] = []

@export var particle_button_group: ButtonGroup

@onready var Leptons = $Leptons/MovingContainer/Tab/Leptons
@onready var Bosons = $Bosons/MovingContainer/Tab/Bosons
@onready var Quarks = $Quarks/MovingContainer/Tab/Quarks

func _ready():
	for particle_button in Leptons.get_children():
		particle_buttons.append(particle_button)
		
	for particle_button in Bosons.get_children():
		particle_buttons.append(particle_button)

	for particle_button in Quarks.get_children():
		particle_buttons.append(particle_button)
	
	for particle_button in particle_buttons:
		particle_button.button_group = particle_button_group
		particle_button.button_group.allow_unpress = false
		particle_button.connect("on_pressed", Callable(self, "on_particle_button_pressed"))

func on_particle_button_pressed(button):
	selected_particle = button.particle

