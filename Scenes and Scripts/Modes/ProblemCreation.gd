extends BaseMode

func toggle_menu_visibility() -> void:
	ParticleButtons.show()
	
	GenerationTab.hide()
	ProblemTab.hide()
	VisionTab.hide()
