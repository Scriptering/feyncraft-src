extends InfoPanel

@onready var check_button: CheckButton = $VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/CheckButton
@onready var solution_count: SpinBox = $VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/SolutionCountContainer/SolutionCountContainer/SolutionCount

func _on_check_button_toggled(button_pressed: bool) -> void:
	$VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/SolutionCountContainer.visible = button_pressed

func _process(_delta: float) -> void:
	if GLOBALS.creating_problem and GLOBALS.creating_problem.custom_solutions:
		solution_count.max_value = GLOBALS.creating_problem.solutions.size()

func _next() -> void:
	if check_button.button_pressed:
		GLOBALS.creating_problem.solution_count = solution_count.value
	
	next.emit()
