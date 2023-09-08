extends TextureRect

var hadron: GLOBALS.Hadrons
var Symbol := preload("res://Scenes and Scripts/UI/Equations/EquationSymbol.tscn")
var HadronLabel := preload("res://Scenes and Scripts/UI/Equation/hadron_content_label.tscn")

func init(_hadron: GLOBALS.Hadrons) -> void:
	hadron = _hadron
	
	if hadron == GLOBALS.Hadrons.Invalid:
		return
	
	var hadron_label := HadronLabel.instantiate()
	
	for i in range(GLOBALS.HADRON_QUARK_CONTENT[hadron].size()):
		if i != 0:
			hadron_label.add_child(create_slash())
		
		for hadron_content in GLOBALS.HADRON_QUARK_CONTENT[hadron]:
			for quark in hadron_content:
				hadron_label.add_child(create_particle_symbol([quark]))
	
	$Tooltip.add_content(hadron_label)
	
func create_slash() -> TextureRect:
	var slash := Symbol.instantiate()
	slash.texture = load("res://Textures/UI/Equation/slash.png")
	return slash

func create_particle_symbol(interaction: Array) -> TextureRect:
	var particle := Symbol.instantiate()
	particle.texture = GLOBALS.PARTICLE_TEXTURES[get_particle_name(interaction)]
	return particle

func get_particle_name(interaction: Array) -> String:
	if interaction.size() == 1:
		return GLOBALS.Particle.keys()[GLOBALS.Particle.values().find(interaction.front())]
	
	for hadron_content in GLOBALS.HADRON_QUARK_CONTENT.keys():
		if interaction in GLOBALS.HADRON_QUARK_CONTENT[hadron_content]:
			return GLOBALS.HADRON_NAMES[hadron_content]
	
	return ''
