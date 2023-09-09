extends Node

@onready var Level = get_tree().get_nodes_in_group('level')[0]
@onready var ColourLine = preload("res://Scenes and Scripts/Diagram/ColourLine.tscn")

var Diagram: DiagramBase
var Initial: StateLine
var Final: StateLine

const INVALID := -1

enum COLOUR {RED, GREEN, BLUE}
enum SHADE {BRIGHT, DARK, GREY}

const VISION_NAMES = ['none', 'colour', 'shade']
const SHADE_NAMES = ['bright', 'dark']

@export var print_results : bool = true

var cdiagram = AStar2D.new()
var nog_diagram = AStar2D.new()
var shade_diagram = AStar2D.new()
var g_points := []
var cinteractions := []
var shade_interactions := []

var old_ends : Array
var old_starts : Array
var old_diagram = AStar2D.new()

var showing_type = GLOBALS.VISION_TYPE.NONE: set = _set_showing_type
var counter = 0

const RGB = [Color('c13e3e'), Color('3ec13e'), Color('4057be')]
const SHADES = [Color('ffffff'), Color('000000'), Color('727272')]

var prev_paths = []
var prev_c_paths = []

func init(diagram: DiagramBase, state_lines: Array) -> void:
	Diagram = diagram
	Initial = state_lines[StateLine.StateType.Initial]
	Final = state_lines[StateLine.StateType.Final]

func _set_showing_type(new_type):
	showing_type = new_type
	
	for i in range(VISION_NAMES.size()):
		show_lines(i, i == showing_type)

func show_lines(i, is_show):
	for cl in get_tree().get_nodes_in_group(VISION_NAMES[i] + '_lines'):
		cl.visible = is_show

func set_valid_showing():
	for vision_type in range(VISION_NAMES.size()):
		if vision_type == showing_type:
			show_lines(vision_type, Level.valid())
		

func colourful(force):
	var generate_colours = false
	var generate_shade = false
	
	set_valid_showing()

	for i in get_tree().get_nodes_in_group('interactions'):
		if i.has_colour:
			generate_colours = true
		if i.has_shade:
			generate_shade = true
	
	if generate_colours:
		build_colour(force)
	if generate_shade:
		build_shade()

func build_diagram():
	var interactions := get_tree().get_nodes_in_group('interactions')
	var connections := []

	for i in interactions:
		var temp_c := []
		
		for line in i.connected_lines:
			if is_instance_valid(line):
				if line.points[0] != line.points[1]:
					temp_c.append(line.signtype)
		
		temp_c.sort()
		
		connections.append(temp_c)
	
	return connections
	
func build_non():
	var interactions := get_tree().get_nodes_in_group('interactions')
	var connections := []

	for i in range(interactions.size()):
		var temp_connections = []
		for line in interactions[i].connected_lines:
			if is_instance_valid(line):
				for In in line.get_connected_interactions():
					if In != interactions[i]:
						temp_connections.append(interactions.find(In))
		
		connections.append(temp_connections)
	
	for state in ['Initial', 'Final']:
		for joint in get_tree().get_nodes_in_group(state + 'hadron_joints'):
			for i in joint.hadron_interactions:
				for j in joint.hadron_interactions:
					if i != j:
						if interactions.find(i) != -1:
							connections[interactions.find(i)].append(interactions.find(j))
	
	if connections.size() != 0:
		return test_non(connections)
	else:
		return false

func test_non(connections : Array) -> bool:
	var reached = []
	
	counter = 0
	reached = travel(0, connections, reached)
	
	if reached == null:
		return false
	
	reached.sort()
	
	return reached == range(connections.size())

func travel(point, connections, reached):
	counter += 1
	reached.append(point)
	if connections == []:
		return []
	
	for c in connections[point]:
		if !c in reached:
			travel(c, connections, reached)
	
	if reached.size() == connections.size():
		return reached
		
	elif counter >= 100:
		return []

func test_same(connections1 : Array, connections2 : Array):
	for c in connections1:
		if !c in connections2:
			return false
	
	return true

func build_shade():
	var paths := []
	var path_colours := []
	shade_interactions = []
	
	var interactions = get_tree().get_nodes_in_group('interactions')
	
	shade_diagram.clear()
	
	for i in range(interactions.size()):
		var interaction = interactions[i]
		if interaction.has_shade:
			shade_interactions.append(interaction)
			shade_diagram.add_point(shade_diagram.get_point_count(), interaction.position)
	
	for shade in [SHADE.BRIGHT, SHADE.DARK]:
		if shade == 2:
			continue
		var new_paths = get_shade_paths(shade)
		for path in new_paths:
			path_colours.append(shade)
		paths += new_paths
	
	
	show_colours(paths, path_colours, SHADES, GLOBALS.VISION_TYPE.SHADE)

func get_shade_paths(shade : int) -> Array:
	var shaded_interactions := []
	
	var lines := get_tree().get_nodes_in_group('lines')
	
	var shade_particles : Array
	
	match shade:
		SHADE.BRIGHT:
			shade_particles = GLOBALS.BRIGHT_PARTICLES
		SHADE.DARK:
			shade_particles = GLOBALS.DARK_PARTICLES
	
	for interaction in shade_interactions:
		for line in interaction.connected_lines:
			if is_instance_valid(line):
				if line.type in shade_particles:
					shaded_interactions.append(interaction)
					break
	
	var temp_shade_diagram = duplicate_diagram(shade_diagram)
	
	for line in lines:
		if is_instance_valid(line):
			if line.type in shade_particles:
				var point1 = line.points[0]
				var point2 = line.points[1]

				if line.type == GLOBALS.Particle.W:
					match shade:
						SHADE.BRIGHT:
							temp_shade_diagram.connect_points(temp_shade_diagram.get_closest_point(point2), temp_shade_diagram.get_closest_point(point1), false)
						SHADE.DARK:
							temp_shade_diagram.connect_points(temp_shade_diagram.get_closest_point(point1), temp_shade_diagram.get_closest_point(point2), false)
				else:
					temp_shade_diagram.connect_points(temp_shade_diagram.get_closest_point(point1), temp_shade_diagram.get_closest_point(point2), false)
	
	var startend_points = get_start_end_points(shade_interactions, temp_shade_diagram)
	var start_points = startend_points[0]
	var end_points = startend_points[1]
	
	var paths = follow_diagram(temp_shade_diagram, start_points, end_points)
	
	return paths
	
func build_colour(force):
	var interactions := get_tree().get_nodes_in_group('interactions')
	cinteractions = []
	var lines := get_tree().get_nodes_in_group('lines')
	cdiagram.clear()
	nog_diagram.clear()
	
	var count = 0
	for i in range(interactions.size()):
		if interactions[i].has_colour:
			cdiagram.add_point(count, interactions[i].position, 1.0)
			nog_diagram.add_point(count, interactions[i].position, 1.0)
			cinteractions.append(interactions[i])
			count += 1
	
	g_points.resize(cdiagram.get_point_count())
	g_points.fill(0)

	for i in range(lines.size()):
		if lines[i].has_colour:
			
			var point1 = cdiagram.get_closest_point(lines[i].points[0])
			var point2 = cdiagram.get_closest_point(lines[i].points[1])
			
			if lines[i].type == GLOBALS.Particle.gluon:
				cdiagram.connect_points(point1, point2, true)
				
			else:
				cdiagram.connect_points(point1, point2, false)
				nog_diagram.connect_points(point1, point2, false)

	for i in range(lines.size()):
		if lines[i].has_colour:
			
			var point1 = cdiagram.get_closest_point(lines[i].points[0])
			var point2 = cdiagram.get_closest_point(lines[i].points[1])
			
			if lines[i].type == GLOBALS.Particle.gluon:
				g_points[point1] += 1
				g_points[point2] += 1
	
	var same = true
	if cdiagram.get_point_ids() != old_diagram.get_point_ids():
		same = false
	else:
		for p in cdiagram.get_point_ids():
			if (cdiagram.get_point_connections(p) != old_diagram.get_point_connections(p)) or (cdiagram.get_point_position(p) != old_diagram.get_point_position(p)):
				same = false
	
	var check_colourless = false
	for interaction in interactions:
		interaction.check_valid()
		if !interaction.valid_colourless:
			check_colourless = true
		elif !interaction.valid:
			check_colourless = false

	if prev_c_paths.size() == 0:
		force = true

	if (!same or force) and Level.valid:
		find_colour_paths()
	elif same and Level.valid:
		show_colours(prev_paths, prev_c_paths, RGB, GLOBALS.VISION_TYPE.COLOUR)
	elif same and !Level.valid and !check_colourless:
		get_tree().call_group('colour_lines', 'queue_free')
	elif check_colourless:
		find_colour_paths()

func find_colour_paths():
	var end_points := []
	var start_points := []
	var baryon_points := []
	var entry_baryon_points := []
	var meson_points := []
	
	for baryon in Initial.baryon_points:
		var b_p = []
		for p in baryon:
			b_p.append(cdiagram.get_closest_point(p))
		baryon_points.append(b_p)

	for baryon in Final.baryon_points:
		var b_p = []
		for p in baryon:
			b_p.append(cdiagram.get_closest_point(p))
		baryon_points.append(b_p)
	
	for baryon in Initial.entry_baryon_points:
		var b_p = []
		for p in baryon:
			b_p.append(cdiagram.get_closest_point(p))
		entry_baryon_points.append(b_p)

	for baryon in Final.entry_baryon_points:
		var b_p = []
		for p in baryon:
			b_p.append(cdiagram.get_closest_point(p))
		entry_baryon_points.append(b_p)

	for meson in Initial.meson_points:
		var b_p = []
		for p in meson:
			b_p.append(cdiagram.get_closest_point(p))
		meson_points.append(b_p)
	for meson in Final.meson_points:
		var b_p = []
		for p in meson:
			b_p.append(cdiagram.get_closest_point(p))
		meson_points.append(b_p)
	
	var startend_points = get_start_end_points(cinteractions, cdiagram)
	start_points = startend_points[0]
	end_points = startend_points[1]

	#puts gs first
	for point in start_points:
		if g_points[point] == 1:
			start_points.erase(point)
			start_points.push_front(point)
	
	var paths = follow_diagram(cdiagram, start_points, end_points)
	
	var path_colours = hadron_colour(paths, cdiagram, meson_points, baryon_points, entry_baryon_points, start_points, end_points)
			
	show_colours(paths, path_colours, RGB, GLOBALS.VISION_TYPE.COLOUR)

func get_start_end_points(interactions : Array, diagram : AStar2D) -> Array:
	var start_points := []
	var end_points := []
	
	for i in range(interactions.size()):
		if !is_instance_valid(interactions[i]):
			continue
		if interactions[i].connected_lines.size() == 1:
			end_points.append(i)
			if diagram.get_point_connections(i).size() == 1:
				start_points.append(i)
	
	return [start_points, end_points]

func duplicate_diagram(diagram : AStar2D) -> AStar2D:
	var new_diagram = AStar2D.new()
	
	for point in diagram.get_point_ids():
		new_diagram.add_point(point, diagram.get_point_position(point))
	for point in diagram.get_point_ids():
		for connection in diagram.get_point_connections(point):
			new_diagram.connect_points(point, connection, false)
	
	return new_diagram

func follow_diagram(diagram, start_points, end_points, remove_bidirectional = false):
	var paths = []
	var valid = true
	var start_time = Time.get_ticks_usec()

	for attempt in range(100):
		valid = true
		
		var tdiagram = duplicate_diagram(diagram)

		paths = []
		for s in start_points:
			var path = follow(s, end_points, tdiagram, false)
			if path == []:
				valid = false
				break
			paths.append(path)
		if !valid:
			continue

		for p in tdiagram.get_point_ids():
			if tdiagram.get_point_connections(p).size() != 0:
				var path = follow(p, end_points, tdiagram, true, remove_bidirectional)
				if path == []:
					valid = false
					break
				paths.append(path)
		if !valid:
			continue

		for p in tdiagram.get_point_ids():
			if tdiagram.get_point_connections(p).size() != 0:
				valid = false
				break
		if !valid:
			continue
		
		if valid:
			if print_results:
				print('Found correct paths in: ', attempt, ' attempt(s), which took ', Time.get_ticks_usec() - start_time, ' usec')
				print(paths)
			
			return paths
	
	if !valid:
		if print_results:
			print('Unfortunate')
			print('Took ', Time.get_ticks_usec() - start_time, ' usec')
		
		return paths

func follow(start_point, end_points, diagram, is_loop, disconnect_bidirectional = false):
	var current_id = start_point
	var path = [current_id]
	
	for step_number in range(20):
		if step_number == 0:
			current_id = step(current_id, -1, diagram)
		else:
			current_id = step(current_id, path[step_number - 1], diagram)
		
		if current_id == -1:
			return []
	
		path.append(current_id)
		
		diagram.disconnect_points(path[step_number], current_id, disconnect_bidirectional)
		
		if (current_id != start_point) and !(current_id in end_points):
			continue
		
		if !is_loop:
			return path
		
		if diagram.get_point_connections(current_id).size() == 0:
			return path
		
		print('connections')
		print(diagram.get_point_connections(current_id)[0])
		print('prev id')
		print(path[-2])
		
		if diagram.get_point_connections(current_id).size() == 1 and diagram.get_point_connections(current_id)[0] == path[-2]:
			return path
		
#˚		if randi() % diagram.get_point_connections(current_id).size() == 0:
#			return path

func step(id, prev_id, diagram):
	var connection_ids = diagram.get_point_connections(id)
	
	if prev_id in connection_ids:
		connection_ids.remove(connection_ids.find(prev_id))

	if connection_ids.size() == 0:
		return -1
	else:
		return connection_ids[randi() % connection_ids.size()]

func hadron_colour(paths, hdiagram, meson_points, baryon_points, entry_baryon_points, start_points, end_points):
	var start_time = Time.get_ticks_usec()
	
	var pc := []
	var old_path_colours := []
	var path_colours := []
	
	var nog_paths_flat_hadron = build_nog_diagram(meson_points, baryon_points, start_points, end_points)
	var nog_paths = nog_paths_flat_hadron[0]
	var flat_hadron = nog_paths_flat_hadron[1]
	
	var cc = 0
	
	var cancel = false
	
	var exit_baryon_points := []
	for baryon in baryon_points:
		if !entry_baryon_points.has(baryon):
			exit_baryon_points.append(baryon) 
	
	for attempt in range(10000):
		var valid = true
		path_colours = []
		cc = 0
		pc = []
		pc.resize(hdiagram.get_point_ids().size())
		pc.fill(-1)
		path_colours.resize(paths.size())
		path_colours.fill(-1)

		for baryon in entry_baryon_points:
			var ri = randi() % 3
			for i in range(baryon.size()):
				for j in range(paths.size()):
					var path = paths[j]
					if path[0] == baryon[i]:
						var c = (cc + ri) % 3
						pc[path[0]] = c
						pc[path[-1]] = c
						path_colours[j] = c
						cc += 1
		
		for baryon in exit_baryon_points:
			var pc_baryon = [pc[baryon[0]], pc[baryon[1]], pc[baryon[2]]]
			var ri = randi() % 3
			if -1 in pc_baryon:
				for _i in range(3):
					var c = (cc + ri) % 3
					if !(c in pc_baryon):
						var bi = pc_baryon.find(-1)
						for j in range(paths.size()):
							var path = paths[j]
							if bi != -1 and path[-1] == baryon[bi]:
								pc_baryon[bi] = c
								pc[path[0]] = c
								pc[path[-1]] = c
								path_colours[j] = c
						
					cc += 1
			pass

		for meson in meson_points:
			var ri = randi() % 3
			if pc[meson[1]] == -1 and pc[meson[0]] == -1:
				var c = (cc + ri) % 3
				for j in range(paths.size()):
					var path = paths[j]

					if (path[0] == meson[0] or path[-1] == meson[0]) or (path[0] == meson[1] or path[-1] == meson[1]):
						pc[path[0]] = c
						pc[path[-1]] = c
						path_colours[j] = c
				cc += 1

			elif pc[meson[0]] != -1:
				for j in range(paths.size()):
					var path = paths[j]
					if path[0] == meson[1]:
						pc[path[0]] = pc[meson[0]]
						pc[path[-1]] = pc[meson[0]]
						path_colours[j] = pc[meson[0]]

			elif pc[meson[1]] != -1:
				for j in range(paths.size()):
					var path = paths[j]
					if path[0] == meson[0]:
						pc[path[0]] = pc[meson[1]]
						pc[path[-1]] = pc[meson[1]]
						path_colours[j] = pc[meson[1]]

		var ri = randi() % 3
		for i in range(paths.size()):
			var path = paths[i]

			if path_colours[i] == -1:
				var c = (cc + ri) % 3
				path_colours[i] = c
				pc[path[0]] = c
				pc[path[-1]] = c
				cc += 1

		for meson in meson_points:
			if pc[meson[0]] != pc[meson[1]]:
				valid = false
				break
		if !valid:
			continue

		for baryon in baryon_points:
			var pcb = [pc[baryon[0]], pc[baryon[1]], pc[baryon[2]]]
			pcb.sort()
			if pcb != [0, 1, 2]:
				valid = false
				break
		if !valid: 
			continue
		
		path_colours = normalise_colours(path_colours)
		
		if !(path_colours in old_path_colours):
			old_path_colours.append(path_colours)
		
			for i in range(nog_paths.size()):
				var path = nog_paths[i]
				var first = path[0]
				var last = path[-1]
				if ((pc[first] == pc[last]) and (first in flat_hadron and last in flat_hadron)) or (first == last):
					var g_sum = 0
					var g_index = -1
					for point in path:
						if g_points[point] == 1:
							if point != g_index:
								g_index = point
								g_sum += 1

					if g_sum == 1:
						valid = false
		
		else:
			valid = false

		if attempt > 20:
			for i in range(nog_paths.size()):
				var path = nog_paths[i]
				var first = path[0]
				var last = path[-1]
				var g_sum = 0

				if ((pc[first] == pc[last]) and (first in flat_hadron and last in flat_hadron)) or (first == last):
					var g_index = -1
					for point in path:
						if g_points[point] == 1:
							if g_index != point:
								g_index = point
								g_sum += 1

						else:
							cinteractions[point].valid_colourless = true
							cinteractions[point].check_valid()
					
					if g_sum == 1:
						cinteractions[g_index].valid_colourless = false
						cinteractions[g_index].check_valid()
						cancel = true
					
					else:
						for point in path:
							cinteractions[point].valid_colourless = true
							cinteractions[point].check_valid()

		if cancel:
			break
		
		if !valid:
			continue

		if valid:
			if print_results:
				print('Found correct hadrons in: ', attempt, ' attempt(s), taking ', Time.get_ticks_usec() - start_time, ' usec')
				print(pc)
				print(path_colours)
			for i in get_tree().get_nodes_in_group('interactions'):
				i.valid_colourless = true
				i.check_valid()
			return path_colours
	
	if cancel:
		if print_results:
			print('Colourless to colour')
			print(pc)
		return path_colours
	
	if print_results:
		print('Failed to find hadrons')
		print(pc)
	return []

func build_nog_diagram(meson_points, baryon_points, start_points, end_points):
	var nog_start_points := []
	var nog_end_points := []
	var flat_hadron := []
	var paths := []
	for meson in meson_points:
		flat_hadron.append(meson[0])
		flat_hadron.append(meson[1])
	
	for baryon in baryon_points:
		flat_hadron.append(baryon[0])
		flat_hadron.append(baryon[1])
		flat_hadron.append(baryon[2])
	
	for point in start_points:
		if g_points[point] == 0:
			nog_start_points.append(point)
	
	for point in end_points:
		if !(point in nog_start_points) and g_points[point] == 0:
			nog_end_points.append(point) 
	
	paths = follow_diagram(nog_diagram, nog_start_points, nog_end_points)

	return [paths, flat_hadron]

func normalise_colours(path_colours):
	if path_colours.size() == 0:
		return []
	
	var r = path_colours[0]
	var g = -1
	var b = -1
	
	for c in path_colours:
		if c != r:
			g = c
			break
	
	for c in path_colours:
		if c != r and c != g:
			b = c
			break
	
	for i in range(path_colours.size()):
		var pc = path_colours[i]
		if pc == r:
			path_colours[i] = 0
		elif path_colours[i] == g:
			path_colours[i] = 1
		elif path_colours[i] == b:
			path_colours[i] = 2
	
	return path_colours

func show_colours(paths, path_colours, colours, type):
	prev_c_paths = [path_colours][0]
	prev_paths = [paths][0]
	
	get_tree().call_group(VISION_NAMES[type] + '_lines', 'queue_free')
	
	if path_colours.size() == 0:
		if print_results:
			print('No paths to show')
		return
	
	if print_results:
		print('showing colours')
		print(path_colours)
	
	var interactions : Array
	
	match type:
		GLOBALS.VISION_TYPE.COLOUR:
			set_interaction_colour(path_colours, paths)
			interactions = cinteractions
			
		GLOBALS.VISION_TYPE.SHADE:
			interactions = shade_interactions
	
	if type == GLOBALS.VISION_TYPE.COLOUR:
		set_interaction_colour(path_colours, paths)
	
	for i in range(paths.size()):
		var path = paths[i]
		var colour = colours[path_colours[i]]
		
		for p in range(path.size() - 1):
			var cl = ColourLine.instantiate()
			
			cl.add_to_group(VISION_NAMES[type] + '_lines')
			
			cl.colour = path_colours[i]
			cl.default_color = colour
			
			if type == GLOBALS.VISION_TYPE.SHADE:
				cl.default_color = Color('ffffff')
				cl.width = 5
				cl.shade = path_colours[i]
				match path_colours[i]:
					SHADE.BRIGHT:
						cl.texture = load('res://Textures/ParticlesAndLines/colour_lines/line_white.png')
					SHADE.DARK:
						cl.texture = load('res://Textures/ParticlesAndLines/colour_lines/line_black.png')
					
			if showing_type == type:
				cl.visible = true
			
			var line
			for l in get_tree().get_nodes_in_group('lines'):
				if interactions[path[p]].position in l.points and interactions[path[p+1]].position in l.points:
					line = l
					break

			cl.points[0] = interactions[path[p]].position
			cl.points[1] = interactions[path[p+1]].position
			
			
			cl.position = 3 * (cl.points[1] - cl.points[0]).orthogonal().normalized()

			if is_instance_valid(line):
				if cl.points[0] == line.points[1]:
					cl.reverse = true
				line.add_child(cl)
	
	set_valid_showing()

func set_interaction_colour(path_colours, paths):
	var path_colour_string = []
	path_colour_string.resize(path_colours.size())
	
	var colour_interactions = []
	var interactions = get_tree().get_nodes_in_group('interactions')
	
	for interaction in interactions:
		if interaction.has_colour:
			colour_interactions.append(interaction)
	
	for i in range(path_colours.size()):
		var colour = path_colours[i]
		match colour:
			COLOUR.RED:
				path_colour_string[i] = 'r'
			COLOUR.GREEN: 
				path_colour_string[i] = 'g'
			COLOUR.BLUE:
				path_colour_string[i] = 'b'
	
	for i in range(colour_interactions.size()):
		var interaction = colour_interactions[i]
		
		interaction.left_colour = ''
		interaction.right_colour = ''
		
		for j in range(paths.size()):
			var path = paths[j]
			var find_index = path.find(i)
			
			if find_index == -1:
				continue
			elif find_index == 0:
				interaction.left_colour += path_colour_string[j]
			elif find_index == path.size():
				interaction.right_colour += path_colour_string[j]
			else:
				interaction.left_colour += path_colour_string[j]
				interaction.right_colour += path_colour_string[j]
	
