extends Control

var selected_particle: int = ParticleData.Particle.none
var particle_buttons: Array[PanelButton] = []

var particle_button_group: ButtonGroup

@onready var Leptons = $HBoxContainer/Leptons/MovingContainer/Tab/Leptons
@onready var Bosons = $HBoxContainer/Bosons/MovingContainer/Tab/Bosons
@onready var Quarks = $HBoxContainer/Quarks/MovingContainer/Tab/Quarks
@onready var General = $HBoxContainer/General/MovingContainer/Tab/General

@onready var ParticleButtonCategories : Array = [
	Leptons, Bosons, Quarks, General
]

@onready var ParticleControls : Array = [
	$HBoxContainer/Leptons, $HBoxContainer/Bosons, $HBoxContainer/Quarks, $HBoxContainer/General
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
	for particle_button in particle_buttons:
		particle_button.button_group = particle_button_group

func clear_button_group() -> void:
	for particle_button in particle_buttons:
		particle_button.button_group = null

func disable_buttons(disable: bool, disabled_particles: Array = ParticleData.Particle.values()) -> void:
	for particle_button in particle_buttons:
		if particle_button.particle not in disabled_particles:
			continue
		
		particle_button.disabled = disable

func toggle_button_visiblity(to_visible: bool, particles: Array = ParticleData.Particle.values()) -> void:
	for particle_button in particle_buttons:
		if particle_button.particle not in particles:
			continue
		
		particle_button.visible = to_visible

func toggle_button_mute(mute: bool) -> void:
	for particle_button in particle_buttons:
		particle_button.mute = mute

func enter_particle_selection(problem: Problem) -> void:
	clear_button_group()
	disable_buttons(false)
	toggle_button_visiblity(true)
	toggle_button_group_visibility()
	
	if problem.allowed_particles.size() == 0:
		toggle_buttons(true)
	else:
		toggle_buttons(true, problem.allowed_particles)

func exit_particle_selection() -> void:
	add_buttons_to_button_group()

func get_toggled_particles(toggled: bool) -> Array[ParticleData.Particle]:
	var toggled_particles: Array[ParticleData.Particle] = []
	
	for particle_button in particle_buttons:
		if particle_button.button_pressed == toggled:
			toggled_particles.push_back(particle_button.particle)
	
	return toggled_particles

func toggle_button_group_visibility() -> void:
	for i in ParticleButtonCategories.size():
		ParticleControls[i].visible = ParticleButtonCategories[i].get_children().any(
			func(button: PanelButton): return button.visible
		)

func load_problem(problem: Problem) -> void:
	disable_buttons(true)
	toggle_button_visiblity(true)
	disable_buttons(false, problem.allowed_particles)
	
	if problem.hide_unavailable_particles:
		toggle_button_visiblity(false)
		toggle_button_visiblity(true, problem.allowed_particles)
		toggle_button_group_visibility()
		
#		for particle_control in ParticleControls:
#			particle_control.readjust()

func toggle_buttons(button_pressed: bool, particles: Array = ParticleData.Particle.values()) -> void:
	toggle_button_mute(true)
	for particle_button in particle_buttons:
		particle_button.button_pressed = button_pressed and particle_button.particle in particles
	toggle_button_mute(false)
