extends PullOutTab

signal submit_pressed

@export var diagram_viewer_offset: Vector2 = Vector2(15, 15)

@onready var Equation : PanelContainer = $MovingContainer/VBoxContainer/Tab/HBoxContainer/Equation
@onready var SubmissionFeedback : PullOutTab = $MovingContainer/SubmitFeedback
@onready var DiagramNotValid : Control = $MovingContainer/SubmitFeedback/MovingContainer/PanelContainer/VBoxContainer/DiagramNotValid
@onready var DiagramNotConnected : Control = (
	$MovingContainer/SubmitFeedback/MovingContainer/PanelContainer/VBoxContainer/DiagramNotConnected
)
@onready var DiagramDuplicate : Control = $MovingContainer/SubmitFeedback/MovingContainer/PanelContainer/VBoxContainer/DuplicateDiagram
@onready var DiagramSubmitted : Control = $MovingContainer/SubmitFeedback/MovingContainer/PanelContainer/VBoxContainer/DiagramSubmitted
@onready var DiagramNotSolution : Control = $MovingContainer/SubmitFeedback/MovingContainer/PanelContainer/VBoxContainer/DiagramNotSolution

var Diagram: MainDiagram
var current_problem: Problem
var SubmittedDiagramViewer: MiniDiagramViewer
var ProblemGeneration: Node
var SolutionGeneration: Node

var problem_history: Array[Problem] = []

func init(
	diagram: DiagramBase, _current_problem: Problem, submitted_diagrams_viewer: MiniDiagramViewer, problem_generation: Node,
	_solution_generation: Node
) -> void:

	Diagram = diagram
	current_problem = _current_problem
	SubmittedDiagramViewer = submitted_diagrams_viewer
	SubmittedDiagramViewer.diagram_deleted.connect(submitted_diagram_deleted)
	SubmittedDiagramViewer.closed.connect(toggle_diagram_viewer)
	ProblemGeneration = problem_generation
	SolutionGeneration = _solution_generation

	
func _on_submit_pressed() -> void:
	submit_diagram()
	submit_pressed.emit()

func submitted_diagram_deleted(index: int) -> void:
	current_problem.submitted_diagrams.remove_at(index)
	
	update_view_submission_button()

func check_submission(submission: DrawingMatrix) -> bool:
	var diagram_is_valid: bool = true
	
	for child in $MovingContainer/SubmitFeedback/MovingContainer/PanelContainer/VBoxContainer.get_children():
		child.hide()
	
	if !Diagram.is_valid():
		DiagramNotValid.show()
		diagram_is_valid = false
	
	if !Diagram.is_fully_connected(true):
		DiagramNotConnected.show()
		diagram_is_valid = false

	if current_problem.is_submission_duplicate(submission):
		DiagramDuplicate.show()
		diagram_is_valid = false
	
	if !current_problem.is_submission_solution(submission):
		DiagramNotSolution.show()
		diagram_is_valid = false
	
	if diagram_is_valid:
		DiagramSubmitted.show()
	
	SubmissionFeedback.pull_out()
	
	return diagram_is_valid

func update_view_submission_button() -> void:
	$MovingContainer/VBoxContainer/Tab/HBoxContainer/ViewSubmissions.disabled = current_problem.submitted_diagrams.size() == 0

func submit_diagram() -> void:
	var submission: DrawingMatrix = Diagram.generate_drawing_matrix_from_diagram()
	
	if !check_submission(submission):
		return
	
	current_problem.submit_diagram(submission)
	SubmittedDiagramViewer.store_diagram(submission)
	
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

func load_new_problem(problem: Problem, save_to_history: bool = true) -> void:
	if save_to_history:
		problem_history.push_back(current_problem)
	current_problem = problem
	Equation.load_problem(problem)
	
func _on_solution_pressed() -> void:
	EVENTBUS.draw_diagram_raw(generate_solution())

func _on_rewind_pressed() -> void:
	load_new_problem(problem_history[-1], false)
	problem_history.pop_back()
	
	$MovingContainer/VBoxContainer/Tab/HBoxContainer/Rewind.disabled = problem_history.size() == 0
