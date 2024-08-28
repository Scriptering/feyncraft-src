extends BaseTutorialStep

signal load_hadron_problem

func enter() -> void:
	super()
	load_hadron_problem.emit()
