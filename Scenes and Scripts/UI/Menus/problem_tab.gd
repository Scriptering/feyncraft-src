extends PullOutTab

signal submit_pressed

@export var diagram_viewer_offset: Vector2 = Vector2(15, 15)
@export var DegreeLabel: Label
@export var SubmitButton: PanelButton

@onready var Equation : PanelContainer = $MovingContainer/VBoxContainer/Tab/HBoxContainer/Equation
@onready var SubmissionFeedback : PullOutTab = $MovingContainer/SubmitFeedback
@onready var DiagramDuplicate : Control = $MovingContainer/SubmitFeedback/MovingContainer/PanelContainer/VBoxContainer/DuplicateDiagram
@onready var DiagramSubmitted : Control = $MovingContainer/SubmitFeedback/MovingContainer/PanelContainer/VBoxContainer/DiagramSubmitted
@onready var DiagramNotSolution : Control = $MovingContainer/SubmitFeedback/MovingContainer/PanelContainer/VBoxContainer/DiagramNotSolution
@onready var IncorrectOrder: HBoxContainer = $MovingContainer/SubmitFeedback/MovingContainer/PanelContainer/VBoxContainer/IncorrectOrder

var Diagram: MainDiagram
var current_problem: Problem:
	set(new_value): current_problem = new_value
var SubmittedDiagramViewer: MiniDiagramViewer
var ProblemGeneration: Node
var SolutionGeneration: Node

var problem_history: Array[Problem] = []

func init(
	diagram: DiagramBase, _current_problem: Problem, submitted_diagrams_viewer: MiniDiagramViewer, problem_generation: Node,
	_solution_generation: Node
) -> void:

	Diagram = diagram
	Diagram.action_taken.connect(_on_diagram_action)
	current_problem = _current_problem
	SubmittedDiagramViewer = submitted_diagrams_viewer
	SubmittedDiagramViewer.diagram_deleted.connect(submitted_diagram_deleted)
	SubmittedDiagramViewer.closed.connect(toggle_diagram_viewer)
	ProblemGeneration = problem_generation
	SolutionGeneration = _solution_generation

func _on_diagram_action() -> void:
	update_degree_label()

func update_degree_label() -> void:
	DegreeLabel.text = str(Diagram.get_degree()) + "/" + str(current_problem.degree)

func _on_submit_pressed() -> void:
	submit_diagram()
	submit_pressed.emit()

func submitted_diagram_deleted(index: int) -> void:
	current_problem.submitted_diagrams.remove_at(index)
	
	update_view_submission_button()

func check_submission(submission: DrawingMatrix) -> bool:
	for child in $MovingContainer/SubmitFeedback/MovingContainer/PanelContainer/VBoxContainer.get_children():
		child.hide()
	
	if Diagram.get_degree() != current_problem.degree:
		IncorrectOrder.show()
		return false

	if current_problem.is_submission_duplicate(submission):
		DiagramDuplicate.show()
		return false
	
	if !current_problem.is_submission_solution(submission):
		DiagramNotSolution.show()
		return false
	
	DiagramSubmitted.show()
	return true

func update_view_submission_button() -> void:
	$MovingContainer/VBoxContainer/Tab/HBoxContainer/ViewSubmissions.disabled = current_problem.submitted_diagrams.size() == 0

func update_submitted_solution_count() -> void:
	SubmitButton.text = str(current_problem.submitted_diagrams.size()) + "/" + str(current_problem.solution_count)

func submit_diagram() -> void:
	var submission: DrawingMatrix = Diagram.generate_drawing_matrix_from_diagram()
	var submission_valid: bool = check_submission(submission)
	SubmissionFeedback.pull_out()
	if !submission_valid:
		return
	
	current_problem.submit_diagram(submission)
	SubmittedDiagramViewer.store_diagram(submission)
	
	update_submitted_solution_count()
	update_view_submission_button()

func generate_solution() -> ConnectionMatrix:
	return(SolutionGeneration.generate_diagrams(
		current_problem.state_interactions[StateLine.StateType.Initial], current_problem.state_interactions[StateLine.StateType.Final],
		1, 10, SolutionGeneration.generate_useable_interactions_from_particles(current_problem.allowed_particles),
		SolutionGeneration.Find.One
	))[0]

func toggle_diagram_viewer() -> void:
	SubmittedDiagramViewer.visible = !SubmittedDiagramViewer.visible
	SubmittedDiagramViewer.position = diagram_viewer_offset + position

func _on_view_submissions_pressed() -> void:
	toggle_diagram_viewer()

func load_problem(problem: Problem, save_to_history: bool = true) -> void:
	if save_to_history:
		problem_history.push_back(current_problem)
	current_problem = problem
	Equation.load_problem(problem)
	
func _on_solution_pressed() -> void:
	EVENTBUS.draw_diagram_raw(generate_solution())

func _on_rewind_pressed() -> void:
	load_problem(problem_history[-1], false)
	problem_history.pop_back()
	
	$MovingContainer/VBoxContainer/Tab/HBoxContainer/Rewind.disabled = problem_history.size() == 0
