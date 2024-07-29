extends Node2D
class_name MiniHadronJoint

@onready var HadronLabel := $HadronSprite

@export var label_seperation : float = 20
var state : StateLine.State
var hadron: ParticleData.Hadrons
var interaction_ys: PackedInt32Array

var Diagram: MiniDiagram

func _ready() -> void:
	place_label()
	interaction_ys.sort()

func array_min(array: Array) -> Variant:
	var min_element : Variant = array[0]
	
	for element:Variant in array:
		if element < min_element:
			min_element = element
	
	return min_element

func init(position_x: int, _diagram: MiniDiagram) -> void:
	position.x = position_x
	position.y = array_min(interaction_ys)
	$Panel.size.y += get_hadron_seperation()
	Diagram = _diagram

func get_hadron_interactions() -> Array:
	return ArrayFuncs.find_all_var(
		Diagram.get_interactions(),
		func(interaction: MiniInteraction) -> bool:
			return (
				interaction.position.y in interaction_ys and
				interaction.get_on_state_line() == state
			)
	)

func get_hadron_seperation() -> float:
	return interaction_ys[-1] - interaction_ys[0]

func place_label() -> void:
	HadronLabel.texture = ParticleData.get_hadron_texture(hadron)
	
	if state == StateLine.State.Initial:
		HadronLabel.position.x = -label_seperation + 5
	else:
		HadronLabel.position.x = label_seperation
	
	HadronLabel.position.y += get_hadron_seperation()/2
