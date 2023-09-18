extends BaseMode

func process(_delta: float) -> Mode:
	if CreationInformation.submit.button_pressed:
		return Mode.ParticleSelection
	
	return Mode.Null

func enter() -> void:
	super.enter()
	
	ParticleButtons.enter_particle_selection()

func exit() -> void:
	ParticleButtons.exit_particle_selection()

func toggle_menu_visibility() -> void:
	ParticleButtons.show()
	
	GenerationTab.hide()
	ProblemTab.hide()
	VisionTab.hide()


