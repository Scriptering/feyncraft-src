extends Node2D

@onready var HadronLabel = $HadronSprite

@export var label_seperation : float = 20
var state : StateLine.StateType
var hadron: GLOBALS.Hadrons
var interaction_ys: PackedInt32Array

func _ready():
	place_label()
	interaction_ys.sort()

func array_min(array: Array):
	var min_element = array[0]
	
	for element in array:
		if element < min_element:
			min_element = element
	
	return min_element

func init(position_x: int) -> void:
	position.x = position_x
	position.y = array_min(interaction_ys)
	$Panel.size.y += get_hadron_seperation()

func get_hadron_seperation() -> float:
	return interaction_ys[-1] - interaction_ys[0]

func place_label() -> void:
	HadronLabel.texture = GLOBALS.get_hadron_texture(hadron)
	
	if state == StateLine.StateType.Initial:
		HadronLabel.position.x = -label_seperation + 5
	else:
		HadronLabel.position.x = label_seperation
	
	HadronLabel.position.y += get_hadron_seperation()/2
