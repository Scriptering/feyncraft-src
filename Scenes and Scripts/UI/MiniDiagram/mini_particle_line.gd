extends Node2D
class_name MiniParticleLine

enum Anti {anti = -1, noanti = +1}
enum Point {Start = 0, End = 1, Invalid = -1}
enum PointsConnected {None, Left, Right, Both}

@export var line_joint_start_length: float = 1.75
@export var line_joint_end_length: float = .5
@export var gluon_loop_length: float = 4.5
@export var click_area_width: float = 3.5
@export var text_gap: float = 7
@export var gluon_line_width: float = 9
@export var particle_line_width: float = 6
@export var photon_line_width: float = 6

@onready var Text := $text
@onready var SpareText := $spareText
@onready var Arrow := $arrow
@onready var LineMiddle := $line_middle
@onready var LineJointStart := $line_joint_start
@onready var LineJointEnd := $line_joint_end

var Diagram: MiniDiagram
var Initial: Control
var Final: Control

var anti := 1 : set = _set_anti
var base_particle := ParticleData.Particle.none
var particle := ParticleData.Particle.none : get = _get_particle
var left_point: Vector2i
var right_point: Vector2i
var points : Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO] : set = _set_points
var line_vector : Vector2 = Vector2.ZERO:
	get: return points[Point.End] - points[Point.Start]
var particle_name : String : get = _get_particle_name

const texture_dict: Array = [
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

var line_texture : Texture2D

func _ready() -> void:
	set_line_width()

	line_texture = load('res://Textures/ParticlesAndLines/Lines/' + texture_dict[base_particle] + '.png')

	set_textures()
	
	update_line()

	Text.visible = true

func init(diagram: MiniDiagram) -> void:
	Diagram = diagram
	Initial = diagram.StateLines[StateLine.State.Initial]
	Final = diagram.StateLines[StateLine.State.Final]

func set_textures() -> void:
	LineMiddle.texture = line_texture
	Text.texture = ParticleData.particle_textures[self.particle_name]
	SpareText.texture = ParticleData.particle_textures[self.particle_name]

func _get_particle() -> ParticleData.Particle:
	return (anti * base_particle) as ParticleData.Particle

func _set_anti(new_value: int) -> void:
	anti = new_value

func _get_particle_name() -> String:
	return ParticleData.Particle.keys()[ParticleData.Particle.values().find(self.particle)]

func set_anti() -> void:
	if base_particle in ParticleData.SHADED_PARTICLES:
		if points[Point.Start].x <= points[Point.End].x:
			anti = Anti.noanti
		else:
			anti = Anti.anti
	else:
		anti = Anti.noanti

func _set_points(new_value: Array[Vector2i]) -> void:
	points = new_value

func set_left_and_right_points() -> void:
	if points[Point.Start].x <= points[Point.End].x:
		left_point = points[Point.Start]
		right_point = points[Point.End]
	else:
		left_point = points[Point.End]
		right_point = points[Point.Start]

func update_line() -> void:
	move_line()
	
	set_left_and_right_points()
	set_anti()
	
	Arrow.visible = get_arrow_visiblity()
	if Arrow.visible:
		move_arrow()

	move_text()
	
	set_text_texture()

func connect_to_interactions() -> void:
	for interaction:Interaction in Diagram.get_interactions():
		if interaction.position in points and !self in interaction.connected_lines:
			interaction.connected_lines.append(self)
		elif !interaction.position in points:
			interaction.connected_lines.erase(self)
	
func move_line() -> void:
	LineJointStart.points[Point.Start] = Vector2(points[Point.Start])
	LineJointEnd.points[Point.End] = Vector2(points[Point.End])
	
	LineJointStart.points[Point.End] = Vector2(points[Point.Start]) + line_joint_start_length * self.line_vector.normalized() 
	
	if base_particle == ParticleData.Particle.gluon:
		var number_of_gluon_loops : int = floor((self.line_vector.length() - line_joint_start_length - line_joint_end_length) / gluon_loop_length)
		
		LineJointEnd.points[Point.Start] = (
			LineJointStart.points[Point.End] +
			gluon_loop_length * number_of_gluon_loops * self.line_vector.normalized()
		)
	else:
		LineJointEnd.points[Point.Start] = Vector2(points[Point.End]) - line_joint_end_length * self.line_vector.normalized() 
	
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

func get_on_state_line() -> StateLine.State:
	if left_point.x == Initial.position.x and right_point.x == Final.position.x:
		return StateLine.State.Both
		
	if left_point.x == Initial.position.x:
		return StateLine.State.Initial
		
	if right_point.x == Final.position.x:
		return StateLine.State.Final
		
	return StateLine.State.None

func is_point_connected(point: Vector2) -> bool:
	for interaction:Interaction in Diagram.get_interactions():
		if point == interaction.position:
			return true
	return false

func is_position_on_line(test_position: Vector2) -> bool:
	var split_vector: Vector2 = test_position-Vector2(points[Point.Start])
	
	if test_position in points:
		return false
	
	if split_vector.normalized() != self.line_vector.normalized():
		return false

	if split_vector.length() >= self.line_vector.length():
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

func move_text() -> void:
	match get_on_state_line():
		StateLine.State.Both:
			Text.position = Vector2(left_point) + text_gap * Vector2.LEFT
			SpareText.position = Vector2(right_point) + text_gap * Vector2.RIGHT
			SpareText.show()
			return
		StateLine.State.Initial:
			Text.position = Vector2(left_point) + text_gap * Vector2.LEFT
			SpareText.hide()
			return
		StateLine.State.Final:
			Text.position = Vector2(right_point) + text_gap * Vector2.RIGHT
			SpareText.hide()
			return
	SpareText.hide()
	
	if points[Point.Start] == points[Point.End]:
		Text.position = Vector2(left_point) + text_gap * Vector2.LEFT
		return
	
	match get_points_connected():
		PointsConnected.Left:
			Text.position = Vector2(right_point) + text_gap * Vector2.RIGHT
		PointsConnected.Right:
			Text.position = Vector2(left_point) + text_gap * Vector2.LEFT
	
	Text.position = (
		Vector2(right_point - left_point) / 2 + Vector2(left_point) +
		text_gap * self.line_vector.orthogonal().normalized()
	)

func set_text_texture() -> void:
	Text.texture = ParticleData.particle_textures[self.particle_name]
	SpareText.texture = ParticleData.particle_textures[self.particle_name]

	if points[Point.End].x == points[Point.Start].x and base_particle == ParticleData.Particle.W:
		Text.texture = ParticleData.particle_textures['W_0']
