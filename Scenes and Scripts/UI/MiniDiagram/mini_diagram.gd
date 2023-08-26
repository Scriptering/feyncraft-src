class_name MiniDiagram
extends DiagramBase

func generate_drawing_matrix_from_diagram() -> DrawingMatrix:
	var generated_matrix := DrawingMatrix.new()

	for interaction in get_interactions():
		generated_matrix.add_interaction_with_position(interaction.position, grid_size, interaction.get_on_state_line())

	for line in get_particle_lines():
		generated_matrix.connect_interactions(
			generated_matrix.get_interaction_positions().find(line.points[ParticleLine.Point.Start] / grid_size),
			generated_matrix.get_interaction_positions().find(line.points[ParticleLine.Point.End] / grid_size),
			line.base_particle
		)

	return generated_matrix

func clear_diagram() -> void:
	for interaction in Interactions.get_children():
		interaction.queue_free()
	
	for line in ParticleLines.get_children():
		line.queue_free()
