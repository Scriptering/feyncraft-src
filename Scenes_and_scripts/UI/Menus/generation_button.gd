extends PullOutTab

const MAX_DEGREE: int = 10

var Initial: StateLine
var Final: StateLine
var GeneratedDiagramViewer: MiniDiagramViewer

@export_group("Children")
@export var InitialState : Array
@export var FinalState : Array
@export var SaveStates: PanelButton
@export var Generate: PanelButton
@export var ViewDiagrams: PanelButton
@export var MinDegree: SpinBox
@export var MaxDegree: SpinBox
@export var Equation: PanelContainer
@export var NoStatesToSave: HBoxContainer
@export var StatesSaved: HBoxContainer
@export var NoDiagramsFound: HBoxContainer
@export var GenerationCompleted: HBoxContainer
@export var LoadTimeWarning: PullOutTab

@onready var feedback_containers: Array[HBoxContainer] = [NoStatesToSave, StatesSaved, NoDiagramsFound, GenerationCompleted]

enum {INVALID}

@onready var Feedback: PullOutTab = $MovingContainer/SubmitFeedback

var prev_self_energy: bool = false

var can_generate : bool = false : set = _set_can_generate
var min_degree: int:
	set(_new_value):
		return
	get:
		return int(MinDegree.value)
var max_degree: int:
	set(_new_value):
		return
	get:
		return int(MaxDegree.value)

func _ready() -> void:
	super._ready()
	
	MinDegree.max_value = MAX_DEGREE
	MaxDegree.max_value = MAX_DEGREE
	can_generate = !(InitialState == [] and FinalState == [])
	
	self.can_generate = can_generate

func init(diagram: DiagramBase, generated_diagram_viewer: MiniDiagramViewer) -> void:
	Initial = diagram.StateLines[StateLine.State.Initial]
	Final = diagram.StateLines[StateLine.State.Final]
	GeneratedDiagramViewer = generated_diagram_viewer
	
	GeneratedDiagramViewer.closed.connect(toggle_diagram_viewer)
	GeneratedDiagramViewer.diagram_deleted.connect(_diagram_deleted)

func _set_can_generate(new_value: bool) -> void:
	can_generate = new_value
	Generate.disabled = !new_value

func update_view_button() -> void:
	ViewDiagrams.disabled = GeneratedDiagramViewer.get_diagram_count() == 0

func set_checks(state_interactions : Array) -> void:
	var particles : Array = []
	var has_hadron: bool = false
	for state_interaction:Array in state_interactions:
		particles += state_interaction
		
		if state_interaction.size() > 1:
			has_hadron = true
	
	if has_hadron:
		%SelfEnergy.button_pressed = true
		%SelfEnergy.disabled = true
	else:
		%SelfEnergy.button_pressed = prev_self_energy
		%SelfEnergy.disabled = false
	
	if ParticleData.Particle.photon in particles:
		%electromagnetic_check.button_pressed = true
	if ParticleData.Particle.gluon in particles:
		%strong_check.button_pressed = true
	if ParticleData.Particle.W in particles or ParticleData.Particle.anti_W in particles:
		%weak_check.button_pressed = true
	if ParticleData.Particle.H in particles or ParticleData.Particle.Z in particles:
		%electroweak_check.button_pressed = true

func _diagram_deleted(_index: int) -> void:
	update_view_button()

func generate(checks: Array[bool]) -> void:
	var useable_particles: Array[ParticleData.Particle] = ProblemGeneration.get_useable_particles_from_interaction_checks(checks)
	
	var generated_diagrams: Array[ConnectionMatrix] = (
		SolutionGeneration.generate_diagrams(
			InitialState,
			FinalState,
			min_degree,
			max_degree,
			useable_particles,
			int(%Find.value),
			%Tadpoles.button_pressed,
			%SelfEnergy.button_pressed
		)
	)
	
	if generated_diagrams == [null]:
		GeneratedDiagramViewer.clear()
		NoDiagramsFound.show()
	else:
		GenerationCompleted.show()
		GeneratedDiagramViewer.store_diagrams(
			generated_diagrams
		)
	
	show_feedback()
	update_view_button()

func _on_generate_pressed() -> void:
	if !can_generate: return
	
	var checks: Array[bool] = [
		%electromagnetic_check.button_pressed,
		%strong_check.button_pressed,
		%weak_check.button_pressed,
		%electroweak_check.button_pressed
	]
	
	generate(checks)

func show_feedback() -> void:
	Feedback.pull_out()

func _on_save_pressed() -> void:
	var initial_state: Array = Initial.get_state_interactions()
	var final_state: Array = Final.get_state_interactions()
	
	if initial_state.is_empty() and final_state.is_empty():
		NoStatesToSave.show()
		show_feedback()
		return

	InitialState = initial_state
	FinalState = final_state

	self.can_generate = true
	StatesSaved.show()
	set_checks(InitialState + FinalState)
	
	for state:StateLine.State in StateLine.STATES:
		Equation.load_state_symbols(state, [InitialState, FinalState][state])
		
	show_feedback()

func toggle_diagram_viewer() -> void:
	GeneratedDiagramViewer.toggle_visible()
	GeneratedDiagramViewer.position = Vector2.ZERO

func _on_view_pressed() -> void:
	toggle_diagram_viewer()

func _on_electromagnetic_toggled(button_pressed: bool) -> void:
	if !button_pressed:
		%electroweak_check.button_pressed = false
	
func _on_weak_toggled(button_pressed: bool) -> void:
	if !button_pressed:
		%electroweak_check.button_pressed = false

func _on_electro_weak_toggled(button_pressed: bool) -> void:
	if button_pressed:
		%electromagnetic_check.button_pressed = true
		%weak_check.button_pressed = true

func update_load_time_warning() -> void:
	match int(%Find.value):
		SolutionGeneration.Find.One:
			LoadTimeWarning.push_in()
		SolutionGeneration.Find.LowestOrder:
			show_warning(min_degree)
		SolutionGeneration.Find.All:
			show_warning(max_degree)

func show_warning(degree: int) -> void:
	if degree <= 5:
		LoadTimeWarning.push_in()
		return
	
	if degree <= 7:
		%WarningLabel.text = "Warning: May take a while"
	elif degree <= 9:
		%WarningLabel.text = "Warning: Don't do this"
	elif degree == 10:
		%WarningLabel.text = "Don't say I didn't warn you"
	
	LoadTimeWarning.pull_out()

func _on_min_degree_value_changed(value: float) -> void:
	MaxDegree.value = max(value, MaxDegree.value)
	update_load_time_warning()

func _on_max_degree_value_changed(value: float) -> void:
	MinDegree.value = min(value, MinDegree.value)
	update_load_time_warning()

func _on_submit_feedback_push_in_finished() -> void:
	for feedback_container in feedback_containers:
		feedback_container.hide()

func _on_find_value_changed(_value: float) -> void:
	update_load_time_warning()
	
func _on_self_energy_pressed() -> void:
	prev_self_energy = %SelfEnergy.button_pressed
