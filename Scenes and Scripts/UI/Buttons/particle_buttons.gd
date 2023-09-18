extends Control

var selected_particle: int = GLOBALS.Particle.none
var particle_buttons: Array[PanelButton] = []

var particle_button_group: ButtonGroup

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
			particle_button.connect("on_pressed", Callable(self, "on_particle_button_pressed"))
		
	add_buttons_to_button_group()

func on_particle_button_pressed(button) -> void:
	selected_particle = button.particle

func add_buttons_to_button_group() -> void:
	particle_button_group = ButtonGroup.new()
	particle_button_group.allow_unpress = true
	for particle_button in particle_buttons:
		particle_button.button_group = particle_button_group

func clear_button_group() -> void:
	particle_button_group.free()

func disable_buttons(disabled_particles: Array[GLOBALS.Particle]) -> void:
	for particle_button in particle_buttons:
		particle_button.disabled = particle_button.particle in disabled_particles

func enter_particle_selection() -> void:
	clear_button_group()
	toggle_buttons(true)

func get_toggled_particles(toggled: bool) -> Array[GLOBALS.Particle]:
	var toggled_particles: Array[GLOBALS.Particle] = []
	
	for particle_button in particle_buttons:
		if particle_button.button_pressed:
			toggled_particles.push_back(particle_button.particle)
	
	return toggled_particles

func toggle_buttons(button_pressed: bool) -> void:
	for particle_button in particle_buttons:
		var is_particle_button_mute: bool = particle_button.mute
		particle_button.mute = true
		particle_button.button_pressed = button_pressed
		particle_button.mude = is_particle_button_mute

func exit_particle_selection() -> void:
	var disabled_particles: Array[GLOBALS.Particle] = get_toggled_particles(false)
	toggle_buttons(true)
	disable_buttons(disabled_particles)
	add_buttons_to_button_group()
