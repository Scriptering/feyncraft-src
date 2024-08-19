extends Node2D
class_name ParticleLine

signal deleted

@onready var Text := get_node("text")
@onready var SpareText := get_node("spareText")
@onready var Arrow := $arrow
@onready var LineMiddle := $line_middle
@onready var LineJointStart := $line_joint_start
@onready var LineJointEnd := $line_joint_end

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
enum Side {left, right}
enum PointsConnected {None, Left, Right, Both}
enum Shade {Bright, Dark}

var Diagram: MainDiagram
var Initial: StateLine
var Final: StateLine
var Crosshair: Node

var points : Array[Vector2i] = [Vector2i.LEFT, Vector2i.LEFT] : set = _set_points
var prev_points : Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 0)]
var line_vector : Vector2 = Vector2.ZERO:
	get: return points[Point.End] - points[Point.Start]

var base_particle := ParticleData.Particle.none
var particle := ParticleData.Particle.none : get = _get_particle
var particle_name : String : get = _get_particle_name

var connected_interactions : Array[Interaction] = [null, null]

var anti := 1 : set = _set_anti
var on_state_line := StateLine
var quantum_numbers: Array : get = _get_quantum_numbers
var dimensionality: float
var being_deleted : bool = false
var update_queued: bool = true

var has_colour := false
var has_shade := false

var left_point: Point = Point.Start
var right_point: Point = Point.End

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

var line_texture: Texture2D
var show_labels: bool = true

func _ready() -> void:
	has_colour = base_particle in ParticleData.COLOUR_PARTICLES
	has_shade = base_particle in ParticleData.SHADED_PARTICLES
	quantum_numbers = ParticleData.QUANTUM_NUMBERS[base_particle]
	set_dimensionality()
	set_line_width()

	line_texture = load('res://Textures/ParticlesAndLines/Lines/' + texture_dict[base_particle] + '.png')

	set_textures()
	
	set_anti()
	set_left_and_right_points()
	
	click_area_width = 12 if Globals.is_on_mobile() else 7

func init(diagram: MainDiagram) -> void:
	Diagram = diagram
	Initial = diagram.StateLines[StateLine.State.Initial]
	Final = diagram.StateLines[StateLine.State.Final]
	Crosshair = diagram.Crosshair

func _input(event: InputEvent) -> void:
	if Globals.is_on_mobile():
		if event is InputEventScreenTouch and event.pressed and is_hovered(event.position - global_position):
			EventBus.deletable_object_clicked.emit(self)
	elif event.is_action_pressed("click") and is_hovered(get_local_mouse_position()):
		EventBus.deletable_object_clicked.emit(self)

func _set_points(new_points: Array[Vector2i]) -> void:
	points = new_points
	set_anti()
	set_left_and_right_points()

func _get_particle() -> ParticleData.Particle:
	return (anti * base_particle) as ParticleData.Particle

func _get_quantum_numbers() -> Array:
	var quantum_numbers_temp := []
	for quantum_number:ParticleData.QuantumNumber in ParticleData.QuantumNumber.values():
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
	
func set_textures() -> void:
	LineMiddle.texture = line_texture
	Text.texture = ParticleData.particle_textures[self.particle_name]
	SpareText.texture = ParticleData.particle_textures[self.particle_name]

func _get_particle_name() -> String:
	return ParticleData.Particle.keys()[ParticleData.Particle.values().find(self.particle)]

func get_side_point(side: ParticleLine.Side) -> Point:
	if side == Side.left:
		return left_point
	return right_point

func get_side_position(side: int) -> Vector2i:
	return points[get_side_point(side)]

func set_dimensionality() -> void:
	if base_particle in ParticleData.FERMIONS:
		dimensionality = ParticleData.FERMION_DIMENSIONALITY
	elif base_particle in ParticleData.BOSONS:
		dimensionality = ParticleData.BOSON_DIMENSIONALITY

func set_left_and_right_points() -> void:
	if points[Point.Start].x <= points[Point.End].x:
		left_point = Point.Start
		right_point = Point.End
	else:
		left_point = Point.End
		right_point = Point.Start

func connect_interaction(interaction: Interaction, point:Point = points.find(interaction.positioni())) -> void:
	connected_interactions[point] = interaction

func get_on_state_line() -> StateLine.State:
	if points[left_point].x == Initial.position.x and points[right_point].x == Final.position.x:
		return StateLine.State.Both
		
	if points[left_point].x == Initial.position.x:
		return StateLine.State.Initial
		
	if points[right_point].x == Final.position.x:
		return StateLine.State.Final
		
	return StateLine.State.None

func get_interaction_at_point(point: Point) -> Interaction:
	var interaction_at_point : Interaction
	for interaction:Interaction in self.connected_interactions:
		if points[point] == interaction.positioni():
			interaction_at_point = interaction
	return interaction_at_point

func is_point_connected(point: Vector2i) -> bool:
	for interaction:Interaction in self.connected_interactions:
		if point == interaction.positioni():
			return true
	return false

func is_position_on_line(test_position: Vector2i) -> bool:
	var split_vector: Vector2 = test_position - points[Point.Start]
	
	if test_position in points:
		return false
	
	if !ArrayFuncs.is_vec_zero_approx(split_vector.normalized() - line_vector.normalized()):
		return false

	if split_vector.length() >= line_vector.length():
		return false
	
	return true

func is_vertical() -> bool:
	return points[Point.Start].x == points[Point.End].x

func get_points_connected() -> PointsConnected:
	if connected_interactions[left_point] and connected_interactions[right_point]:
		return PointsConnected.Both

	if connected_interactions[left_point]:
		return PointsConnected.Left
	
	if connected_interactions[right_point]:
		return PointsConnected.Right
	
	return PointsConnected.None

func get_point_at_position(test_position: Vector2i) -> Point:
	if test_position == points[Point.Start]:
		return Point.Start
	elif test_position == points[Point.End]:
		return Point.End
	return Point.Invalid

func get_connected_point(interaction: Interaction) -> Point:
	return connected_interactions.find(interaction) as Point

func get_unconnected_point(interaction: Interaction) -> Point:
	return (get_connected_point(interaction)+1)%2 as Point

func queue_update() -> void:
	update_queued = true

func update() -> void:
	if points != prev_points:
		prev_points = points.duplicate()
		
		move_line()

		Arrow.visible = get_arrow_visiblity()
		if Arrow.visible:
			move_arrow()

	set_text_texture()
	move_text()
	set_text_visiblity()

func move(point:Point, to_position: Vector2i) -> void:
	points[point] = to_position
	set_anti()
	queue_update()

func move_line() -> void:
	LineJointStart.points[Point.Start] = Vector2(points[Point.Start])
	LineJointEnd.points[Point.End] = Vector2(points[Point.End])
	
	LineJointStart.points[Point.End] = (
		Vector2(points[Point.Start])
		+ line_joint_start_length
		* self.line_vector.normalized() 
	)
	
	if base_particle == ParticleData.Particle.gluon:
		var number_of_gluon_loops : int = floor((self.line_vector.length() - line_joint_start_length - line_joint_end_length) / gluon_loop_length)
		
		LineJointEnd.points[Point.Start] = (
			LineJointStart.points[Point.End] +
			gluon_loop_length * number_of_gluon_loops * self.line_vector.normalized()
		)
	else:
		LineJointEnd.points[Point.Start] = (
			Vector2(points[Point.End])
			- line_joint_end_length
			* self.line_vector.normalized()
		)
	
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
	Arrow.position = Vector2(points[Point.Start]) + self.line_vector / 2
	Arrow.rotation = self.line_vector.angle()

func move_text() -> void:
	match get_on_state_line():
		StateLine.State.Both:
			Text.position = Vector2(points[left_point]) + text_gap * Vector2.LEFT
			SpareText.position = Vector2(points[right_point]) + text_gap * Vector2.RIGHT
			return
		StateLine.State.Initial:
			Text.position = Vector2(points[left_point]) + text_gap * Vector2.LEFT
			return
		StateLine.State.Final:
			Text.position = Vector2(points[right_point]) + text_gap * Vector2.RIGHT
			return
	
	if points[Point.Start] == points[Point.End]:
		Text.position = Vector2(points[left_point]) + text_gap * Vector2.LEFT
		return
	
	match get_points_connected():
		PointsConnected.Left:
			Text.position = Vector2(points[right_point]) + text_gap * Vector2.RIGHT
		PointsConnected.Right:
			Text.position = Vector2(points[left_point]) + text_gap * Vector2.LEFT
	
	Text.position = (
		(Vector2(points[right_point]) - Vector2(points[left_point])) / 2 + Vector2(points[left_point]) +
		text_gap * self.line_vector.orthogonal().normalized()
	)

func set_text_visiblity() -> void:
	if Globals.in_main_menu:
		Text.hide()
		SpareText.hide()
		return
	
	match get_on_state_line():
		StateLine.State.None:
			if !show_labels:
				Text.hide()
				SpareText.hide()
				return
		StateLine.State.Both:
			Text.show()
			SpareText.show()
			return
	
	Text.show()
	SpareText.hide()

func set_text_texture() -> void:
	Text.texture = ParticleData.particle_textures[self.particle_name]
	SpareText.texture = ParticleData.particle_textures[self.particle_name]

	if points[Point.End].x == points[Point.Start].x and base_particle == ParticleData.Particle.W:
		Text.texture = ParticleData.particle_textures['W_0']

func is_duplicate(particle_line: ParticleLine) -> bool:
	if particle_line == self:
		return false
	
	if particle_line.points[Point.Start] == particle_line.points[Point.End]:
		return false
	
	if !(particle_line.points[Point.Start] in points):
		return false
	
	if !(particle_line.points[Point.End] in points):
		return false
	
	return true

func is_overlapping(particle_line: ParticleLine) -> bool:
	if particle_line == self:
		return false
	
	if particle_line.points[Point.Start] == particle_line.points[Point.End]:
		return false
	
	if !(
		particle_line.line_vector.normalized() == line_vector.normalized()
		|| particle_line.line_vector.normalized() == -line_vector.normalized()
	):
		return false
	
	return (
		is_position_on_line(particle_line.points[ParticleLine.Point.Start])
		|| is_position_on_line(particle_line.points[ParticleLine.Point.End])
	)
	
	return true

func is_hovered(pos: Vector2) -> bool:
	var v := line_vector.normalized();
	var m := pos - Vector2(points[Point.Start]);

	var lambda := m.x*v.x + m.y*v.y
	var rho :=   -m.x*v.y + m.y*v.x


	if lambda < 0 or lambda > line_vector.length():
		return false
	
	if rho > click_area_width or rho < -click_area_width:
		return false
	
	return true

func delete() -> void:
	deleted.emit(self)
	queue_free()

func deconstructor() -> void:
	being_deleted = true
	points[Point.Start] = Vector2.LEFT
	points[Point.End] = Vector2.LEFT

func set_point_interaction_strength_alpha(point: Point, interaction_strength_alpha: float) -> void:
	if point == Point.Start:
		material.set_shader_parameter("start_interaction_strength_alpha", interaction_strength_alpha)
	else:
		material.set_shader_parameter("end_interaction_strength_alpha", interaction_strength_alpha)
