extends PullOutTab

var Initial: StateLine
var Final: StateLine
var Generation: Node
var GeneratedDiagramViewer: MiniDiagramViewer

@onready var DegreeRange = $MovingContainer/PanelContainer/VBoxContainer/OptionsContainer/DegreeSlider/VBoxContainer/RangeSlider
@onready var EM_check := $MovingContainer/PanelContainer/VBoxContainer/OptionsContainer/GridContainer/em
@onready var strong_check := $MovingContainer/PanelContainer/VBoxContainer/OptionsContainer/GridContainer/strong
@onready var weak_check := $MovingContainer/PanelContainer/VBoxContainer/OptionsContainer/GridContainer/weak
@onready var electroweak_check := $MovingContainer/PanelContainer/VBoxContainer/OptionsContainer/GridContainer/electroweak
@onready var OptionsContainer = $MovingContainer/PanelContainer/VBoxContainer/OptionsContainer
@onready var GenerateButton := $MovingContainer/PanelContainer/VBoxContainer/HBoxContainer/Generate

@export var InitialState : Array
@export var FinalState : Array
@export var min_degree : int = -1
@export var max_degree : int = -1
@export var generated_diagram_viewer_offset : Vector2 = Vector2.ZERO

enum {INVALID}

var can_generate : bool = false : set = _set_can_generate

func _ready():
	super._ready()
	
	can_generate = !(InitialState == [] and FinalState == [])
	
	self.can_generate = can_generate
	
	if min_degree != INVALID and max_degree != INVALID:
		DegreeRange.minValue = min_degree
		DegreeRange.maxValue = max_degree

func init(diagram: DiagramBase, generation: Node, generated_diagram_viewer: MiniDiagramViewer) -> void:
	Initial = diagram.StateLines[StateLine.StateType.Initial]
	Final = diagram.StateLines[StateLine.StateType.Final]
	Generation = generation
	GeneratedDiagramViewer = generated_diagram_viewer
	
	GeneratedDiagramViewer.closed.connect(toggle_diagram_viewer)
	GeneratedDiagramViewer.diagram_deleted.connect(_diagram_deleted)

func _set_can_generate(new_value: bool) -> void:
	can_generate = new_value
	GenerateButton.disabled = !new_value

func update_view_button() -> void:
	$MovingContainer/PanelContainer/VBoxContainer/HBoxContainer/View.disabled = GeneratedDiagramViewer.get_diagram_count() == 0

func get_state_interactions(state_line: StateLine) -> Array:
	var state_interactions : Array = []
	
	for particle in state_line.connected_lone_particles:
		state_interactions.append([particle])
	
	for hadron in state_line.hadrons:
		state_interactions.append(hadron.quarks)
		
	return state_interactions

func set_checks(state_interactions : Array) -> void:
	var particles : Array = []
	for state_interaction in state_interactions:
		particles += state_interaction
	
	if GLOBALS.Particle.photon in particles:
		EM_check.button_pressed = true
	if GLOBALS.Particle.gluon in particles:
		strong_check.button_pressed = true
	if GLOBALS.Particle.W in particles or GLOBALS.Particle.anti_W in particles:
		weak_check.button_pressed = true
	if GLOBALS.Particle.H in particles or GLOBALS.Particle.Z in particles:
		set_electroweak_check(true)

func _diagram_deleted(_index: int) -> void:
	update_view_button()

func _on_options_pressed() -> void:
	OptionsContainer.visible = !OptionsContainer.visible

func _on_electroweak_toggled(button_pressed: bool):
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
	GeneratedDiagramViewer.create_diagrams(
		Generation.generate_diagrams(
			InitialState, FinalState, DegreeRange.minValue, DegreeRange.maxValue, Generation.get_usable_interactions(checks)
		)
	)
	
	update_view_button()

func _on_em_toggled(button_pressed: bool) -> void:
	electroweak_type_button_pressed(button_pressed)

func _on_weak_toggled(button_pressed: bool) -> void:
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

func _on_save_pressed() -> void:
	InitialState = get_state_interactions(Initial)
	FinalState = get_state_interactions(Final)
	
	if InitialState.size() == 0 and FinalState.size() == 0:
		self.can_generate = false
	else:
		self.can_generate = true
		set_checks(InitialState + FinalState)

func toggle_diagram_viewer() -> void:
	GeneratedDiagramViewer.visible = !GeneratedDiagramViewer.visible
	GeneratedDiagramViewer.position = generated_diagram_viewer_offset + position

func _on_view_pressed() -> void:
	toggle_diagram_viewer()
