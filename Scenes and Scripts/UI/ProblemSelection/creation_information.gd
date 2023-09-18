extends Control

signal submit_problem

var step: int = 0: set = _set_step

var active_modes: Array[BaseMode.Mode] = [BaseMode.Mode.ProblemCreation]

@onready var problem_text: Label = $"PanelContainer/VBoxContainer/VBoxContainer/ProblemCount"
@onready var title: Label = $PanelContainer/VBoxContainer/VBoxContainer/Title
@onready var body: Label = $PanelContainer/VBoxContainer/VBoxContainer/Body

@onready var Prev: PanelButton = $PanelContainer/VBoxContainer/Buttons/PrevStep
@onready var Next: PanelButton = $PanelContainer/VBoxContainer/Buttons/NextStep
@onready var Submit: PanelButton = $PanelContainer/VBoxContainer/Buttons/Submit

var Diagram: MainDiagram
var ModeManager: Node
var problem: Problem

func _process(_delta: float) -> void:
	if ModeManager.mode != BaseMode.Mode.ProblemCreation:
		return
	
	var quantum_numbers_match: bool = Diagram.are_quantum_numbers_matching
	
	Next.disabled = !quantum_numbers_match

func _set_step(new_value: int) -> void:
	step = clamp(new_value, 0, active_modes.size()-1)
	
	Prev.visible = step != 0
	Next.visible = step != active_modes.size()-1
	Submit.visible = step == active_modes.size()-1

func init(_problem: Problem, diagram: MainDiagram, mode_manager: Node) -> void:
	Diagram = diagram
	ModeManager = mode_manager
	problem = _problem
	
	if _problem.limited_particles:
		active_modes.push_front(BaseMode.Mode.ParticleSelection)

	if _problem.custom_solutions:
		active_modes.push_back(BaseMode.Mode.SolutionCreation)

	self.step = 0

func change_mode(mode: BaseMode.Mode) -> void:
	if mode == BaseMode.Mode.Sandbox:
		return
	
	match mode:
		BaseMode.Mode.ParticleSelection:
			particle_selection()
		BaseMode.Mode.ProblemCreation:
			problem_creation()
		BaseMode.Mode.SolutionCreation:
			solution_creation()
			
func particle_selection() -> void:
	title.text = str(step+1) + ". Particle Selection"
	body.text = "
		- Deselect/Select available particles.\n
		- Deselected particles will not be able to be used.
	"

func problem_creation() -> void:
	title.text = str(step+1) + ". Problem Creation"
	body.text = "
		- Draw the problem.\n
		- Only the drawn initial and final states matter.
	"

func solution_creation() -> void:
	title.text = str(step+1) + ". Solution Creation"
	body.text = "
		- Draw solutions to the problem.\n
		- Submit using puzzle tab.
	"

func _on_submit_pressed() -> void:
	submit_problem.emit()
