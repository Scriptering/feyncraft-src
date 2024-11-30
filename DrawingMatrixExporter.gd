extends Node
class_name DrawingMatrixExporter

var join_paths: bool = true
var draw_external_labels: bool = true
var draw_internal_labels: bool = true
var matrix: DrawingMatrix
var particle_matrix: DrawingMatrix
var positions: Array[Vector2i]
var decorations: Array[Decoration.Decor]
var fermion_paths: Array[PackedInt32Array]

const xscale:float = .25
const yscale:float = .3
const scale: Vector2 = Vector2(xscale, yscale)

func _init(_matrix: DrawingMatrix) -> void:
	matrix = _matrix
	decorations = _matrix.decorations
	
	matrix.fix_directionless_bend_paths()
	positions = calc_positions()

func generate_export() -> String:

	var export_string : String = "\\begin{tikzpicture}\n\\begin{feynman}\n"
	export_string += "\\def\\xscale{%s} %%change to stretch in x\n"%[xscale]
	export_string += "\\def\\yscale{%s} %%change to stretch in y\n"%[yscale]
	
	var diagram_string : String = get_diagram_string()
	
	var interaction_string : String = ""
	for id:int in matrix.matrix_size:
		if diagram_string.find("i%s"%[id]) == -1:
			continue
		
		interaction_string += get_interaction_string(id)
	
	export_string += interaction_string
	export_string += diagram_string
	
	if draw_external_labels:
		for hadron_ids:Array in matrix.split_hadron_ids:
			export_string += get_hadron_string(hadron_ids)

	export_string += "\\end{feynman}\n\\end{tikzpicture}\n"

	return export_string

func get_diagram_string() -> String:
	var diagram_string := "\\diagram* {\n"
	
	var fermion_string: String = get_fermion_string()
	diagram_string += fermion_string
	
	var boson_matrix := matrix.get_reduced_matrix(
		func(particle : ParticleData.Particle) -> bool:
			return !(particle in ParticleData.FERMIONS)
	)
	
	var has_passed: bool = false
	for id:int in boson_matrix.matrix_size:
		if is_bend_interaction(id):
			continue
		
		var connected_ids: PackedInt32Array = boson_matrix.get_connected_ids(id)
		for i:int in connected_ids.size():
			if has_passed or !fermion_string.is_empty():
				diagram_string += ",\n"
			has_passed = true

			var to_id: int = connected_ids[i]
			var particle : ParticleData.Particle = boson_matrix.get_connection_particles(id, to_id).front()
			
			diagram_string += get_connection_string(id, to_id, particle)
	
	diagram_string += "\n};\n"
	
	return diagram_string

func get_connection_string(id: int, to_id: int, particle: ParticleData.Particle) -> String:
	if is_bend_interaction(to_id):
		return get_bend_string(id, to_id, particle)
	
	else:
		return get_direct_connection_string(id, to_id, particle)

func get_fermion_string() -> String:
	var fermion_string: String = ""
	
	var fermion_matrix : DrawingMatrix = matrix.get_reduced_matrix(
		func(particle : ParticleData.Particle) -> bool:
			return particle in ParticleData.FERMIONS
	)
	
	var path_finder := PathFinder.new(fermion_matrix)
	fermion_paths = path_finder.generate_paths()
	
	for fermion_path: PackedInt32Array in fermion_paths:
		fermion_string += get_fermion_path_string(fermion_path)
		
		if fermion_path != fermion_paths[-1]:
			fermion_string += ",\n"
	
	return fermion_string

func get_fermion_path_string(path: PackedInt32Array) -> String:
	var fermion_path_string: String = ""

	for i in path.size() - 1:
		var from_id: int = path[i]
		var to_id: int = path[i+1] 
		var particle: ParticleData.Particle = matrix.get_connection_particles(
			from_id, to_id
		).front()
		
		if is_bend_interaction(from_id):
			continue
		
		var connection_string := get_connection_string(from_id, to_id, particle)
		
		if (
			to_id != path[-1]
			and !(
				is_bend_interaction(to_id)
				and matrix.get_bend_path(from_id, to_id)[-1] == path[-1] 
			)
		):
			connection_string = connection_string.rsplit(' ', true, 1)[0] + ' '
		
		fermion_path_string += connection_string
	
	return fermion_path_string

func calc_centre(a: Vector2, b: Vector2, c:Vector2) -> Vector2:
	b -= a
	c -= a
	
	var A: float = 1 / (2*(c.y*b.x - b.y*c.x))
	var x2: float = A * (b.x * c.length_squared() - c.x * b.length_squared())
	
	var B: float = 1/(2*b.x)
	var x1: float = B * (b.length_squared() - 2*b.y*x2)
	
	return Vector2(x1, x2) + a

func calc_out_angle(a: Vector2, centre: Vector2) -> float:
	var b : Vector2 = centre - a
	
	return acos(b.x/b.length())

func get_lowest_x() -> int:
	var lowest_x: int = positions[0].x
	
	for position: Vector2i in positions:
		if position.x < lowest_x:
			lowest_x = position.x

	return lowest_x

func get_highest_y() -> int:
	var highest_y: int = positions[0].y
	
	for position: Vector2i in positions:
		if position.y > highest_y:
			highest_y = position.y

	return highest_y

func is_anti_connection(from_id:int, to_id:int) -> bool:
	var is_forward_connection: bool = matrix.are_interactions_connected(from_id, to_id)
	var is_right_connection: bool = positions[to_id].x >= positions[from_id].x
	
	return is_forward_connection != is_right_connection

func is_bend_interaction(id:int) -> bool:
	return matrix.is_bend_id(id) and decorations[id] == Decoration.Decor.none

func get_interaction_string(id: int) -> String:
	var interaction_string: String = ""
	
	var decoration: Decoration.Decor = decorations[id]
	var has_decor: bool = decoration != Decoration.Decor.none
	
	var is_extreme_point: bool = matrix.is_extreme_point(id)
	
	var connection_particle: ParticleData.Particle
	if is_extreme_point:
		connection_particle = matrix.get_connected_particles(id, true)[0]
		var connected_id : int = matrix.get_connected_ids(id, true)[0]
		var is_anti : bool = is_anti_connection(id, connected_id)
		
		connection_particle = connection_particle if !is_anti else ParticleData.anti(connection_particle)
	
	var label_str: String
	if has_decor:
		label_str = " {}"
	elif has_external_label(id):
		label_str = " {%s}"%edge_label(connection_particle)
	else:
		label_str = ""
	
	interaction_string += "\\vertex (i%s)%s at (%s*\\xscale, %s*\\yscale)%s;\n" % [
		id,
		" [%s]"%[Decoration.get_export_name(decoration)] if has_decor else "",
 		positions[id].x,
		positions[id].y,
		label_str
	]
	
	return interaction_string

func get_bend_angle(centre: Vector2, point: Vector2) -> float:
	var angle: float = rad_to_deg(acos((centre - point).x/(centre - point).length()))
	angle += sign((centre - point).x) * 90
	angle *= sign((centre - point).y)
	
	return clamp(angle, -90, 90)

func get_bend_connection_string(
	from_id: int, mid_id: int, to_id: int,
	particle: ParticleData.Particle,
	has_label: bool
) -> String:
	var out_vec: Vector2 = positions[mid_id] - positions[from_id]
	var in_vec: Vector2 = positions[mid_id] - positions[to_id]
	var out_angle : float = out_vec.angle()
	var in_angle : float = in_vec.angle()
	
	return (
		"(i%s) -- [%s, out = %s, in = %s%s] (i%s)"%[
			from_id,
			get_line_string([from_id, mid_id], particle),
			round(rad_to_deg(out_angle)),
			round(rad_to_deg(in_angle)),
			", edge label = %s"%[edge_label(particle)] if has_label else "",
			to_id
		]
	)

func edge_label(particle: ParticleData.Particle) -> String:
	return "\\(%s\\)"%[ParticleData.export_particle_dict[particle]]

func get_3loop_string(
	path: Array[int],
	particle: ParticleData.Particle,
	has_label: bool
	) -> String:
	var out_vec: Vector2 = Vector2(positions[path[1]])*scale - Vector2(positions[path[0]])*scale
	var in_vec: Vector2 = Vector2(positions[path[2]])*scale - Vector2(positions[path[0]])*scale
	var out_angle : float = rad_to_deg(out_vec.angle())
	var in_angle : float = rad_to_deg(in_vec.angle())
	var min_distance : float = max(out_vec.length(), in_vec.length())
	return "i%s -- [%s, out = %s, in = %s, loop, min distance = %scm,%s] i%s"%[
		path[0],
		get_line_string(path, particle),
		round(out_angle),
		round(in_angle),
		round(min_distance) * 1.5,
		", edge label = %s"%[edge_label(particle)] if has_label else "",
		path[0]
	]

func get_4loop_string(
	path: Array[int],
	particle: ParticleData.Particle,
	has_label: bool
	) -> String:
	return "(i%s) -- [%s, half left, edge label = %s] (i%s)"%[
		path[0],
		get_line_string(path, particle),
		", edge label = %s"%[edge_label(particle)] if has_label else "",
		path[2]
	] + " -- [%s, half left] (i%s)"%[
		get_line_string(path, particle),
		path[0]
	]

func get_bend_string(from_id: int, first_bend_id: int, particle: ParticleData.Particle) -> String:
	var bend_path: Array[int] = matrix.get_bend_path(from_id, first_bend_id)

	while bend_path.size() > (4 + int(bend_path.front() == bend_path.back())):
		bend_path.remove_at(randi_range(1, bend_path.size()-2))
	
	var has_label: bool = has_edge_label(from_id, bend_path[-1], particle)
	
	if bend_path.front() == bend_path.back():
		if bend_path.size() == 4:
			return get_3loop_string(bend_path, particle, has_label)
		elif bend_path.size() == 5:
			return get_4loop_string(bend_path, particle, has_label)
	
	return get_bend_connection_string(
		from_id,
		bend_path[randi_range(1, bend_path.size()-2)],
		bend_path[-1],
		particle,
		has_label
	)

func has_external_label(id: int) -> bool:
	if !draw_external_labels:
		return false
	
	if decorations[id] != Decoration.Decor.none:
		return false
		
	return matrix.is_extreme_point(id)

func has_fermion_arrow(id: int) -> bool:
	if !join_paths:
		return true
	
	for path: PackedInt32Array in fermion_paths:
		if id == path[floor((path.size() - 1) / 2)]:
			return true
	
	return false

func get_path_from_id(id: int) -> PackedInt32Array:
	return fermion_paths[ArrayFuncs.find_var(
		fermion_paths,
		func(path: PackedInt32Array) -> bool: return id in path
	)]

func has_edge_label(from_id: int, to_id: int, particle: ParticleData.Particle) -> bool:
	if matrix.is_extreme_point(from_id) || matrix.is_extreme_point(to_id):
		return false

	if !draw_internal_labels:
		return false
	
	if !join_paths:
		return true
	
	if particle not in ParticleData.FERMIONS:
		return true
	
	var path := get_path_from_id(from_id)
	if path[0] == path[-1]:
		return from_id == path[floor((path.size() - 1) / 2)]
	return false

func get_line_string(segment_ids: Array[int], particle: ParticleData.Particle) -> String:
	if !(particle in ParticleData.FERMIONS) || segment_ids.any(has_fermion_arrow):
		return "%s"%[ParticleData.export_line_dict[particle]]

	return ""

func get_direct_connection_string(from_id:int, to_id:int,particle:ParticleData.Particle) -> String:
	
	var connection_string: String = ""
	var is_right : bool = positions[to_id].x >= positions[from_id].x
	
	var label_particle: ParticleData.Particle = particle
	if !is_right:
		label_particle = ParticleData.anti(label_particle)

	var has_label: bool = has_edge_label(from_id, to_id, particle)
	
	connection_string += "(i%s) -- [%s%s] (i%s)" % [
		from_id,
		get_line_string([from_id], particle),
		", edge label = %s"%edge_label(particle) if has_label else "",
		to_id
	]
	
	return connection_string

func get_highest_hadron_id(hadron_ids:PackedInt32Array) -> int:
	var highest_id: int = hadron_ids[0]
	
	for id:int in hadron_ids:
		if positions[id] > positions[highest_id]:
			highest_id = id
	
	return highest_id

func get_lowest_hadron_id(hadron_ids:PackedInt32Array) -> int:
	var lowest_id: int = hadron_ids[0]
	
	for id:int in hadron_ids:
		if positions[id] < positions[lowest_id]:
			lowest_id = id
	
	return lowest_id

func get_hadron_particles(hadron_ids:PackedInt32Array,) -> Array[ParticleData.Particle]:
	var particles: Array[ParticleData.Particle] = []
	
	for id:int in hadron_ids:
		var to_id:int = matrix.get_connected_ids(id, true)[0]
		var particle:ParticleData.Particle = matrix.get_connected_particles(id, true)[0]
		var is_anti: bool = is_anti_connection(id, to_id)
		
		particles.push_back(particle if !is_anti else ParticleData.anti(particle))
	
	return particles

func get_hadron_string(hadron_ids:PackedInt32Array,) -> String:
	var hadron_string: String = ""
	
	var on_left: bool = matrix.get_state_from_id(hadron_ids[0]) == StateLine.State.Initial
	var label_position: String = "left" if on_left else "right"
	
	var lowest_id:int = get_lowest_hadron_id(hadron_ids)
	var highest_id:int = get_highest_hadron_id(hadron_ids)
	
	var from_id:int = lowest_id if on_left else highest_id
	var to_id:int = highest_id if on_left else lowest_id
	
	var from_position:String = "south west" if on_left else "north east"
	var to_position:String = "north west" if on_left else "south east"
	
	hadron_string += "\\draw [decoration={brace}, decorate] (i%s.%s) -- (i%s.%s)"%[
		from_id, from_position, to_id, to_position
	]
	
	var particles:Array = get_hadron_particles(hadron_ids)
	
	hadron_string += " node [pos=0.5, %s] {\\(%s\\)};\n"%[
		label_position, ParticleData.export_hadron_dict[ParticleData.find_hadron(particles)]
	]
	
	return hadron_string

func calc_positions() -> Array[Vector2i]:
	positions = matrix.normalised_interaction_positions
	
	if positions.is_empty():
		return []
	
	var lowest_x : int = get_lowest_x()
	var highest_y : int = get_highest_y()
	
	for i:int in positions.size():
		positions[i] *= Vector2i(+1, -1)
		positions[i] -= Vector2i(lowest_x, -highest_y)
	
	return positions
