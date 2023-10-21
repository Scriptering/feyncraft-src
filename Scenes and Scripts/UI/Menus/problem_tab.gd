extends PullOutTab

signal submit_pressed
signal next_problem_pressed
signal prev_problem_pressed

@export var diagram_viewer_offset: Vector2 = Vector2(15, 15)
@export var DegreeLabel: Label
@export var SubmitButton: PanelButton
@export var NextProblem: PanelButton
@export var PrevProblem: PanelButton

@onready var Equation : PanelContainer = $MovingContainer/VBoxContainer/Tab/HBoxContainer/Equation
@onready var SubmissionFeedback : PullOutTab = $MovingContainer/SubmitFeedback
@onready var DiagramDuplicate : Control = $MovingContainer/SubmitFeedback/MovingContainer/PanelContainer/VBoxContainer/DuplicateDiagram
@onready var DiagramSubmitted : Control = $MovingContainer/SubmitFeedback/MovingContainer/PanelContainer/VBoxContainer/DiagramSubmitted
@onready var DiagramNotSolution : Control = $MovingContainer/SubmitFeedback/MovingContainer/PanelContainer/VBoxContainer/DiagramNotSolution
@onready var IncorrectOrder: HBoxContainer = $MovingContainer/SubmitFeedback/MovingContainer/PanelContainer/VBoxContainer/IncorrectOrder

var Diagram: MainDiagram
var current_problem: Problem = null:
	set(new_value): current_problem = new_value
var SubmittedDiagramViewer: MiniDiagramViewer
var ProblemGeneration: Node
var SolutionGeneration: Node

var submitted_diagrams: Array[DrawingMatrix] = []

var in_solution_creation: bool = false:
	set(new_value):
		in_solution_creation = new_value
		
		if in_solution_creation:
			_enter_solution_creation()
		else:
			_exit_solution_creation()
		
		update_submitted_solution_count()

var in_sandbox: bool = false

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
	submitted_diagrams.remove_at(index)
	
	update_view_submission_button()

func check_submission(submission: DrawingMatrix) -> bool:
	for child in $MovingContainer/SubmitFeedback/MovingContainer/PanelContainer/VBoxContainer.get_children():
		child.hide()
	
	if Diagram.get_degree() != current_problem.degree:
		IncorrectOrder.show()
		return false

	if is_submission_duplicate(submission):
		DiagramDuplicate.show()
		return false
	
	if !current_problem.is_submission_solution(submission):
		DiagramNotSolution.show()
		return false
	
	DiagramSubmitted.show()
	return true

func update_view_submission_button() -> void:
	$MovingContainer/VBoxContainer/Tab/HBoxContainer/ViewSubmissions.disabled = submitted_diagrams.size() == 0

func update_submitted_solution_count() -> void:
	SubmitButton.text = str(submitted_diagrams.size())
	
	if !in_solution_creation:
		SubmitButton.text += "/" + str(current_problem.solution_count)

func submit_diagram() -> void:
	var submission: DrawingMatrix = Diagram.generate_drawing_matrix_from_diagram()
	var submission_valid: bool = check_submission(submission)
	SubmissionFeedback.pull_out()
	if !submission_valid:
		return
	
	submitted_diagrams.push_back(submission)
	SubmittedDiagramViewer.store_diagram(submission)
	
	update_submitted_solution_count()
	update_view_submission_button()
	
	NextProblem.disabled = !in_sandbox and submitted_diagrams.size() < current_problem.solution_count

func generate_solution() -> ConnectionMatrix:
	return(SolutionGeneration.generate_diagrams(
		current_problem.state_interactions[StateLine.StateType.Initial], current_problem.state_interactions[StateLine.StateType.Final],
		1, 10, SolutionGeneration.generate_useable_interactions_from_particles(current_problem.allowed_particles),
		SolutionGeneration.Find.One
	))[0]

func is_submission_duplicate(submission: DrawingMatrix) -> bool:
	var reduced_submission: ConnectionMatrix = submission.reduce_to_connection_matrix()
	
	return submitted_diagrams.any(
		func(submitted_diagram: DrawingMatrix):
			return submitted_diagram.reduce_to_connection_matrix().is_duplicate(reduced_submission)
	)

func toggle_diagram_viewer() -> void:
	SubmittedDiagramViewer.visible = !SubmittedDiagramViewer.visible
	SubmittedDiagramViewer.position = diagram_viewer_offset + position

func _on_view_submissions_pressed() -> void:
	toggle_diagram_viewer()

func load_problem(problem: Problem) -> void:
	current_problem = problem
	
	submitted_diagrams.clear()
	Equation.load_problem(problem)
	
	update_degree_label()
	update_submitted_solution_count()
	
	NextProblem.disabled = !in_sandbox

func set_prev_problem_disabled(disable: bool) -> void:
	PrevProblem.disabled = disable

func set_next_problem_disabled(disable: bool) -> void:
	NextProblem.disabled = disable
	
func _on_solution_pressed() -> void:
	EVENTBUS.draw_diagram_raw(generate_solution())

func _on_rewind_pressed() -> void:
	prev_problem_pressed.emit()

func _on_next_problem_pressed() -> void:
	next_problem_pressed.emit()

func _enter_solution_creation() -> void:
	NextProblem.hide()

func _exit_solution_creation() -> void:
	NextProblem.show()

func _enter_sandbox() -> void:
	in_sandbox = true

func _exit_sandbox() -> void:
	in_sandbox = false

func toggle_finish_icon(toggle: bool) -> void:
	if toggle:
		NextProblem.icon = load("res://Textures/Buttons/icons/finish.png")
	else:
		NextProblem.icon = load("res://Textures/Buttons/icons/next.png")

