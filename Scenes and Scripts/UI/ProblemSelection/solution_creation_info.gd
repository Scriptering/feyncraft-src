extends InfoPanel

@onready var check_button: CheckButton = $VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/CheckButton
@onready var solution_count: SpinBox = $VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/SolutionCountContainer/SolutionCountContainer/SolutionCount

var ProblemTab: Node

func _on_check_button_toggled(button_pressed: bool) -> void:
	$VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/SolutionCountContainer.visible = button_pressed

func init(problem_tab: Node) -> void:
	ProblemTab = problem_tab

func _process(_delta: float) -> void:
	if ProblemTab:
		if ProblemTab.submitted_diagrams.size() > 0:
			solution_count.max_value = ProblemTab.submitted_diagrams.size()
		else:
			solution_count.max_value = 5

func _next() -> void:
	if check_button.button_pressed:
		GLOBALS.creating_problem.solution_count = int(solution_count.value)
	
	next.emit()
