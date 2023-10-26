extends BaseTutorialStep

signal load_hadron_problem

func enter() -> void:
	load_hadron_problem.emit()
