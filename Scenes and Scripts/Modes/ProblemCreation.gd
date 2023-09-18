extends BaseMode

func process(_delta: float) -> Mode:
	if CreationInformation.submit.button_pressed:
		return Mode.SolutionCreation
	
	return Mode.Null

func toggle_menu_visibility() -> void:
	ParticleButtons.show()
	
	GenerationTab.hide()
	ProblemTab.hide()
	VisionTab.hide()
