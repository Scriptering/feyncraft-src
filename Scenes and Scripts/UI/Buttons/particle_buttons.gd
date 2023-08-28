extends Control

var selected_particle: int = GLOBALS.Particle.none
var particle_buttons: Array[PanelButton] = []

@export var particle_button_group: ButtonGroup

@onready var Leptons = $HBoxContainer/Leptons/MovingContainer/Tab/Leptons
@onready var Bosons = $HBoxContainer/Bosons/MovingContainer/Tab/Bosons
@onready var Quarks = $HBoxContainer/Quarks/MovingContainer/Tab/Quarks
@onready var General = $HBoxContainer/General/MovingContainer/Tab/General

@onready var ParticleButtonCategories : Array = [
	Leptons, Bosons, Quarks, General
]

func _ready():
	for particle_button_category in ParticleButtonCategories:
		for particle_button in particle_button_category.get_children():
			particle_buttons.append(particle_button)
	
	for particle_button in particle_buttons:
		particle_button.button_group = particle_button_group
		particle_button.button_group.allow_unpress = false
		particle_button.connect("on_pressed", Callable(self, "on_particle_button_pressed"))

func on_particle_button_pressed(button):
	selected_particle = button.particle

