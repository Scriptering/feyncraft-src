class_name Interaction
extends GrabbableNode2D

signal clicked_on
signal request_deletion
signal show_information_box

@onready var Ball = get_node("Ball")
@onready var Level := get_node("/root/World")
@onready var StateManager = Level.get_node('state_manager')

@onready var Dot = get_node("Dot")
@onready var InfoNumberLabel = get_node('InfoNumberLabel')
@onready var interaction_matrix: ConnectionMatrix = Level.interaction_matrix

@export var information_box_offset := Vector2(0, 0)

static var used_information_numbers: Array[int] = []

enum {HIGHLIGHT, NORMAL}
enum Side {Before = -1, After = +1}
const INTERACTION_SIZE_MINIMUM := 3
const INFORMATION_ID_MAXIMUM := 99
const MAXIMUM_DIMENSIONALITY : float = 4

var Diagram: MainDiagram
var Initial: StateLine
var Final: StateLine
var Crosshair: Node

var InformationBox := preload("res://Scenes and Scripts/UI/Info/interaction_information.tscn")
var information_id: int

var id : int
var connected_lines: Array[ParticleLine] = []
var old_connected_lines: Array[ParticleLine] = []
var connected_particles: Array[GLOBALS.Particle] : get = _get_connected_particles
var connected_base_particles: Array[GLOBALS.Particle] : get = _get_connected_base_particles
var connected_colour_lines: Array[ParticleLine] : get = _get_connected_colour_lines
var connected_shade_lines: Array[ParticleLine] : get = _get_connected_shade_lines
var dimensionality: float : get = _get_dimensionality

var information_visible: bool = false
var information_box

var valid := true: set = _set_valid
var valid_colourless := true: set = _set_valid_colourless
var hovering := false : set = _set_hovering

func _ready():
	super._ready()
	
	show_information_box.connect(EVENTBUS.add_floating_menu)
	request_deletion.connect(Diagram.delete_interaction)
	
	id = interaction_matrix.calculate_new_interaction_id()
	interaction_matrix.add_interaction()
	
	for line in Diagram.get_particle_lines():
		if position in line.points and !line in connected_lines:
			connected_lines.append(line)

	Ball.frame = NORMAL
	
	update_interaction()

	Diagram.check_split_lines()
	Diagram.update_statelines()

func init(diagram: MainDiagram) -> void:
	Diagram = diagram
	Initial = diagram.StateLines[StateLine.StateType.Initial]
	Final = diagram.StateLines[StateLine.StateType.Final]
	Crosshair = diagram.Crosshair

func _process(_delta: float) -> void:
	if old_connected_lines != connected_lines:
		update_interaction()
		old_connected_lines = connected_lines.duplicate(true)
	if connected_lines.size() == 0 and not grabbed and StateManager.state != BaseState.State.Drawing:
		queue_free()

func _grab_area_hovered_changed(new_value: bool):
	self.hovering = new_value
	grab_area_hovered = new_value

func _input(event: InputEvent) -> void:
	super._input(event)
	if Input.is_action_just_pressed("click") and hovering:
		emit_signal("clicked_on", self)

func _set_hovering(new_value: bool):
	if new_value:
		Ball.frame = HIGHLIGHT
	else:
		Ball.frame = NORMAL

	hovering = new_value

func _set_valid(new_valid: bool) -> void:
	valid = new_valid
	update_valid_visual()

func _set_valid_colourless(new_valid_colourless: bool) -> void:
	valid_colourless = new_valid_colourless
	update_valid_visual()

func crosshair_moved(_current_position: Vector2, _old_position: Vector2):
	if grabbed:
		update_interaction()

func update_valid_visual() -> void:
	if valid and valid_colourless:
		Ball.animation = 'valid'
	else:
		Ball.animation = 'invalid'

func update_dot_visual() -> void:
	if !grabbed:
		if connected_lines.size() >= INTERACTION_SIZE_MINIMUM:
			Dot.visible = true
		else:
			Dot.visible = false
	
	if get_on_state_line() != StateLine.StateType.None:
		Dot.frame = 1
		Dot.visible = true
	else:
		Dot.frame = 0

func get_on_state_line() -> StateLine.StateType:
	if position.x == Initial.position.x and position.x == Final.position.x:
		return StateLine.StateType.Both
		
	if position.x == Initial.position.x:
		return StateLine.StateType.Initial
		
	if position.x == Final.position.x:
		return StateLine.StateType.Final
		
	return StateLine.StateType.None

func update_interaction() -> void:
	if grabbed:
		move_interaction()
	elif should_request_deletion():
		emit_signal("request_deletion", self)
		return
	update_dot_visual()
	update_ball_hovering()
	if connected_lines.size() < INTERACTION_SIZE_MINIMUM and information_visible:
		close_information_box()
	
	if information_visible:
		information_box.build_table()
	
	set_shader_parameters()
	
	valid = connected_lines.size() < INTERACTION_SIZE_MINIMUM or validate()

func update_ball_hovering() -> void:
	self.hovering = self.hovering

func has_colour() -> bool:
	for line in connected_lines:
		if line.has_colour:
			return true
	return false
	
func has_shade() -> bool:
	for line in connected_lines:
		if line.has_shade:
			return true
	return false

func _get_connected_colour_lines() -> Array[ParticleLine]:
	var connected_coloured_lines: Array[ParticleLine] = []
	for line in connected_lines:
		if line.has_colour:
			connected_coloured_lines.append(line)
	return connected_coloured_lines

func _get_connected_shade_lines() -> Array[ParticleLine]:
	var connected_shaded_lines: Array[ParticleLine] = []
	for line in connected_lines:
		if line.has_shade:
			connected_shaded_lines.append(line)
	return connected_shaded_lines

func _get_connected_particles() -> Array[GLOBALS.Particle]:
	connected_particles.clear()
	for line in connected_lines:
		connected_particles.append(line.particle)
	return connected_particles

func _get_connected_base_particles() -> Array[GLOBALS.Particle]:
	connected_base_particles.clear()
	for line in connected_lines:
		connected_base_particles.append(line.base_particle)
	return connected_base_particles

func should_request_deletion() -> bool:
	if connected_lines.size() == 0:
		return true
	return false

func move_interaction() -> void:
	position = Crosshair.position

func has_particle_connected(particle: GLOBALS.Particle):
	return particle in self.connected_particles

func has_base_particle_connected(base_particle: GLOBALS.Particle):
	return base_particle in self.connected_base_particles

func validate() -> bool:
	if !is_dimensionality_valid():
		return false

	if has_particle_connected(GLOBALS.Particle.photon) and has_neutral_photon():
		return false
	
	if has_particle_connected(GLOBALS.Particle.gluon) and has_colourless_gluon():
		return false
	
	if get_invalid_quantum_numbers().size() > 0:
		return false
	
	return true

func get_invalid_quantum_numbers() -> Array[GLOBALS.QuantumNumber]:
	var is_weak: bool = has_base_particle_connected(GLOBALS.Particle.W)
	var invalid_quantum_numbers: Array[GLOBALS.QuantumNumber] = []
	var before_quantum_sum : Array[float] = get_side_quantum_sum(Side.Before)
	var after_quantum_sum : Array[float] = get_side_quantum_sum(Side.After)
	var interaction_in_list := is_interaction_in_list()
	
	for quantum_number in GLOBALS.QuantumNumber.values():
		var quantum_numbers_equal := is_equal_approx(before_quantum_sum[quantum_number], after_quantum_sum[quantum_number])
		
		if !is_weak:
			if !quantum_numbers_equal:
				invalid_quantum_numbers.append(quantum_number)
		
		elif (
			(quantum_number == GLOBALS.QuantumNumber.charge or
			quantum_number == GLOBALS.QuantumNumber.lepton or
			quantum_number == GLOBALS.QuantumNumber.electron or
			quantum_number == GLOBALS.QuantumNumber.muon or
			quantum_number == GLOBALS.QuantumNumber.tau or
			quantum_number == GLOBALS.QuantumNumber.quark) and
			!quantum_numbers_equal
		):
			invalid_quantum_numbers.append(quantum_number)
			
		elif !interaction_in_list:
			invalid_quantum_numbers.append(quantum_number)
	
	return invalid_quantum_numbers

func get_side_connected_lines(side: Interaction.Side) -> Array[ParticleLine]:
	var side_connected_lines : Array[ParticleLine] = []
	
	for line in connected_lines:
		var unconnected_point := line.get_unconnected_point(self)
		var unconnected_vector : Vector2 = (
			line.points[unconnected_point] - position
		)
		if side * unconnected_vector.x > 0:
			side_connected_lines.append(line)
		elif unconnected_vector.x == 0 and is_vertical_line_on_side(unconnected_point, side):
			side_connected_lines.append(line)

	return side_connected_lines

func is_vertical_line_on_side(unconnected_point: ParticleLine.Point, side: Interaction.Side) -> bool:
	if side == Side.Before:
		return unconnected_point == ParticleLine.Point.Start
	
	return unconnected_point == ParticleLine.Point.End

func get_side_quantum_sum(side: Interaction.Side) -> Array[float]:
	var quantum_sum : Array[float] = []
	var side_connected_lines := get_side_connected_lines(side)
	
	for quantum_number in GLOBALS.QuantumNumber.values():
		var sum: float = 0
		for line in side_connected_lines:
			sum += line.quantum_numbers[quantum_number]
		quantum_sum.append(sum)

	return quantum_sum

func is_dimensionality_valid() -> bool:
	return self.dimensionality <= MAXIMUM_DIMENSIONALITY

func _get_dimensionality() -> float:
	dimensionality = 0
	for line in connected_lines:
		dimensionality += line.dimensionality
	return dimensionality

func has_neutral_photon() -> bool:
	for line in connected_lines:
		if line.quantum_numbers[GLOBALS.QuantumNumber.charge] != 0:
			return false
	
	return is_interaction_in_list()

func has_colourless_gluon() -> bool:
	for line in connected_lines:
		if !line.has_colour:
			return true
	return false

func is_interaction_in_list() -> bool:
	var sorted_connected_base_particles := self.connected_base_particles.duplicate(true)
	sorted_connected_base_particles.sort()
	
	for interaction_type in GLOBALS.INTERACTIONS:
		if sorted_connected_base_particles in interaction_type:
			return true
	
	return false

func is_hovered() -> bool:
	return hovering

func pick_up() -> void:
	super.pick_up()
	
	for line in connected_lines:
		line.pick_up(line.get_point_at_position(position))

func get_new_information_id() -> int:
	for i in range(1, INFORMATION_ID_MAXIMUM):
		if !i in used_information_numbers:
			return i
	return -1

func open_information_box() -> void:
	information_id = get_new_information_id()
	used_information_numbers.append(information_id)
	
	information_box = InformationBox.instantiate()
	information_box.ConnectedInteraction = self
	information_box.ID = information_id
	information_box.position = Diagram.position + position + information_box_offset
	emit_signal("show_information_box", information_box)
	
	InfoNumberLabel.text = str(information_id)
	InfoNumberLabel.show()
	information_visible = true

func close_information_box() -> void:
	used_information_numbers.erase(information_id)
	InfoNumberLabel.hide()
	information_box.queue_free()
	information_visible = false

func _on_information_button_pressed():
	if (
		(StateManager.state == BaseState.State.Idle or
		(StateManager.state == BaseState.State.Drawing and
		!StateManager.states[BaseState.State.Drawing].drawing)) and
		connected_lines.size() >= INTERACTION_SIZE_MINIMUM
	):
		if information_visible:
			close_information_box()
		else:
			open_information_box()

func deconstructor() -> void:
	if information_visible:
		close_information_box()
	Diagram.update_statelines()

func _on_tree_exiting():
	deconstructor()
	
func drop() -> void:
	super.drop()
	
	update_dot_visual()
	Diagram.update_statelines()

func get_interaction_index() -> Array[int]:
	var sorted_connected_base_particles := self.connected_base_particles.duplicate(true)
	sorted_connected_base_particles.sort()
	
	for i in range(GLOBALS.INTERACTIONS.size()):
		for j in range(GLOBALS.INTERACTIONS[i].size()):
			if sorted_connected_base_particles == GLOBALS.INTERACTIONS[i][j]:
				return [i, j]
	
	return []

func get_interaction_strength() -> float:
	var interaction_index := get_interaction_index()
	if interaction_index == []:
		return -1
	return GLOBALS.INTERACTION_STRENGTHS[interaction_index[0]][interaction_index[1]][0]

func calculate_interaction_strength_alpha(interaction_strength:float = get_interaction_strength()) -> float:
	var minimum_log_strength := log(GLOBALS.MINIMUM_INTERACTION_STRENGTH)
	var maximum_log_strength := log(GLOBALS.MAXIMUM_INTERACTION_STRENGTH)
	
	if interaction_strength == -1:
		return 1.0
	
	var proportional_strength : float = (
		(log(interaction_strength) - minimum_log_strength) /
		(maximum_log_strength - minimum_log_strength) *
		(1.0 - GLOBALS.MINIMUM_INTERACTION_STRENGTH_ALPHA) + GLOBALS.MINIMUM_INTERACTION_STRENGTH_ALPHA
	)
	
	return proportional_strength

func set_shader_parameters() -> void:
	var interaction_strength_alpha = calculate_interaction_strength_alpha()
	material.set_shader_parameter("interaction_strength_alpha", interaction_strength_alpha)
	
	set_connected_line_shader_parameters(interaction_strength_alpha)

func set_connected_line_shader_parameters(interaction_strength_alpha: float) -> void:
	for line in connected_lines:
		line.set_point_interaction_strength_alpha(line.get_point_at_position(position), interaction_strength_alpha)
