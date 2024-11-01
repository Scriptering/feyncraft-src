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

static func generate_vision_paths(vision: Globals.Vision, diagram: DrawingMatrix, is_vision_matrix: bool = false) -> Array:
	match vision:
		Globals.Vision.Colour:
			return generate_colour_paths(diagram, is_vision_matrix)
		
		Globals.Vision.Shade:
			return generate_shade_paths(diagram)
	
	return []

static func generate_vision_matrix(vision: Globals.Vision, diagram: DrawingMatrix, shade: Shade = Shade.Both) -> DrawingMatrix:
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

static func generate_shade_paths(diagram: DrawingMatrix) -> Array:
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
		return []
	
	return [paths, path_colours]

static func generate_colour_paths(drawing_matrix: DrawingMatrix, is_vision_matrix: bool = false) -> Array:
	var colour_matrix: DrawingMatrix = drawing_matrix if is_vision_matrix else generate_vision_matrix(Globals.Vision.Colour, drawing_matrix)
	
	if colour_matrix.is_empty():
		return []
	
	var path_finder := PathFinder.new(colour_matrix)
	path_finder.set_get_next_point_function(pick_next_colour_point)
	var paths: Array[PackedInt32Array] = path_finder.generate_paths()
	
	if paths.size() == 0:
		return []
	
	var path_colours: Array[Colour] = generate_path_colours(paths, colour_matrix)
	
	return [paths, path_colours]

static func find_colourless_interactions(
	paths: Array[PackedInt32Array], path_colours: Array[Colour], drawing_matrix: DrawingMatrix, is_vision_matrix: bool = false
) -> PackedInt32Array:
	var colourless_interactions: PackedInt32Array = []
	var colour_matrix: DrawingMatrix = drawing_matrix if is_vision_matrix else generate_vision_matrix(Globals.Vision.Colour, drawing_matrix)
	
	colourless_interactions.append_array(find_colourless_group_interactions(paths, colour_matrix))
	colourless_interactions.append_array(find_colourless_hadron_interactions(paths, path_colours, colour_matrix, colourless_interactions))
	
	return colourless_interactions

static func path_has_repeated_point(path: PackedInt32Array) -> bool:
	for point:int in path:
		if path.count(point) > 1:
			return true
	
	return false

static func find_colourless_hadron_interactions(
	paths: Array[PackedInt32Array], path_colours: Array[Colour], vision_matrix: DrawingMatrix,
	colourless_group_interactions: PackedInt32Array = []
) -> PackedInt32Array:
	
	var colourless_hadron_interactions: PackedInt32Array = []
	var hadrons : Array = vision_matrix.split_hadron_ids
	hadrons = hadrons.filter(
		func(hadron: PackedInt32Array) -> bool:
			return is_hadron_in_paths(hadron, paths)
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
			hadron, ArrayFuncs.flatten(hadrons), quark_paths, paths, path_colours, vision_matrix, colourless_group_interactions
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

static func find_colourless_hadron_interaction(
	hadron: PackedInt32Array, hadron_ids: PackedInt32Array, quark_paths: Array[PackedInt32Array], paths: Array[PackedInt32Array],
	path_colours: Array[Colour], vision_matrix: DrawingMatrix, _colourless_group_interactions: PackedInt32Array = [],
) -> int:
	
	var gluon_ids: PackedInt32Array = []
	var counted_quark_paths: PackedInt32Array = []
	
	for hadron_point:int in hadron:
		var quark_path_id: int = get_path_from_id(hadron_point, quark_paths)
		
		if quark_path_id in counted_quark_paths:
			continue
		
		counted_quark_paths.push_back(quark_path_id)
		
		if get_colour_from_id(hadron_point, path_colours, paths) != get_colour_from_id(quark_paths[quark_path_id][-1], path_colours, paths):
			return NOT_FOUND
		
		if quark_paths[quark_path_id][0] not in hadron_ids or quark_paths[quark_path_id][-1] not in hadron_ids:
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

static func generate_path_colours(paths: Array[PackedInt32Array], colour_matrix: DrawingMatrix) -> Array[Colour]:
	var path_colours: Array[Colour] = []
	path_colours.resize(paths.size())
	path_colours.fill(Colour.None)
	
	path_colours = colour_hadrons(path_colours, paths, colour_matrix)
	path_colours = colour_other_paths(path_colours)

	return path_colours

static func colour_other_paths(path_colours: Array[Colour]) -> Array[Colour]:
	for path_id in range(path_colours.size()):
		if path_colours[path_id] != Colour.None:
			continue
		
		path_colours[path_id] = get_least_used_colour(path_colours)
	
	return path_colours

static func is_hadron_restricted(hadron: PackedInt32Array, path_colours: Array[Colour], paths: Array[PackedInt32Array]) -> bool:
	return get_hadron_colours(hadron, path_colours, paths).count(Colour.None) == 1
	
#	return (
#		get_hadron_colours(hadron, path_colours, paths).any(func(colour: Colour) -> bool: return colour != Colour.None) and
#		get_hadron_colours(hadron, path_colours, paths).any(func(colour: Colour) -> bool: return colour == Colour.None)
#	)

static func colour_hadron(hadron: PackedInt32Array, path_colours: Array[Colour], paths: Array[PackedInt32Array]) -> Array[Colour]:
	if hadron.size() == 2:
		path_colours = colour_meson(hadron, path_colours, paths)
	else:
		path_colours = colour_baryon(hadron, path_colours, paths)
	
	return path_colours

static func is_hadron_in_paths(hadron: PackedInt32Array, paths: Array[PackedInt32Array]) -> bool:
	for hadron_id in hadron:
		if get_path_from_id(hadron_id, paths) == paths.size():
			return false
	
	return true

static func colour_hadrons(path_colours: Array[Colour], paths: Array[PackedInt32Array], colour_matrix: DrawingMatrix) -> Array[Colour]:
	var entry_baryons: Array = colour_matrix.get_entry_baryons()
	var exit_baryons: Array = colour_matrix.get_exit_baryons()
	var mesons: Array = colour_matrix.get_mesons()
	var hadrons: Array = entry_baryons + exit_baryons + mesons
	hadrons = hadrons.filter(
		func(hadron: PackedInt32Array) -> bool:
			return is_hadron_in_paths(hadron, paths)
	)
	
	for hadron:PackedInt32Array in hadrons:
		path_colours = colour_hadron(hadron, path_colours, paths)
		
		for i:int in range(MAX_RESTRICTED_HADRON_COUNT):
			var restricted_hadron_index : int = (
				ArrayFuncs.find_var(
					hadrons,
					func(test_hadron: PackedInt32Array) -> bool:
						return is_hadron_restricted(test_hadron, path_colours, paths)
			))
			
			if restricted_hadron_index == hadrons.size():
				break
			
			colour_hadron(hadrons[restricted_hadron_index], path_colours, paths)
		
		if !path_colours.any(
			func(colour: Colour) -> bool:
				return colour == Colour.None
		):
			break
	
	return path_colours

static func get_path_from_id(id:int, paths: Array[PackedInt32Array]) -> int:
	return ArrayFuncs.find_var(
		paths,
		func(path: PackedInt32Array) -> bool:
			return id in path
	)

static func get_colour_from_id(id: int, path_colours: Array[Colour], paths: Array[PackedInt32Array]) -> Colour:
	return path_colours[get_path_from_id(id, paths)]

static func get_hadron_colours(hadron: Array, path_colours: Array[Colour], paths: Array[PackedInt32Array]) -> Array[Colour]:
	var hadron_colours: Array[Colour] = []
	
	for hadron_point:int in hadron:
		hadron_colours.push_back(get_colour_from_id(hadron_point, path_colours, paths))
	
	return hadron_colours

static func colour_baryon(baryon: Array, path_colours: Array[Colour], paths: Array[PackedInt32Array]) -> Array[Colour]:
	var used_colours: Array[Colour] = get_hadron_colours(baryon, path_colours, paths)
	
	if !used_colours.any(
		func(colour: Colour) -> bool: 
			return colour == Colour.None
	):
		return path_colours
	
	for baryon_point:int in baryon:
		if get_colour_from_id(baryon_point, path_colours, paths) != Colour.None:
			continue
		
		var next_colour: Colour = colours[
			ArrayFuncs.find_var(
				colours,
				func(colour: Colour) -> bool:
					return colour not in used_colours
		)]
		
		used_colours[baryon.find(baryon_point)] = next_colour
		path_colours[get_path_from_id(baryon_point, paths)] = next_colour

	return path_colours

static func get_least_used_colour(path_colours: Array[Colour]) -> Colour:
	var least_used_colour: Colour = Colour.Red
	var lowest_count: int = path_colours.count(Colour.Red)
	
	for colour in colours:
		if path_colours.count(colour) < lowest_count:
			lowest_count = path_colours.count(colour)
			least_used_colour = colour
	
	return least_used_colour

static func colour_meson(meson: Array, path_colours: Array[Colour], paths: Array[PackedInt32Array]) -> Array[Colour]:
	var meson_colours: Array[Colour] = get_hadron_colours(meson, path_colours, paths)
	
	for i:int in meson.size():
		if meson_colours[i] == Colour.None:
			continue
		
		path_colours[get_path_from_id(meson[(i + 1) % meson.size()], paths)] = meson_colours[i]
		
		return path_colours
	
	var meson_colour: Colour = get_least_used_colour(path_colours)
	for meson_point:int in meson:
		path_colours[get_path_from_id(meson_point, paths)] = meson_colour

	return path_colours

static func generate_colour_matrix(drawing_matrix: DrawingMatrix) -> DrawingMatrix:
	var colour_matrix : DrawingMatrix = drawing_matrix.get_reduced_matrix(
		func(particle: ParticleData.Particle) -> bool:
			return particle in ParticleData.COLOUR_PARTICLES
	)
	
	var gluon_connections: Array = []
	for id:int in colour_matrix.matrix_size:
		for connected_id:int in colour_matrix.get_connected_ids(id):
			if colour_matrix.get_connection_particles(id, connected_id).front() == ParticleData.Particle.gluon:
				gluon_connections.push_back([connected_id, id, ParticleData.Particle.gluon])
	
	for gluon_connection:Array in gluon_connections:
		colour_matrix.insert_connection(gluon_connection)
	
	return colour_matrix

static func pick_next_colour_point(current_point: int, available_points: PackedInt32Array, connections: DrawingMatrix) -> int:
	var gluon_points: PackedInt32Array = []
	
	if available_points.size() == 0:
		return NOT_FOUND

	for available_point:int in available_points:
		if ParticleData.Particle.gluon in connections.get_connection_particles(current_point, available_point, false, true):
			gluon_points.push_back(available_point)
	
	if gluon_points.size() == 0:
		return available_points[randi() % available_points.size()]
	
	var most_connections: int = 0
	var highest_connection_gluon_point: int = -1
	for gluon_point:int in gluon_points:
		var connection_size: int = connections.get_connection_size(current_point, gluon_point, true)
		if connection_size > most_connections:
			highest_connection_gluon_point = gluon_point
			most_connections = connection_size
	
	return highest_connection_gluon_point
