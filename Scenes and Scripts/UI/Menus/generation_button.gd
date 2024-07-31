extends PullOutTab

var Initial: StateLine
var Final: StateLine
var Generation: Node
var GeneratedDiagramViewer: MiniDiagramViewer

@export var InitialState : Array
@export var FinalState : Array
@export var EM_check : CheckButton
@export var strong_check: CheckButton
@export var weak_check: CheckButton
@export var electroweak_check: CheckButton
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

@onready var feedback_containers: Array[HBoxContainer] = [NoStatesToSave, StatesSaved, NoDiagramsFound, GenerationCompleted]

enum {INVALID}

@onready var Feedback: PullOutTab = $MovingContainer/SubmitFeedback

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
	
	can_generate = !(InitialState == [] and FinalState == [])
	
	self.can_generate = can_generate

func init(diagram: DiagramBase, generation: Node, generated_diagram_viewer: MiniDiagramViewer) -> void:
	Initial = diagram.StateLines[StateLine.State.Initial]
	Final = diagram.StateLines[StateLine.State.Final]
	Generation = generation
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
	for state_interaction:Array in state_interactions:
		particles += state_interaction
	
	if ParticleData.Particle.photon in particles:
		EM_check.button_pressed = true
	if ParticleData.Particle.gluon in particles:
		strong_check.button_pressed = true
	if ParticleData.Particle.W in particles or ParticleData.Particle.anti_W in particles:
		weak_check.button_pressed = true
	if ParticleData.Particle.H in particles or ParticleData.Particle.Z in particles:
		set_electroweak_check(true)

func _diagram_deleted(_index: int) -> void:
	update_view_button()

func _on_electroweak_toggled(button_pressed: bool) -> void:
	set_electroweak_check(button_pressed)

func electroweak_type_button_pressed(button_pressed: bool) -> void:
	set_electroweak_check(EM_check.button_pressed and weak_check.button_pressed)

func set_electroweak_check(new_value: bool) -> void:
	if electroweak_check.button_pressed != new_value:
		electroweak_check.button_pressed = new_value
	
	if new_value:
		EM_check.button_pressed = true
		weak_check.button_pressed = true

func generate(checks: Array[bool]) -> void:
	var generated_diagrams: Array[ConnectionMatrix] = (
		Generation.generate_diagrams(
			InitialState, FinalState, min_degree, max_degree, Generation.get_usable_interactions(checks)
		)
	)
	
	if generated_diagrams == [null]:
		NoDiagramsFound.show()
	else:
		GenerationCompleted.show()
		GeneratedDiagramViewer.store_diagrams(
			generated_diagrams
		)
	
	show_feedback()
	update_view_button()

func _on_em_toggled(button_pressed: bool) -> void:
	electroweak_type_button_pressed(button_pressed)

func _on_generate_pressed() -> void:
	if !can_generate: return
	
	var checks: Array[bool] = [
		EM_check.button_pressed,
		strong_check.button_pressed,
		weak_check.button_pressed,
		electroweak_check.button_pressed
	]
	
	generate(checks)

func show_feedback() -> void:
	Feedback.pull_out()

func _on_save_pressed() -> void:
	InitialState = Initial.get_state_interactions()
	FinalState = Final.get_state_interactions()
	
	if InitialState.size() == 0 and FinalState.size() == 0:
		self.can_generate = false
		NoStatesToSave.show()
	else:
		self.can_generate = true
		StatesSaved.show()
		set_checks(InitialState + FinalState)
		
		for state:StateLine.State in StateLine.STATES:
			Equation.load_state_symbols(state, [InitialState, FinalState][state])
		
	show_feedback()

func toggle_diagram_viewer() -> void:
	GeneratedDiagramViewer.toggle_visible()
	GeneratedDiagramViewer.position = get_viewport_rect().size / 2

func _on_view_pressed() -> void:
	toggle_diagram_viewer()

func _on_electromagnetic_toggled(button_pressed: bool) -> void:
	if button_pressed:
		return
	
	if weak_check.button_pressed:
		return
	
	electroweak_check.button_pressed = false
	
func _on_weak_toggled(button_pressed: bool) -> void:
	if button_pressed:
		return
	
	if EM_check.button_pressed:
		return
	
	electroweak_check.button_pressed = false

func _on_electro_weak_toggled(button_pressed: bool) -> void:
	if !button_pressed:
		return
	
	EM_check.button_pressed = true
	weak_check.button_pressed = true

func _on_min_degree_value_changed(value: float) -> void:
	MaxDegree.min_value = value

func _on_max_degree_value_changed(value: float) -> void:
	MinDegree.max_value = value

func _on_submit_feedback_push_in_finished() -> void:
	for feedback_container in feedback_containers:
		feedback_container.hide()
