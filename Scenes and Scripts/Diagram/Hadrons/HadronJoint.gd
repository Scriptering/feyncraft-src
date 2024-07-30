extends Node2D
class_name HadronJoint

@onready var HadronLabel := $HadronSprite

@export var label_seperation : float = 25
var state : StateLine.State
var hadron : Hadron
var hadron_lines : Array

func _ready() -> void:
	place_label()

func init() -> void:
	hadron_lines = hadron.quark_lines
	position = calculate_position()
	$Panel.size.y += get_hadron_seperation()

func get_hadron_interactions() -> Array[Interaction]:
	var hadron_interactions : Array[Interaction] = []
	
	for hadron_line:ParticleLine in hadron_lines:
		hadron_interactions.push_back(
			hadron_line.get_interaction_at_point(hadron_line.get_point_at_position(hadron_line.get_side_position(state as ParticleLine.Side)))
		)
	
	return hadron_interactions

func get_hadron_seperation() -> int:
	return abs(get_highest_line().get_side_position(state).y-get_lowest_line().get_side_position(state).y)

func calculate_position() -> Vector2:
	return get_lowest_line().get_side_position(state)

func get_lowest_line() -> ParticleLine:
	var lowest_line : ParticleLine = hadron_lines[0]
	for particle_line:ParticleLine in hadron_lines:
		if particle_line.get_side_position(state).y < lowest_line.get_side_position(state).y:
			lowest_line = particle_line
	return lowest_line

func get_highest_line() -> ParticleLine:
	var highest_line : ParticleLine = hadron_lines[0]
	for particle_line:ParticleLine in hadron_lines:
		if particle_line.get_side_position(state).y > highest_line.get_side_position(state).y:
			highest_line = particle_line
	return highest_line

func place_label() -> void:
	HadronLabel.texture = ParticleData.get_hadron_texture(hadron.hadron)
	
	if state == StateLine.State.Initial:
		HadronLabel.position.x = -label_seperation
	else:
		HadronLabel.position.x = label_seperation
	
	HadronLabel.position.y += get_hadron_seperation()/2
