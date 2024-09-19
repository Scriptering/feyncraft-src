extends Control

signal particle_selected(particle: ParticleData.Particle)

var selected_particle: int = ParticleData.Particle.none
var particle_buttons: Array[PanelButton] = []

var particle_button_group: ButtonGroup

@onready var ParticleButtonCategories : Array[Container] = [
	%Leptons, %Bosons, %Quarks
]

func _ready() -> void:
	for particle_button_category:Container in ParticleButtonCategories:
		for child:Control in particle_button_category.get_children():
			if child is PanelButton:
				particle_buttons.append(child)
				child.on_pressed.connect(on_particle_button_pressed)
		
	add_buttons_to_button_group()

func on_particle_button_pressed(button:PanelButton) -> void:
	selected_particle = button.particle
	particle_selected.emit(selected_particle)

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

func is_button_visible(button: PanelButton) -> bool:
	return button.visible

func get_toggled_particles(toggled: bool) -> Array[ParticleData.Particle]:
	var toggled_particles: Array[ParticleData.Particle] = []
	
	for particle_button:PanelButton in particle_buttons:
		if particle_button.button_pressed == toggled:
			toggled_particles.push_back(particle_button.particle)
	
	return toggled_particles

func has_visible_button(container: Container) -> bool:
	for child:Control in container.get_children():
		if child is PanelButton and child.visible:
			return true
	
	return false

func toggle_button_group_visibility() -> void:
	$HBoxContainer/Leptons.visible = has_visible_button(%Leptons)
	$HBoxContainer/Bosons.visible = has_visible_button(%Bosons)
	$HBoxContainer/Quarks.visible = has_visible_button(%Quarks)

func load_problem(problem: Problem) -> void:
	if problem.allowed_particles.size() > 0:
		disable_buttons(true)
		toggle_button_visiblity(true)
		disable_buttons(false, problem.allowed_particles)
	else:
		disable_buttons(false)
	
	if problem.hide_unavailable_particles:
		toggle_button_visiblity(false)
		toggle_button_visiblity(true, problem.allowed_particles)
		toggle_button_group_visibility()
	else:
		toggle_button_visiblity(true)
		toggle_button_group_visibility()

func toggle_buttons(button_pressed: bool, particles: Array = ParticleData.Particle.values()) -> void:
	toggle_button_mute(true)
	for particle_button in particle_buttons:
		particle_button.button_pressed = button_pressed and particle_button.particle in particles
	toggle_button_mute(false)
