@tool
extends PanelButton

@export var particle: GLOBALS.Particle:
	set(new_value):
		particle = new_value
		self.icon = get_particle_icon(particle)

func get_particle_name(new_particle: int):
	return GLOBALS.Particle.keys()[GLOBALS.Particle.values().find(new_particle)]

func get_particle_icon(new_particle: int) -> Texture2D:
	return load("res://Textures/Buttons/icons/Particles/" + get_particle_name(new_particle) + ".png")
