class_name MiniDiagram
extends DiagramBase

@onready var MiniHadronJoint := preload("res://Scenes and Scripts/UI/MiniDiagram/MiniHadronJoint.tscn")

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
	
	for hadron_joint in HadronJoints.get_children():
		hadron_joint.queue_free()

func show_interaction_dots(drawing_matrix: DrawingMatrix) -> void:
	for id in drawing_matrix.get_state_ids(StateLine.StateType.Both):
		Interactions.get_child(id).show_dot()
	
	for id in drawing_matrix.get_state_ids(StateLine.StateType.None):
		if drawing_matrix.get_connected_count(id, true) >= Interaction.INTERACTION_SIZE_MINIMUM:
			Interactions.get_child(id).show_dot()

func find_hadron(quarks: Array) -> ParticleData.Hadrons:
	for hadron in ParticleData.HADRON_QUARK_CONTENT:
		if quarks in ParticleData.HADRON_QUARK_CONTENT[hadron]:
			return hadron
	
	return ParticleData.Hadrons.Proton

func create_hadron_joint(drawing_matrix: DrawingMatrix, hadron_ids: PackedInt32Array) -> void:
	var interaction_ys: PackedInt32Array = []
	var quarks: Array = []
	
	for id in hadron_ids:
		interaction_ys.push_back(int(drawing_matrix.normalised_interaction_positions[id].y*grid_size))
		
		if drawing_matrix.get_state_from_id(id) == StateLine.StateType.Initial:
			quarks.append_array(drawing_matrix.get_connected_particles(id))
			quarks.append_array(drawing_matrix.get_connected_particles(id, false, false, true).map(
				func(particle: ParticleData.Particle): return -particle
			))
		
		else:
			quarks.append_array(drawing_matrix.get_connected_particles(id).map(
				func(particle: ParticleData.Particle): return -particle
			))
			quarks.append_array(drawing_matrix.get_connected_particles(id, false, false, true))
	
	quarks.sort()
	
	var hadron_joint := MiniHadronJoint.instantiate()
	hadron_joint.hadron = find_hadron(quarks)
	
	hadron_joint.interaction_ys = interaction_ys
	
	var state : StateLine.StateType = drawing_matrix.get_state_from_id(hadron_ids[0])
	
	hadron_joint.state = state
	
	$DiagramArea/HadronJoints.add_child(hadron_joint)
	
	hadron_joint.init(StateLines[state].position.x, self)

func draw_diagram(drawing_matrix: DrawingMatrix) -> void:
	super.draw_diagram(drawing_matrix)
	
	await get_tree().process_frame

	show_interaction_dots(drawing_matrix)

	for split_hadron in drawing_matrix.split_hadron_ids:
		create_hadron_joint(drawing_matrix, split_hadron)

