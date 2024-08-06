extends Node
class_name DrawingMatrixExporter

const xscale:float = .25
const yscale:float = .25
const scale: Vector2 = Vector2(xscale, yscale)

static func calc_centre(a: Vector2, b: Vector2, c:Vector2) -> Vector2:
	b -= a
	c -= a
	
	var A: float = 1 / (2*(c.y*b.x - b.y*c.x))
	var x2: float = A * (b.x * c.length_squared() - c.x * b.length_squared())
	
	var B: float = 1/(2*b.x)
	var x1: float = B * (b.length_squared() - 2*b.y*x2)
	
	return Vector2(x1, x2) + a

static func calc_out_angle(a: Vector2, centre: Vector2) -> float:
	var b : Vector2 = centre - a
	
	return acos(b.x/b.length())

static func get_lowest_x(positions: Array[Vector2i]) -> int:
	var lowest_x: int = positions[0].x
	
	for position: Vector2i in positions:
		if position.x < lowest_x:
			lowest_x = position.x

	return lowest_x

static func get_highest_y(positions: Array[Vector2i]) -> int:
	var highest_y: int = positions[0].y
	
	for position: Vector2i in positions:
		if position.y > highest_y:
			highest_y = position.y

	return highest_y

static func is_anti_connection(from_id:int, to_id:int, positions:Array[Vector2i], matrix:DrawingMatrix) -> bool:
	var is_forward_connection: bool = matrix.are_interactions_connected(from_id, to_id)
	var is_right_connection: bool = positions[to_id].x >= positions[from_id].x
	
	return is_forward_connection != is_right_connection

static func get_interaction_string(matrix: DrawingMatrix, id: int, positions:Array[Vector2i]) -> String:
	var interaction_string: String = ""
	
	var is_extreme_point: bool = matrix.is_extreme_point(id)
	
	var connection_particle: ParticleData.Particle
	if is_extreme_point:
		connection_particle = matrix.get_connected_particles(id, true)[0]
		var connected_id : int = matrix.get_connected_ids(id, true)[0]
		var is_anti : bool = is_anti_connection(id, connected_id, positions, matrix)
		
		connection_particle = connection_particle if !is_anti else ParticleData.anti(connection_particle)
	
	interaction_string += "\\vertex (i%s) at (%s*\\xscale, %s*\\yscale)%s;\n" % [
		id,
		positions[id].x,
		positions[id].y,
		" {\\(%s\\)}"%ParticleData.export_particle_dict[connection_particle] if is_extreme_point else ""
	]
	
	return interaction_string

static func get_bend_angle(centre: Vector2, point: Vector2) -> float:
	var angle: float = rad_to_deg(acos((centre - point).x/(centre - point).length()))
	angle += sign((centre - point).x) * 90
	angle *= sign((centre - point).y)
	
	return clamp(angle, -90, 90)

static func get_bend_connection_string(
	from_id: int, mid_id: int, to_id: int,
	particle: ParticleData.Particle,
	positions: Array[Vector2i],
	has_label: bool
) -> String:
	var out_vec: Vector2 = positions[mid_id] - positions[from_id]
	var in_vec: Vector2 = positions[mid_id] - positions[to_id]
	var out_angle : float = out_vec.angle()
	var in_angle : float = in_vec.angle()
	
	return (
		"(i%s) -- [%s, out = %s, in = %s%s] (i%s),\n"%[
			from_id,
			ParticleData.export_line_dict[particle],
			round(rad_to_deg(out_angle)),
			round(rad_to_deg(in_angle)),
			", edge label = %s"%[edge_label(particle)] if has_label else "",
			to_id
		]
	)

static func edge_label(particle: ParticleData.Particle) -> String:
	return "\\(%s\\)"%[ParticleData.export_particle_dict[particle]]

static func get_3loop_string(path: Array[int], positions: Array[Vector2i], particle: ParticleData.Particle) -> String:
	var out_vec: Vector2 = Vector2(positions[path[1]])*scale - Vector2(positions[path[0]])*scale
	var in_vec: Vector2 = Vector2(positions[path[2]])*scale - Vector2(positions[path[0]])*scale
	var out_angle : float = rad_to_deg(out_vec.angle())
	var in_angle : float = rad_to_deg(in_vec.angle())
	var min_distance : float = max(out_vec.length(), in_vec.length())
	return "i%s -- [%s, out = %s, in = %s, loop, min distance = %scm, edge label = %s] i%s,\n"%[
		path[0],
		ParticleData.export_line_dict[particle],
		round(out_angle),
		round(in_angle),
		round(min_distance) * 1.5,
		edge_label(particle),
		path[0]
	]

static func get_4loop_string(path: Array[int], positions: Array[Vector2i], particle: ParticleData.Particle) -> String:
	return "i%s -- [%s, half left, edge label = %s] i%s,\n"%[
		path[0],
		ParticleData.export_line_dict[particle],
		edge_label(particle),
		path[2]
	] + "i%s -- [%s, half left, edge label = %s] i%s,\n"%[
		path[2],
		ParticleData.export_line_dict[particle],
		edge_label(particle),
		path[0]
	]

static func get_bend_string(matrix:DrawingMatrix, from_id: int, first_bend_id: int, positions: Array[Vector2i]) -> String:
	var bend_path: Array[int] = matrix.get_bend_path(from_id, first_bend_id)
	var particle: ParticleData.Particle = matrix.get_connection_particles(from_id, first_bend_id).front()
	
	while bend_path.size() > (4 + int(bend_path.front() == bend_path.back())):
		bend_path.remove_at(randi_range(1, bend_path.size()-2))
	
	if bend_path.front() == bend_path.back():
		if bend_path.size() == 4:
			return get_3loop_string(bend_path, positions, particle)
		elif bend_path.size() == 5:
			return get_4loop_string(bend_path, positions, particle)
	
	return get_bend_connection_string(
		from_id,
		bend_path[randi_range(1, bend_path.size()-2)],
		bend_path[-1],
		particle,
		positions,
		has_label(from_id, bend_path[-1], matrix)
	)

static func has_label(from_id: int, to_id: int, matrix:DrawingMatrix) -> bool:
	return !(
		matrix.is_extreme_point(from_id)
		|| matrix.is_extreme_point(to_id)
	)

static func get_direct_connection_string(
	matrix:DrawingMatrix,
	from_id:int, to_id:int,
	particle:ParticleData.Particle,
	positions:Array[Vector2i]
) -> String:
	
	var connection_string: String = ""
	var is_right : bool = positions[to_id].x >= positions[from_id].x
	
	var label_particle: ParticleData.Particle = particle
	if !is_right:
		label_particle = ParticleData.anti(label_particle)

	var has_label: bool = has_label(from_id, to_id, matrix)
	
	connection_string += "(i%s) -- [%s%s] (i%s),\n" % [
		from_id,
		ParticleData.export_line_dict[particle],
		", edge label = \\(%s\\)"%ParticleData.export_particle_dict[label_particle] if has_label else "",
		to_id
	]
	
	
	return connection_string

static func get_highest_hadron_id(hadron_ids:PackedInt32Array, positions:Array[Vector2i]) -> int:
	var highest_id: int = hadron_ids[0]
	
	for id:int in hadron_ids:
		if positions[id] > positions[highest_id]:
			highest_id = id
	
	return highest_id

static func get_lowest_hadron_id(hadron_ids:PackedInt32Array, positions:Array[Vector2i]) -> int:
	var lowest_id: int = hadron_ids[0]
	
	for id:int in hadron_ids:
		if positions[id] < positions[lowest_id]:
			lowest_id = id
	
	return lowest_id

static func get_hadron_particles(
	matrix:DrawingMatrix,
	hadron_ids:PackedInt32Array,
	positions:Array[Vector2i]
) -> Array[ParticleData.Particle]:
	var particles: Array[ParticleData.Particle] = []
	
	for id:int in hadron_ids:
		var to_id:int = matrix.get_connected_ids(id, true)[0]
		var particle:ParticleData.Particle = matrix.get_connected_particles(id, true)[0]
		var is_anti: bool = is_anti_connection(id, to_id, positions, matrix)
		
		particles.push_back(particle if !is_anti else ParticleData.anti(particle))
	
	return particles


static func get_hadron_string(
	matrix:DrawingMatrix,
	hadron_ids:PackedInt32Array,
	positions:Array[Vector2i]
) -> String:
	var hadron_string: String = ""
	
	var state: StateLine.State = matrix.get_state_from_id(hadron_ids[0])
	
	var on_left: bool = matrix.get_state_from_id(hadron_ids[0]) == StateLine.State.Initial
	var label_position: String = "left" if on_left else "right"
	
	var lowest_id:int = get_lowest_hadron_id(hadron_ids, positions)
	var highest_id:int = get_highest_hadron_id(hadron_ids, positions)
	
	var from_id:int = lowest_id if on_left else highest_id
	var to_id:int = highest_id if on_left else lowest_id
	
	var from_position:String = "south west" if on_left else "north east"
	var to_position:String = "north west" if on_left else "south east"
	
	hadron_string += "\\draw [decoration={brace}, decorate] (i%s.%s) -- (i%s.%s)\n"%[
		from_id, from_position, to_id, to_position
	]
	
	var particles:Array = get_hadron_particles(matrix, hadron_ids, positions)
	
	hadron_string += "\tnode [pos=0.5, %s] {\\(%s\\)};\n"%[
		label_position, ParticleData.export_hadron_dict[ParticleData.find_hadron(particles)]
	]
	
	return hadron_string

static func get_string(drawing_matrix: DrawingMatrix) -> String:
	var exporting_matrix: DrawingMatrix = drawing_matrix.duplicate(true)
	exporting_matrix.fix_directionless_bend_paths()
	var interaction_positions := exporting_matrix.normalised_interaction_positions
	
	var lowest_x : int = get_lowest_x(interaction_positions)
	var highest_y : int = get_highest_y(interaction_positions)
	
	for i:int in interaction_positions.size():
		interaction_positions[i] *= Vector2i(+1, -1)
		interaction_positions[i] -= Vector2i(lowest_x, -highest_y)
	
	var export_string : String = "\\begin{tikzpicture}\n\\begin{feynman}\n"
	export_string += "\\def\\xscale{%s}\n\\def\\yscale{%s}\n" % [
		xscale, yscale
	]

	var diagram_string := "\\diagram* {\n"
	
	for id:int in exporting_matrix.matrix_size:
		if drawing_matrix.is_bend_id(id):
			continue
		
		for c:Array in exporting_matrix.get_connections(id):
			var to_id: int = c[ConnectionMatrix.Connection.to_id]
			var particle: ParticleData.Particle = c[ConnectionMatrix.Connection.particle]
			
			if drawing_matrix.is_bend_id(to_id):
				diagram_string += get_bend_string(
					exporting_matrix,
					id, to_id,
					interaction_positions
				)
			
			else:
				diagram_string += get_direct_connection_string(
					exporting_matrix,
					id,
					c[ConnectionMatrix.Connection.to_id],
					c[ConnectionMatrix.Connection.particle],
					interaction_positions
				)
	
	diagram_string += "};\n"
	
	var interaction_string : String = ""
	for id:int in exporting_matrix.matrix_size:
		if diagram_string.find("i%s"%[id]) == -1:
			continue
		
		interaction_string += get_interaction_string(exporting_matrix, id, interaction_positions)
	
	export_string += interaction_string
	export_string += diagram_string
	
	for hadron_ids:Array in exporting_matrix.split_hadron_ids:
		export_string += get_hadron_string(exporting_matrix, hadron_ids, interaction_positions)

	export_string += "\\end{feynman}\n\\end{tikzpicture}\n"

	return export_string
