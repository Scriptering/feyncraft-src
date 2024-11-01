class_name MiniDiagram
extends DiagramBase

@onready var mini_hadron_joint := preload("res://Scenes_and_scripts/UI/MiniDiagram/MiniHadronJoint.tscn")

func generate_drawing_matrix_from_diagram() -> DrawingMatrix:
	var generated_matrix := DrawingMatrix.new()

	for interaction:MiniInteraction in get_interactions():
		generated_matrix.add_interaction_with_position(interaction.position, grid_size, interaction.get_on_state_line())

	for particle_line:ParticleLine in get_particle_lines():
		generated_matrix.connect_interactions(
			generated_matrix.get_interaction_positions().find(particle_line.points[ParticleLine.Point.Start] / grid_size),
			generated_matrix.get_interaction_positions().find(particle_line.points[ParticleLine.Point.End] / grid_size),
			particle_line.base_particle
		)

	return generated_matrix

func clear_diagram() -> void:
	for interaction:MiniInteraction in get_interactions():
		interaction.free()
	
	for particle_line:MiniParticleLine in get_particle_lines():
		particle_line.free()
	
	for hadron_joint:MiniHadronJoint in get_hadron_joints():
		hadron_joint.free()

func show_interaction_dots(drawing_matrix: DrawingMatrix) -> void:
	for id:int in drawing_matrix.get_state_ids(StateLine.State.Both):
		Interactions.get_child(id).show_state_dot()
	
	for id:int in drawing_matrix.get_state_ids(StateLine.State.None):
		var connected_count: int = drawing_matrix.get_connected_count(id, true)
		
		if connected_count < 3:
			Interactions.get_child(id).show_dot(0)
		elif connected_count == 3:
			Interactions.get_child(id).show_dot(1)
		elif connected_count > 3:
			Interactions.get_child(id).show_dot(2)

func find_hadron(quarks: Array) -> ParticleData.Hadron:
	for hadron:ParticleData.Hadron in ParticleData.HADRON_QUARK_CONTENT:
		if quarks in ParticleData.HADRON_QUARK_CONTENT[hadron]:
			return hadron
	
	return ParticleData.Hadron.proton

func create_hadron_joint(drawing_matrix: DrawingMatrix, hadron_ids: PackedInt32Array) -> void:
	var interaction_ys: PackedInt32Array = []
	var quarks: Array = []
	
	for id:int in hadron_ids:
		interaction_ys.push_back(int(drawing_matrix.normalised_interaction_positions[id].y*grid_size))
		
		if drawing_matrix.get_state_from_id(id) == StateLine.State.Initial:
			quarks.append_array(drawing_matrix.get_connected_particles(id))
			quarks.append_array(drawing_matrix.get_connected_particles(id, false, false, true).map(
				func(particle: ParticleData.Particle) -> ParticleData.Particle:
					return -particle as ParticleData.Particle
			))
		
		else:
			quarks.append_array(drawing_matrix.get_connected_particles(id).map(
				func(particle: ParticleData.Particle) -> ParticleData.Particle:
					return -particle as ParticleData.Particle
			))
			quarks.append_array(drawing_matrix.get_connected_particles(id, false, false, true))
	
	quarks.sort()
	
	var hadron_joint := mini_hadron_joint.instantiate()
	hadron_joint.hadron = find_hadron(quarks)
	
	hadron_joint.interaction_ys = interaction_ys
	
	var state : StateLine.State = drawing_matrix.get_state_from_id(hadron_ids[0])
	
	hadron_joint.state = state
	
	$DiagramArea/HadronJoints.add_child(hadron_joint)
	
	hadron_joint.init(StateLines[state].position.x, self)

func draw_diagram(drawing_matrix: DrawingMatrix) -> void:
	super.draw_diagram(drawing_matrix)
	show_interaction_dots(drawing_matrix)

	for split_hadron:PackedInt32Array in drawing_matrix.split_hadron_ids:
		create_hadron_joint(drawing_matrix, split_hadron)
