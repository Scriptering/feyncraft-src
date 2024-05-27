extends TextureRect

const MINIMUM_LABEL_SIZE := Vector2(10, 10)

var hadron: ParticleData.Hadrons
var Symbol := preload("res://Scenes and Scripts/UI/Equation/EquationSymbol.tscn")

func init(_hadron: ParticleData.Hadrons) -> void:
	hadron = _hadron
	
	if hadron == ParticleData.Hadrons.Invalid:
		return
	
	for i:int in range(ParticleData.HADRON_QUARK_CONTENT[hadron].size()):
		if i != 0:
			$Tooltip.add_content(create_slash())
		
		for quark:ParticleData.Particle in ParticleData.HADRON_QUARK_CONTENT[hadron][i]:
			$Tooltip.add_content(create_particle_symbol([quark]))
	
func create_slash() -> TextureRect:
	var slash : TextureRect = Symbol.instantiate()
	slash.texture = load("res://Textures/UI/Equation/slash.png")
	slash.stretch_mode = STRETCH_KEEP
	slash.expand_mode = EXPAND_KEEP_SIZE
	slash.size_flags_vertical = SIZE_SHRINK_END
	
	return slash

func create_particle_symbol(interaction: Array) -> TextureRect:
	var particle := Symbol.instantiate()
	particle.texture = ParticleData.particle_textures[get_particle_name(interaction)]
	particle.stretch_mode = STRETCH_KEEP
	particle.expand_mode = EXPAND_KEEP_SIZE
	particle.size_flags_vertical = SIZE_SHRINK_END
	
	return particle

func get_particle_name(interaction: Array) -> String:
	if interaction.size() == 1:
		return ParticleData.Particle.keys()[ParticleData.Particle.values().find(interaction.front())]
	
	for hadron_type:ParticleData.Hadrons in ParticleData.HADRON_QUARK_CONTENT.keys():
		if interaction in ParticleData.HADRON_QUARK_CONTENT[hadron_type]:
			return ParticleData.HADRON_NAMES[hadron_type]
	
	return ''
