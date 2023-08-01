class_name DiagramActions
extends Node

var Interactions: Control
var ParticleLines: Control
var ParticleButtons: Control
var StateLines: Array

@onready var Line = preload("res://Scenes and Scripts/Diagram/line.tscn")
@onready var InteractionInstance = preload("res://Scenes and Scripts/Diagram/interaction.tscn")

func init(interactions: Control, particle_lines: Control, particle_buttons: Control, state_lines: Array) -> void:
	Interactions = interactions
	ParticleLines = particle_lines
	ParticleButtons = particle_buttons
	StateLines = state_lines

func get_selected_particle() -> GLOBALS.Particle:
	return ParticleButtons.selected_particle

func delete_line(line: ParticleLine) -> void:
	line.queue_free()
	line.deconstructor()
	for interaction in line.connected_interactions:
		if interaction.connected_lines.size() == 0:
			interaction.queue_free()

func delete_interaction(interaction: Interaction) -> void:
	interaction.queue_free()
	var connected_lines := interaction.connected_lines.duplicate()
	for line in connected_lines:
		for connected_interaction in line.connected_interactions:
			if connected_interaction.connected_lines.size() == 1:
				connected_interaction.queue_free()
		delete_line(line)

func split_line(line_to_split: ParticleLine, split_point: Vector2) -> void:
	var new_line = Line.instantiate()

	new_line.points[ParticleLine.Point.Start] = line_to_split.points[ParticleLine.Point.Start]
	new_line.points[ParticleLine.Point.End] = split_point
	line_to_split.points[ParticleLine.Point.Start] = split_point

	new_line.base_particle = line_to_split.base_particle
	new_line.is_placed = true

	ParticleLines.add_child(new_line)

	line_to_split.update_line()

func check_split_lines() -> void:
	for interaction in get_tree().get_nodes_in_group("interactions"):
		for line in get_tree().get_nodes_in_group('lines'):
			if !line.is_placed:
				continue
			if line in interaction.connected_lines:
				continue
			if line.is_position_on_line(interaction.position):
				split_line(line, interaction.position)

func check_rejoin_lines() -> void:
	for interaction in get_tree().get_nodes_in_group("interactions"):
		if interaction.connected_lines.size() != 2:
			continue
		if can_rejoin_lines(interaction.connected_lines[0], interaction.connected_lines[1]):
			rejoin_lines(interaction.connected_lines[0], interaction.connected_lines[1])
			delete_interaction(interaction)

func can_rejoin_lines(line1: ParticleLine, line2: ParticleLine) -> bool:
	if !(line1.is_placed and line2.is_placed):
		return false
	
	if line1.base_particle != line2.base_particle:
		return false
	
	if line1.base_particle in GLOBALS.FERMIONS and line1.particle != line2.particle:
		return false

	if (
		line1.get_line_vector().normalized() == line2.get_line_vector().normalized() or
		line1.get_line_vector().normalized() == -line2.get_line_vector().normalized()
	):
		return true
	
	return false

func rejoin_lines(line_to_extend: ParticleLine, line_to_delete: ParticleLine) -> void:
	var point_to_move : int
	
	if line_to_extend.points[ParticleLine.Point.Start] in line_to_delete.points:
		point_to_move = ParticleLine.Point.Start
	else:
		point_to_move = ParticleLine.Point.End
	
	var point_to_move_to : int
	if line_to_delete.points[ParticleLine.Point.Start] in line_to_extend.points:
		point_to_move_to = ParticleLine.Point.End
	else:
		point_to_move_to = ParticleLine.Point.Start
	
	line_to_extend.points[point_to_move] = line_to_delete.points[point_to_move_to]
	delete_line(line_to_delete)
	line_to_extend.update_line()

func place_interaction(interaction_position: Vector2, bypass_can_place: bool = false) -> void:
	if can_place_interaction(interaction_position) or bypass_can_place:
		var interaction = InteractionInstance.instantiate()
		interaction.position = interaction_position
		Interactions.add_child(interaction)

func can_place_interaction(test_position: Vector2) -> bool:
	for interaction in get_tree().get_nodes_in_group("interactions"):
		if interaction.position == test_position:
			return false
	return true

func place_line(
	start_position: Vector2, end_position: Vector2 = Vector2.ZERO,
	base_particle: GLOBALS.Particle = ParticleButtons.selected_particle
) -> void:
	var line : ParticleLine = Line.instantiate()
	line.points[line.Point.Start] = start_position
	
	if end_position != Vector2.ZERO:
		line.points[line.Point.End] = end_position
		line.is_placed = true
	
	line.base_particle = base_particle
	
	ParticleLines.add_child(line)

func clear_diagram() -> void:
	for interaction in get_tree().get_nodes_in_group("interactions"):
		delete_interaction(interaction)
	for state_line in StateLines:
		state_line.clear_hadrons()


