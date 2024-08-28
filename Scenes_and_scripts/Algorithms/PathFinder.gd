extends Node
class_name PathFinder

enum {
	MAX_PATH_STEPS = 100,
	MAX_LOOP_COUNT = 100,
	MAX_LOOP_ATTEMPTS = 100,
	NOT_FOUND = -1,
	INVALID = -2
}

const INVALID_PATH: Array[PackedInt32Array] = [[INVALID]]

var get_next_point: Callable = func(
	_current_point: int,
	available_points: Array[int],
	_matrix: DrawingMatrix
	) -> int:
		return available_points[randi() % available_points.size()]

var connections: DrawingMatrix

func _init(_connections: DrawingMatrix) -> void:
	connections = _connections.duplicate(true)

func set_get_next_point_function(new_func: Callable) -> void:
	get_next_point = new_func

func generate_paths() -> Array[PackedInt32Array]:
	var paths: Array[PackedInt32Array] = []
	
	paths.append_array(generate_state_paths())
	
	for _attempt in MAX_LOOP_ATTEMPTS:
		var loops: Array[PackedInt32Array] = generate_loops()
		
		if loops == INVALID_PATH:
			continue
		
		paths.append_array(loops)
		break
	
	return paths

func generate_state_paths() -> Array[PackedInt32Array]:
	var start_points: PackedInt32Array = connections.get_entry_points()
	start_points.append_array(connections.get_lonely_entry_points())
	
	var end_points: PackedInt32Array = connections.get_exit_points()
	end_points.append_array(connections.get_lonely_exit_points())
	
	var paths: Array[PackedInt32Array] = []
	
	for start_point:int in start_points:
		var new_path: PackedInt32Array = generate_path(start_point, end_points)
		
		if new_path.size() == 0:
			continue
			
		paths.push_back(new_path)
	
	return paths

func generate_loops(matrix: DrawingMatrix = connections.duplicate(true)) -> Array[PackedInt32Array]:
	
	var paths: Array[PackedInt32Array] = []
	
	for _loop in range(MAX_LOOP_COUNT):
		var start_point: int =  matrix.find_first_state_id(
			func(id: int) -> bool:
				var connected_count: int = matrix.get_connected_count(id, true)
				return connected_count > 0 and connected_count < 3,
			StateLine.State.None
		)
		
		if start_point == matrix.matrix_size:
			start_point = matrix.find_first_state_id(
				func(id: int) -> bool:
					return matrix.get_connected_count(id, true) > 0,
				StateLine.State.None
			)
		
		if start_point == matrix.matrix_size:
			return paths
		
		var new_path : PackedInt32Array = generate_path(start_point, [start_point], matrix)
		
		if new_path.size() == 0:
			return INVALID_PATH
		
		paths.push_back(new_path)
	
	return INVALID_PATH

func get_available_points(current_point: int, path: PackedInt32Array, matrix: DrawingMatrix) -> PackedInt32Array:
	var available_points: PackedInt32Array = matrix.get_connected_ids(current_point)
	var temp_available_points: PackedInt32Array = available_points.duplicate()
	
	for available_point:int in temp_available_points:
		if path.size() < 2:
			continue
		
		var is_previous_point: bool = available_point == path[-2]
		var is_u_turn_gluon: bool = (
			current_point == path[1] and 
			available_point == path[0] and 
			matrix.get_state_from_id(path[0]) == StateLine.State.None and
			!matrix.is_lonely_extreme_point(path[0])
		)
		
		if is_previous_point or is_u_turn_gluon:
			available_points.remove_at(available_points.find(available_point))
			
	return available_points

func generate_path(
	start_point: int,
	end_points: PackedInt32Array,
	matrix: DrawingMatrix = connections
) -> PackedInt32Array:
	
	var path: PackedInt32Array = []
	var current_point: int = start_point
	
	for step in MAX_PATH_STEPS:
		path.push_back(current_point)
		
		if current_point in end_points and step != 0:
			return path
		
		var available_points: PackedInt32Array = get_available_points(current_point, path, matrix)
		var next_point: int = get_next_point.call(current_point, available_points, matrix)
		
		if next_point == NOT_FOUND:
			return []
		
		var connection: Array = [
			current_point, next_point, matrix.get_connection_particles(current_point, next_point, false, true).front()
		]
		
		matrix.remove_connection(connection)
		current_point = next_point
	
	return []
