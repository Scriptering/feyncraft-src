class_name Vision

enum {
	MAX_PATH_STEPS = 100,
	MAX_LOOP_COUNT = 100,
	MAX_RESTRICTED_HADRON_COUNT = 10,
	MAX_LOOP_ATTEMPTS = 100,
	NOT_FOUND = -1
}

enum Colour {Red, Green, Blue, None = -1}
enum Shade {Bright, Dark, Both, None}

const colours : Array[Colour] = [Colour.Red, Colour.Green, Colour.Blue]
const shades: Array[Shade] = [Shade.Bright, Shade.Dark]

const INVALID := -1
const INVALID_PATH: Array[PackedInt32Array] = [[INVALID]]

class PathData:
	func _init(
		_paths: Array[PackedInt32Array] = [],
		_path_colours: PackedInt32Array = [],
		_forced_colour_path_ids: PackedInt32Array = [],
		_unique_colour_ids: PackedInt32Array = []
	) -> void:
		
		paths = _paths
		path_colours = _path_colours
		forced_colour_path_ids = _forced_colour_path_ids
		unique_colour_ids = _unique_colour_ids
		
		if path_colours.is_empty():
			unique_colour_ids.resize(paths.size())
			unique_colour_ids.fill(-1)
			
			path_colours.resize(paths.size())
			path_colours.fill(Colour.None)
	
	func is_empty() -> bool:
		return paths.is_empty()
	
	var paths: Array[PackedInt32Array] = []
	var path_colours: PackedInt32Array = []
	var forced_colour_path_ids: PackedInt32Array = []
	var unique_colour_ids: PackedInt32Array = []

static func generate_vision_paths(
	vision: Globals.Vision,
	diagram: DrawingMatrix,
	is_vision_matrix: bool = false
) -> PathData:
	match vision:
		Globals.Vision.Colour:
			return generate_colour_paths(diagram, is_vision_matrix)
		
		Globals.Vision.Shade:
			return generate_shade_paths(diagram)
	
	return PathData.new()

static func generate_vision_matrix(
	vision: Globals.Vision,
	diagram: DrawingMatrix,
	shade: Shade = Shade.Both
) -> DrawingMatrix:
	var vision_matrix: DrawingMatrix
	
	match vision:
		Globals.Vision.Colour:
			vision_matrix = generate_colour_matrix(diagram)
		
		Globals.Vision.Shade:
			vision_matrix = generate_shade_matrix(shade, diagram)
	
	for id:int in range(vision_matrix.matrix_size):
		if vision_matrix.is_extreme_point(id) or vision_matrix.is_lonely_extreme_point(id):
			continue
		
		if vision_matrix.get_connected_count(id) == 0 or vision_matrix.get_connected_count(id, false, true) == 0:
			vision_matrix.empty_interaction(id)
	
	return vision_matrix

static func generate_shade_matrix(shade: Shade, diagram: DrawingMatrix) -> DrawingMatrix:
	var shade_matrix: DrawingMatrix = diagram.get_reduced_matrix(
		func(particle: ParticleData.Particle) -> bool:
			return particle in ParticleData.SHADE_PARTICLES[shade]
	)

	if shade == Shade.Dark or shade == Shade.Both:
		return shade_matrix
	
	for connection:Array in shade_matrix.get_all_connections():
		if connection[shade_matrix.Connection.particle] == ParticleData.Particle.W:
			shade_matrix.reverse_connection(connection)
	
	for id:int in range(shade_matrix.matrix_size):
		if (
			shade_matrix.is_extreme_point(id) or
			shade_matrix.is_lonely_extreme_point(id, shade_matrix.EntryFactor.Entry) or
			shade_matrix.is_lonely_extreme_point(id, shade_matrix.EntryFactor.Exit)
		):
			continue
		
		if shade_matrix.get_connected_count(id) == 0 or shade_matrix.get_connected_count(id, false, true) == 0:
			shade_matrix.empty_interaction(id)
	
	return shade_matrix

static func generate_shade_paths(diagram: DrawingMatrix) -> PathData:
	var paths: Array[PackedInt32Array] = []
	var path_colours: Array[Shade] = []
	
	for shade in shades:
		var shade_matrix : DrawingMatrix = generate_vision_matrix(Globals.Vision.Shade, diagram, shade)
		
		if shade_matrix.is_empty():
			continue
		
		var path_finder := PathFinder.new(shade_matrix)
		var shade_paths := path_finder.generate_paths()
		paths.append_array(shade_paths)
		
		for path in shade_paths:
			path_colours.push_back(shade)
	
	if paths.size() == 0:
		return PathData.new()
	
	return PathData.new(paths, path_colours, [])

static func generate_colour_paths(
	drawing_matrix: DrawingMatrix,
	is_vision_matrix: bool = false
) -> PathData:
	var colour_matrix: DrawingMatrix = drawing_matrix if is_vision_matrix else generate_vision_matrix(Globals.Vision.Colour, drawing_matrix)
	
	if colour_matrix.is_empty():
		return PathData.new()
	
	var path_finder := PathFinder.new(colour_matrix)
	path_finder.set_get_next_point_function(pick_next_colour_point)
	var paths: Array[PackedInt32Array] = path_finder.generate_paths()
	
	if paths.size() == 0:
		return PathData.new()

	return generate_path_colours(paths, colour_matrix)

static func _find_colourless_interactions(
	path_data: PathData,
	drawing_matrix: DrawingMatrix,
	is_vision_matrix: bool = false
) -> PackedInt32Array:
	var colourless_interactions: PackedInt32Array = []
	var colour_matrix: DrawingMatrix = drawing_matrix if is_vision_matrix else generate_vision_matrix(Globals.Vision.Colour, drawing_matrix)
	
	colourless_interactions.append_array(
		find_colourless_group_interactions(path_data.paths, colour_matrix)
	)
	colourless_interactions.append_array(
		find_colourless_hadron_interactions(
			path_data,
			colour_matrix,
			colourless_interactions
		)
	)
	
	return colourless_interactions

static func find_colourless_interactions(
	path_data: PathData,
	drawing_matrix: DrawingMatrix,
	is_vision_matrix: bool = false
) -> PackedInt32Array:
	
	var colour_matrix : DrawingMatrix = drawing_matrix.get_reduced_matrix(
		func(particle: ParticleData.Particle) -> bool:
			return particle in ParticleData.COLOUR_PARTICLES
	)
	colour_matrix.rejoin_hadrons(true)
	
	var colourless_interactions: PackedInt32Array = []
	var gluon_connections: Array = get_gluon_connections(colour_matrix)
	for gluon_connection: Array in gluon_connections:
		colourless_interactions += is_colourless_gluon(
			gluon_connection,
			colour_matrix,
			path_data
		)
	
	colourless_interactions = ArrayFuncs.packed_int_filter(
		colourless_interactions,
		colour_matrix.is_bend_id,
		true
	)
	
	return colourless_interactions

static func is_colour_exit(id: int, colour_matrix: DrawingMatrix) -> bool:
	if colour_matrix.is_lonely_extreme_point(id):
		return true
	
	if colour_matrix.is_extreme_point(id) && !colour_matrix.is_hadron(id):
		return true
	
	return false

static func is_colourless_gluon(
	gluon_connection: Array,
	colour_matrix: DrawingMatrix,
	path_data: PathData
) -> PackedInt32Array:
	

	var reached_ids_1 := colour_matrix.reach_ids(gluon_connection[0], [], true, [gluon_connection[1]])
	var reached_ids_2 := colour_matrix.reach_ids(gluon_connection[1], [], true, [gluon_connection[0]])
	
	for id:int in reached_ids_1:
		if id in reached_ids_2:
			return []
		
	var colourless_interactions: PackedInt32Array = []
	
	if !ArrayFuncs.packed_int_any(
		reached_ids_1,
		is_colour_exit.bind(colour_matrix)
	):
		colourless_interactions.push_back(gluon_connection[0])
	
	if !ArrayFuncs.packed_int_any(
		reached_ids_2,
		is_colour_exit.bind(colour_matrix)
	):
		colourless_interactions.push_back(gluon_connection[1])

	return colourless_interactions

static func path_has_repeated_point(path: PackedInt32Array) -> bool:
	for point:int in path:
		if path.count(point) > 1:
			return true
	
	return false

static func find_colourless_hadron_interactions(
	path_data: PathData,
	vision_matrix: DrawingMatrix,
	colourless_group_interactions: PackedInt32Array = []
) -> PackedInt32Array:
	
	var colourless_hadron_interactions: PackedInt32Array = []
	var hadrons : Array = vision_matrix.split_hadron_ids
	hadrons = hadrons.filter(
		func(hadron: PackedInt32Array) -> bool:
			return is_hadron_in_paths(hadron, path_data.paths)
	)
	
	if hadrons.size() == 0:
		return colourless_hadron_interactions
	
	var quark_matrix: DrawingMatrix = vision_matrix.get_reduced_matrix(
		func(particle: ParticleData.Particle) -> bool: 
			return particle in ParticleData.QUARKS
	)
	
	var path_finder := PathFinder.new(quark_matrix)
	path_finder.set_get_next_point_function(pick_next_colour_point)
	var quark_paths: Array[PackedInt32Array] = path_finder.generate_paths()
	
	for hadron:PackedInt32Array in hadrons:
		var colourless_hadron_interaction: int = find_colourless_hadron_interaction(
			hadron, 
			ArrayFuncs.flatten(hadrons),
			quark_paths,
			path_data,
			vision_matrix,
			colourless_group_interactions
		)
		
		if colourless_hadron_interaction == NOT_FOUND:
			continue
		
		colourless_hadron_interactions.push_back(colourless_hadron_interaction)
	
	return colourless_hadron_interactions

static func get_quark_path_gluon_points(
	quark_path: PackedInt32Array, vision_matrix: DrawingMatrix, _colourless_group_interactions: PackedInt32Array = []
) -> PackedInt32Array:
	var gluon_points: PackedInt32Array = []
	
	for point:int in quark_path:
		for connected_id in vision_matrix.get_connected_ids(point):
			if vision_matrix.are_interactions_connected(point, connected_id, false, ParticleData.Particle.gluon):
				gluon_points.push_back(point)

	return gluon_points

static func get_all_paths_from_id(id: int, paths: Array[PackedInt32Array]) -> PackedInt32Array:
	return ArrayFuncs.find_all_var(
		paths,
		func(path: PackedInt32Array) -> bool:
			return id in path
	)

static func find_colourless_hadron_interaction(
	hadron: PackedInt32Array,
	hadron_ids: PackedInt32Array,
	quark_paths: Array[PackedInt32Array],
	path_data: PathData,
	vision_matrix: DrawingMatrix,
	_colourless_group_interactions: PackedInt32Array = [],
) -> int:
	
	var gluon_ids: PackedInt32Array = []
	var counted_quark_paths: PackedInt32Array = []
	
	for hadron_point:int in hadron:
		var quark_path_id: int = get_path_from_id(hadron_point, quark_paths)
		var quark_path: PackedInt32Array = quark_paths[quark_path_id]
		
		if quark_path_id in counted_quark_paths:
			continue
		
		counted_quark_paths.push_back(quark_path_id)
		
		if (
			get_colour_from_id(quark_path[0], path_data)
			!= get_colour_from_id(quark_path[-1], path_data)
		):
			return NOT_FOUND
		
		if !(quark_path[0] in hadron_ids and quark_path[-1] in hadron_ids):
			return NOT_FOUND
		
		var path_idA: int = get_path_from_id(quark_path[0], path_data.paths)
		var path_idB: int = get_path_from_id(quark_path[-1], path_data.paths)
		
		if !ArrayFuncs.packed_int_any(
			path_data.paths[path_idA],
			func(id: int) -> bool:
				return id in path_data.paths[path_idB]
		):
			return NOT_FOUND
		
		if path_data.unique_colour_ids[path_idA] != path_data.unique_colour_ids[path_idB]:
			return NOT_FOUND
		
		gluon_ids.append_array(get_quark_path_gluon_points(quark_paths[quark_path_id], vision_matrix))
	
	if gluon_ids.size() != 1:
		return NOT_FOUND
	
	return gluon_ids[0]

static func find_colourless_group_interactions(paths: Array[PackedInt32Array], vision_matrix: DrawingMatrix) -> PackedInt32Array:
	var colourless_group_interactions: PackedInt32Array = []
	
	for path:PackedInt32Array in paths:
		var colourless_group_interaction: int = find_colourless_group_interaction(path, vision_matrix)
		
		if colourless_group_interaction == NOT_FOUND:
			continue
		
		colourless_group_interactions.push_back(colourless_group_interaction)
	
	return colourless_group_interactions

static func get_repeated_points_in_path(path: PackedInt32Array) -> PackedInt32Array:
	var repeated_points: PackedInt32Array = []
	
	for point:int in path:
		if path.count(point) > 1 and point not in repeated_points:
			repeated_points.push_back(point)
	
	return repeated_points

static func find_colourless_group_interaction(path: PackedInt32Array, vision_matrix: DrawingMatrix) -> int:
	var repeated_points: PackedInt32Array = get_repeated_points_in_path(path)
	
	if repeated_points.size() < 2:
		return NOT_FOUND
	
	var test_index: int = ArrayFuncs.find_var(
		repeated_points,
		func(point: int) -> bool:
			return vision_matrix.get_connected_ids(point, true).size() > 2,
		1
	)
	
	if test_index == repeated_points.size():
		return NOT_FOUND
	
	var test_point: int = repeated_points[test_index]

	var test_vision_matrix: DrawingMatrix = vision_matrix.duplicate(true)
	test_vision_matrix.disconnect_interactions(repeated_points[test_index-1], repeated_points[test_index], ParticleData.Particle.gluon, true)

	for reached_point:int in test_vision_matrix.reach_ids(test_point, [], true):
		if reached_point == test_point:
			continue
		
		if test_vision_matrix.is_extreme_point(reached_point) or test_vision_matrix.is_lonely_extreme_point(reached_point):
			return NOT_FOUND

	return test_point

static func generate_path_colours(
	paths: Array[PackedInt32Array],
	colour_matrix: DrawingMatrix
) -> PathData:
	
	var path_data := PathData.new(paths)
	
	path_data = colour_hadrons(path_data, colour_matrix)
	path_data = colour_other_paths(path_data)

	return path_data

static func colour_other_paths(path_data: PathData) -> PathData:
	for path_id in range(path_data.path_colours.size()):
		if path_data.path_colours[path_id] != Colour.None:
			continue
		
		path_data.path_colours[path_id] = get_least_used_colour(path_data.path_colours)
	
	return path_data

static func is_hadron_restricted(
	hadron: PackedInt32Array,
	path_data: PathData
) -> bool:
	return get_hadron_colours(hadron, path_data).count(Colour.None) == 1

static func colour_hadron(
	hadron: PackedInt32Array,
	path_data: PathData
) -> PathData:
	if hadron.size() == 2:
		path_data = colour_meson(hadron, path_data)
	else:
		path_data = colour_baryon(hadron, path_data)
	
	return path_data

static func is_hadron_in_paths(
	hadron: PackedInt32Array,
	paths: Array[PackedInt32Array]
) -> bool:
	for hadron_id in hadron:
		if get_path_from_id(hadron_id, paths) == paths.size():
			return false
	
	return true

static func colour_hadrons(
	path_data: PathData,
	colour_matrix: DrawingMatrix
) -> PathData:
	var entry_baryons: Array = colour_matrix.get_entry_baryons()
	var exit_baryons: Array = colour_matrix.get_exit_baryons()
	var mesons: Array = colour_matrix.get_mesons()
	var hadrons: Array = entry_baryons + exit_baryons + mesons
	hadrons = hadrons.filter(
		func(hadron: PackedInt32Array) -> bool:
			return is_hadron_in_paths(hadron, path_data.paths)
	)
	
	for hadron:PackedInt32Array in hadrons:
		path_data = colour_hadron(hadron, path_data)
		
		for i:int in range(MAX_RESTRICTED_HADRON_COUNT):
			var restricted_hadron_index : int = (
				ArrayFuncs.find_var(
					hadrons,
					func(test_hadron: PackedInt32Array) -> bool:
						return is_hadron_restricted(test_hadron, path_data)
			))
			
			if restricted_hadron_index == hadrons.size():
				break
			
			colour_hadron(hadrons[restricted_hadron_index], path_data)
		
		if !ArrayFuncs.packed_int_any(
			path_data.path_colours,
			func(colour: Colour) -> bool:
				return colour == Colour.None
		):
			break
	
	return path_data

static func get_path_from_id(id:int, paths: Array[PackedInt32Array]) -> int:
	return ArrayFuncs.find_var(
		paths,
		func(path: PackedInt32Array) -> bool:
			return id in path
	)

static func get_colour_from_id(id: int, path_data: PathData) -> Colour:
	return path_data.path_colours[get_path_from_id(id, path_data.paths)]

static func get_hadron_colours(hadron: Array, path_data: PathData) -> Array[Colour]:
	var hadron_colours: Array[Colour] = []
	
	for hadron_point:int in hadron:
		hadron_colours.push_back(get_colour_from_id(hadron_point, path_data))
	
	return hadron_colours

static func no_colour_count(colours: Array[Colour]) -> int:
	var count: int = 0
	for colour:Colour in colours:
		count += int(colour == Colour.None)
	return count

static func colour_baryon(baryon: Array, path_data: PathData) -> PathData:
	var used_colours := get_hadron_colours(baryon, path_data)
	
	if no_colour_count(used_colours) == 3:
		var unique_id: int = ArrayFuncs.packed_int_max(path_data.unique_colour_ids) + 1
		for baryon_point:int in baryon:
			var path_id: int = get_path_from_id(baryon_point, path_data.paths)
			path_data.unique_colour_ids[path_id] = unique_id
	elif no_colour_count(used_colours) == 1:
		var colour_ids := ArrayFuncs.find_all_var(
			used_colours, func(colour:Colour) -> bool: return colour != Colour.None
		)
		var no_colour_id: int = used_colours.find(Colour.None)
		
		if (
			path_data.unique_colour_ids[get_path_from_id(baryon[colour_ids[0]], path_data.paths)]
			== path_data.unique_colour_ids[get_path_from_id(baryon[colour_ids[1]], path_data.paths)]
		):
			path_data.unique_colour_ids[get_path_from_id(baryon[no_colour_id], path_data.paths)] = (
				path_data.unique_colour_ids[get_path_from_id(baryon[colour_ids[0]], path_data.paths)]
			)
		
	
	if !used_colours.any(
		func(colour: Colour) -> bool: 
			return colour == Colour.None
	):
		return path_data
	
	for baryon_point:int in baryon:
		if get_colour_from_id(baryon_point, path_data) != Colour.None:
			continue
		var next_colour: Colour = colours[
			ArrayFuncs.find_var(
				colours,
				func(colour: Colour) -> bool:
					return colour not in used_colours
		)]
		
		used_colours[baryon.find(baryon_point)] = next_colour
		path_data.path_colours[get_path_from_id(baryon_point, path_data.paths)] = next_colour

	return path_data

static func get_least_used_colour(path_colours: Array[Colour]) -> Colour:
	var least_used_colour: Colour = Colour.Red
	var lowest_count: int = path_colours.count(Colour.Red)
	
	for colour in colours:
		if path_colours.count(colour) < lowest_count:
			lowest_count = path_colours.count(colour)
			least_used_colour = colour
	
	return least_used_colour

static func colour_meson(meson: Array, path_data: PathData) -> PathData:
	var meson_colours := get_hadron_colours(meson, path_data)
	if no_colour_count(meson_colours) == 2:
		var unique_id: int = ArrayFuncs.packed_int_max(path_data.unique_colour_ids) + 1
		for meson_point:int in meson:
			var path_id: int = get_path_from_id(meson_point, path_data.paths)
			path_data.unique_colour_ids[path_id] = unique_id
	elif no_colour_count(meson_colours) == 1:
		var no_colour_id: int = meson_colours.find(Colour.None)
		
		path_data.unique_colour_ids[get_path_from_id(meson[no_colour_id], path_data.paths)] = (
			path_data.unique_colour_ids[get_path_from_id(meson[(no_colour_id + 1) % 2], path_data.paths)]
		)

	for i:int in meson.size():
		if meson_colours[i] == Colour.None:
			continue
		
		var path_id := get_path_from_id(
			meson[(i + 1) % meson.size()],
			path_data.paths
		)
		
		path_data.path_colours[path_id] = meson_colours[i]
		
		return path_data
	
	var meson_colour: Colour = get_least_used_colour(path_data.path_colours)
	for meson_point:int in meson:
		var path_id: int = get_path_from_id(meson_point, path_data.paths)
		
		path_data.path_colours[path_id] = meson_colour
		path_data.forced_colour_path_ids.push_back(path_id)

	return path_data

static func get_gluon_connections(colour_matrix: DrawingMatrix) -> Array:
	var gluon_connections: Array = []
	for id:int in colour_matrix.matrix_size:
		for connected_id:int in colour_matrix.get_connected_ids(id):
			if colour_matrix.get_connection_particles(id, connected_id).front() == ParticleData.Particle.gluon:
				gluon_connections.push_back([connected_id, id, ParticleData.Particle.gluon])
	
	return gluon_connections

static func generate_colour_matrix(drawing_matrix: DrawingMatrix) -> DrawingMatrix:
	var colour_matrix : DrawingMatrix = drawing_matrix.get_reduced_matrix(
		func(particle: ParticleData.Particle) -> bool:
			return particle in ParticleData.COLOUR_PARTICLES
	)
	
	var gluon_connections: Array = get_gluon_connections(colour_matrix)
	for gluon_connection:Array in gluon_connections:
		colour_matrix.insert_connection(gluon_connection)
	
	return colour_matrix

static func pick_next_colour_point(
	current_point: int,
	available_points: PackedInt32Array,
	connections: DrawingMatrix,
	path: PackedInt32Array
) -> int:
	
	var gluon_points: PackedInt32Array = []
	
	if available_points.size() == 0:
		return NOT_FOUND
	#return available_points[randi() % available_points.size()]

	for available_point:int in available_points:
		if ParticleData.Particle.gluon in connections.get_connection_particles(current_point, available_point, false, true):
			gluon_points.push_back(available_point)
	
	if gluon_points.size() == 0:
		return available_points[randi() % available_points.size()]
	
	#if path[0] in available_points:
		#if randf() < .5:
			#return path[0]
	
	var most_connections: int = 0
	var highest_connection_gluon_point: int = -1
	for gluon_point:int in gluon_points:
		var connection_size: int = connections.get_connection_size(current_point, gluon_point, true)
		if connection_size > most_connections:
			highest_connection_gluon_point = gluon_point
			most_connections = connection_size
	
	return highest_connection_gluon_point
