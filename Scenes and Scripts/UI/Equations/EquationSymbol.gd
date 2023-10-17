extends TextureRect

const MINIMUM_LABEL_SIZE := Vector2(10, 10)

var hadron: GLOBALS.Hadrons
var Symbol := preload("res://Scenes and Scripts/UI/Equations/EquationSymbol.tscn")

func init(_hadron: GLOBALS.Hadrons) -> void:
	hadron = _hadron
	
	if hadron == GLOBALS.Hadrons.Invalid:
		return
	
	for i in range(GLOBALS.HADRON_QUARK_CONTENT[hadron].size()):
		if i != 0:
			$Tooltip.add_content(create_slash())
		
		for hadron_content in GLOBALS.HADRON_QUARK_CONTENT[hadron]:
			for quark in hadron_content:
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
	particle.texture = GLOBALS.PARTICLE_TEXTURES[get_particle_name(interaction)]
	particle.stretch_mode = STRETCH_KEEP
	particle.expand_mode = EXPAND_KEEP_SIZE
	particle.size_flags_vertical = SIZE_SHRINK_END
	
	return particle

func get_particle_name(interaction: Array) -> String:
	if interaction.size() == 1:
		return GLOBALS.Particle.keys()[GLOBALS.Particle.values().find(interaction.front())]
	
	for hadron_content in GLOBALS.HADRON_QUARK_CONTENT.keys():
		if interaction in GLOBALS.HADRON_QUARK_CONTENT[hadron_content]:
			return GLOBALS.HADRON_NAMES[hadron_content]
	
	return ''
