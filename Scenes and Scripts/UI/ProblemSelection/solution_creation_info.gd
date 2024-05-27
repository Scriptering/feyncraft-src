extends InfoPanel

@onready var custom_solutions: CheckButton = $VBoxContainer/VBoxContainer/PanelContainer2/VBoxContainer/CustomSolutions
@onready var allow_other_solutions: CheckButton = $VBoxContainer/VBoxContainer/PanelContainer2/VBoxContainer/AllowOtherSolutions
@onready var custom_solution_count: CheckButton = $VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/CustomSolutionCount
@onready var solution_count: SpinBox = $VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/SolutionCountContainer/SolutionCountContainer/SolutionCount

var ProblemTab: Node

func _on_check_button_toggled(button_pressed: bool) -> void:
	$VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/SolutionCountContainer.visible = button_pressed

func init(problem_tab: Node) -> void:
	ProblemTab = problem_tab

func update_custom_solutions() -> void:
	var no_solutions: bool = ProblemTab.submitted_diagrams.size() == 0 and custom_solutions.button_pressed
	$VBoxContainer/VBoxContainer/NoSolutions.visible = no_solutions
	$VBoxContainer/Buttons/Submit.disabled = no_solutions

func _process(_delta: float) -> void:
	if custom_solutions.button_pressed:
		update_custom_solutions()
		
	if ProblemTab:
		if custom_solutions.button_pressed:
			solution_count.max_value = ProblemTab.submitted_diagrams.size()
		else:
			solution_count.max_value = 5

func _exit() -> void:
	Globals.creating_problem.custom_solutions = custom_solutions.button_pressed
	Globals.creating_problem.allow_other_solutions = allow_other_solutions.button_pressed
	Globals.creating_problem.custom_solution_count = custom_solution_count.button_pressed

	if custom_solutions.button_pressed:
		Globals.creating_problem.solutions = ProblemTab.submitted_diagrams

	if custom_solution_count.button_pressed:
		Globals.creating_problem.solution_count = int(solution_count.value)

	exit.emit()

func _on_custom_solutions_toggled(button_pressed: bool) -> void:
	allow_other_solutions.visible = button_pressed
	update_custom_solutions()
