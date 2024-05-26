extends Node2D
class_name ParticleLine

signal request_deletion

@onready var Text = get_node("text")
@onready var SpareText = get_node("spareText")
@onready var Arrow = $arrow
@onready var ClickAreaShape = $clickArea/CollisionShape2D
@onready var LineMiddle = $line_middle
@onready var LineJointStart = $line_joint_start
@onready var LineJointEnd = $line_joint_end

@export var line_joint_start_length: float = 3.5
@export var line_joint_end_length: float = 1
@export var gluon_loop_length: int = 11
@export var click_area_width: float = 7
@export var text_gap: float
@export var gluon_line_width: float = 18
@export var particle_line_width: float = 12
@export var photon_line_width: float = 12

enum Anti {anti = -1, noanti = +1}
enum Point {Start = 0, End = 1, Invalid = -1}
enum PointsConnected {None, Left, Right, Both}
enum Shade {Bright, Dark}

var Diagram: MainDiagram
var Initial: StateLine
var Final: StateLine
var Crosshair: Node

var points := PackedVector2Array([Vector2.LEFT, Vector2.LEFT]) : set = _set_points
var prev_points := PackedVector2Array([[0, 0], [0, 0]])
var line_vector : Vector2 = Vector2.ZERO:
	get: return points[Point.End] - points[Point.Start]

var base_particle := ParticleData.Particle.none
var particle := ParticleData.Particle.none : get = _get_particle
var particle_name : String : get = _get_particle_name

var connected_interactions : Array[Interaction] : get = _get_connected_interactions

var anti := 1 : set = _set_anti
var is_placed := false
var on_state_line := StateLine
var quantum_numbers: Array : get = _get_quantum_numbers
var dimensionality: float
var being_deleted : bool = false

var has_colour := false
var has_shade := false

var hovering: bool = false

var left_point: Vector2 = Vector2.LEFT
var right_point: Vector2 = Vector2.LEFT

var moving_point : Point = Point.End

static var texture_dict: Array = [
'Electroweak', 
'loop',
'Electroweak',
'higgs_dash',
'Electroweak',
'Particle',
'Particle',
'Particle',
'Particle',
'Particle',
'Particle',
'Particle',
'Particle',
'Particle',
'Particle',
'Particle',
'Particle',
'Particle',
'Particle',
'Particle',
'Particle']

var line_texture
var show_labels: bool = true

func _ready() -> void:
	request_deletion.connect(Diagram.recursive_delete_line)
	
	has_colour = base_particle in ParticleData.COLOUR_PARTICLES
	has_shade = base_particle in ParticleData.SHADED_PARTICLES
	quantum_numbers = ParticleData.QUANTUM_NUMBERS[base_particle]
	set_dimensionality()
	set_line_width()

	line_texture = load('res://Textures/ParticlesAndLines/Lines/' + texture_dict[base_particle] + '.png')

	set_textures()
	
	if is_placed:
		place()
	
	update_line()
	connect_to_interactions()

func init(diagram: MainDiagram) -> void:
	Diagram = diagram
	Initial = diagram.StateLines[StateLine.StateType.Initial]
	Final = diagram.StateLines[StateLine.StateType.Final]
	Crosshair = diagram.Crosshair

func _get_particle() -> ParticleData.Particle:
	return (anti * base_particle) as ParticleData.Particle

func _get_quantum_numbers() -> Array:
	var quantum_numbers_temp := []
	for quantum_number in ParticleData.QuantumNumber.values():
		quantum_numbers_temp.append(anti*quantum_numbers[quantum_number])
	return quantum_numbers_temp

func get_quantum_number(quantum_number: ParticleData.QuantumNumber) -> float:
	return anti * ParticleData.QUANTUM_NUMBERS[base_particle][quantum_number]

func _set_anti(new_value: int) -> void:
	anti = new_value

func set_anti() -> void:
	if base_particle in ParticleData.SHADED_PARTICLES:
		if points[Point.Start].x <= points[Point.End].x:
			anti = Anti.noanti
		else:
			anti = Anti.anti
	else:
		anti = Anti.noanti

func _set_points(new_value: PackedVector2Array) -> void:
	points = new_value
	
	if is_inside_tree() and !being_deleted and is_placed:
		connect_to_interactions()
	
func set_textures() -> void:
	LineMiddle.texture = line_texture
	Text.texture = ParticleData.PARTICLE_TEXTURES[self.particle_name]
	SpareText.texture = ParticleData.PARTICLE_TEXTURES[self.particle_name]

func _get_particle_name() -> String:
	return ParticleData.Particle.keys()[ParticleData.Particle.values().find(self.particle)]

func get_side_point(state: StateLine.StateType) -> Vector2:
	if state == StateLine.StateType.Initial:
		return left_point
	return right_point

func set_dimensionality() -> void:
	if base_particle in ParticleData.FERMIONS:
		dimensionality = ParticleData.FERMION_DIMENSIONALITY
	elif base_particle in ParticleData.BOSONS:
		dimensionality = ParticleData.BOSON_DIMENSIONALITY

func connect_to_interactions() -> void:
	for interaction in Diagram.get_interactions():
		if interaction.position in points and !self in interaction.connected_lines:
			interaction.connected_lines.append(self)
		elif !interaction.position in points:
			interaction.connected_lines.erase(self)

func set_left_and_right_points() -> void:
	if points[Point.Start].x <= points[Point.End].x:
		left_point = points[Point.Start]
		right_point = points[Point.End]
	else:
		left_point = points[Point.End]
		right_point = points[Point.Start]

func get_on_state_line() -> StateLine.StateType:
	if left_point.x == Initial.position.x and right_point.x == Final.position.x:
		return StateLine.StateType.Both
		
	if left_point.x == Initial.position.x:
		return StateLine.StateType.Initial
		
	if right_point.x == Final.position.x:
		return StateLine.StateType.Final
		
	return StateLine.StateType.None

func _get_connected_interactions() -> Array[Interaction]:
	connected_interactions.clear()
	for interaction in Diagram.get_interactions():
		if self in interaction.connected_lines:
			connected_interactions.append(interaction)

	return connected_interactions

func get_interaction_at_point(point: Point) -> Interaction:
	var interaction_at_point : Interaction
	for interaction in self.connected_interactions:
		if points[point] == interaction.position:
			interaction_at_point = interaction
	return interaction_at_point

func is_point_connected(point: Vector2) -> bool:
	for interaction in self.connected_interactions:
		if point == interaction.position:
			return true
	return false

func is_position_on_line(test_position: Vector2) -> bool:
	var split_vector: Vector2 = test_position-points[Point.Start]
	
	if test_position in points:
		return false
	
	if !GLOBALS.is_vec_zero_approx(split_vector.normalized() - line_vector.normalized()):
		return false

	if split_vector.length() >= line_vector.length():
		return false
	
	return true

func get_points_connected() -> PointsConnected:
	if is_point_connected(left_point) and is_point_connected(right_point):
		return PointsConnected.Both
	
	if is_point_connected(left_point):
		return PointsConnected.Left
	
	if is_point_connected(right_point):
		return PointsConnected.Right
	
	return PointsConnected.None

func get_point_at_position(test_position: Vector2) -> Point:
	if test_position == points[Point.Start]:
		return Point.Start
	elif test_position == points[Point.End]:
		return Point.End
	return Point.Invalid

func get_connected_point(interaction: Interaction) -> Point:
	return points.find(interaction.position) as Point

func get_unconnected_point(interaction: Interaction) -> Point:
	return (get_connected_point(interaction)+1)%2 as Point

func update_line() -> void:
	if !is_placed:
		points[moving_point] = Crosshair.position

	if points == prev_points:
		move_text()
		set_text_visiblity()
		return

	prev_points = points.duplicate()

	move_line()

	set_left_and_right_points()
	set_anti()

	Arrow.visible = get_arrow_visiblity()
	if Arrow.visible:
		move_arrow()

	move_click_area()
	set_text_texture()


func move_line() -> void:
	pass
	LineJointStart.points[Point.Start] = points[Point.Start]
	LineJointEnd.points[Point.End] = points[Point.End]
	
	LineJointStart.points[Point.End] = points[Point.Start] + line_joint_start_length * self.line_vector.normalized() 
	
	if base_particle == ParticleData.Particle.gluon:
		var number_of_gluon_loops : int = floor((self.line_vector.length() - line_joint_start_length - line_joint_end_length) / gluon_loop_length)
		
		LineJointEnd.points[Point.Start] = (
			LineJointStart.points[Point.End] +
			gluon_loop_length * number_of_gluon_loops * self.line_vector.normalized()
		)
	else:
		LineJointEnd.points[Point.Start] = points[Point.End] - line_joint_end_length * self.line_vector.normalized() 
	
	LineMiddle.points[Point.Start] = LineJointStart.points[Point.End]
	LineMiddle.points[Point.End] = LineJointEnd.points[Point.Start]

func set_line_width() -> void:
	match base_particle:
		ParticleData.Particle.gluon:
			LineMiddle.width = gluon_line_width
			return
		ParticleData.Particle.photon:
			LineMiddle.width = photon_line_width
			return
	
	LineMiddle.width = particle_line_width

func get_arrow_visiblity() -> bool:
	if points[Point.Start] == points[Point.End]:
		return false
	
	if base_particle == ParticleData.Particle.W:
		return false
	
	if base_particle in ParticleData.BOSONS:
		return false
		
	return true

func move_arrow() -> void:
	Arrow.position = points[Point.Start] + self.line_vector / 2
	Arrow.rotation = self.line_vector.angle()

func move_click_area() -> void:
	ClickAreaShape.position = self.line_vector / 2 + points[Point.Start]
	ClickAreaShape.rotation = self.line_vector.angle()
	ClickAreaShape.shape.size.x = self.line_vector.length()

func move_text() -> void:
	match get_on_state_line():
		StateLine.StateType.Both:
			Text.position = left_point + text_gap * Vector2.LEFT
			SpareText.position = right_point + text_gap * Vector2.RIGHT
			return
		StateLine.StateType.Initial:
			Text.position = left_point + text_gap * Vector2.LEFT
			return
		StateLine.StateType.Final:
			Text.position = right_point + text_gap * Vector2.RIGHT
			return
	
	if points[Point.Start] == points[Point.End]:
		Text.position = left_point + text_gap * Vector2.LEFT
		return
	
	match get_points_connected():
		PointsConnected.Left:
			Text.position = right_point + text_gap * Vector2.RIGHT
		PointsConnected.Right:
			Text.position = left_point + text_gap * Vector2.LEFT
	
	Text.position = (
		(right_point - left_point) / 2 + left_point +
		text_gap * self.line_vector.orthogonal().normalized()
	)

func set_text_visiblity() -> void:
	if GLOBALS.in_main_menu:
		Text.hide()
		SpareText.hide()
		return
	
	match get_on_state_line():
		StateLine.StateType.None:
			if !show_labels:
				Text.hide()
				SpareText.hide()
				return
		StateLine.StateType.Both:
			Text.show()
			SpareText.show()
			return
	
	Text.show()
	SpareText.hide()

func set_text_texture() -> void:
	Text.texture = ParticleData.PARTICLE_TEXTURES[self.particle_name]
	SpareText.texture = ParticleData.PARTICLE_TEXTURES[self.particle_name]

	if points[Point.End].x == points[Point.Start].x and base_particle == ParticleData.Particle.W:
		Text.texture = ParticleData.PARTICLE_TEXTURES['W_0']

func place() -> void:
	if !is_placement_valid():
		request_deletion.emit(self)
		return
	is_placed = true
	connect_to_interactions()

func is_placement_valid() -> bool:
	if points[Point.Start] == points[Point.End]:
		return false
	
	if is_line_copy():
		return false
	
	if is_line_overlapping():
		return false
	
	if are_both_points_on_same_state_line():
		return false
	
	return true

func are_both_points_on_same_state_line() -> bool:
	if get_on_state_line() == StateLine.StateType.None:
		return false
	
	return Diagram.get_on_stateline(points[Point.Start]) == Diagram.get_on_stateline(points[Point.End])

func pick_up(point_index_to_pick_up: Point) -> void:
	is_placed = false
	moving_point = point_index_to_pick_up
	
func is_line_copy() -> bool:
	for line in Diagram.get_particle_lines():
		if line == self:
			continue
		if !line.is_placed:
			continue
		if (points[Point.Start] in line.points and points[Point.End] in line.points and line != self):
			return true
	return false

func is_line_overlapping() -> bool:
	for line in Diagram.get_particle_lines():
		if !line.is_placed:
			continue
		if !points[Point.Start] in line.points:
			continue 
		if line.is_position_on_line(points[Point.End]):
			return true
	return false

func is_hovered() -> bool:
	return hovering

func _on_click_area_mouse_entered() -> void:
	hovering = true

func _on_click_area_mouse_exited() -> void:
	hovering = false

func delete() -> void:
	queue_free()
	deconstructor()

func deconstructor():
	being_deleted = true
	for interaction in self.connected_interactions:
		interaction.connected_lines.erase(self)
	Diagram.update_statelines()
	points[Point.Start] = Vector2.LEFT
	points[Point.End] = Vector2.LEFT

func set_point_interaction_strength_alpha(point: Point, interaction_strength_alpha: float) -> void:
	if point == Point.Start:
		material.set_shader_parameter("start_interaction_strength_alpha", interaction_strength_alpha)
	else:
		material.set_shader_parameter("end_interaction_strength_alpha", interaction_strength_alpha)
