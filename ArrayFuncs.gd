extends Object
class_name ArrayFuncs

static func is_vec_zero_approx(vec: Vector2) -> bool:
	return is_zero_approx(vec.x) and is_zero_approx(vec.y)

static func flatten(array: Array) -> Array:
	var flat_array: Array = []
	
	for element:Variant in array:
		flat_array.append_array(element)
	
	return flat_array

static func count_var(array: Array, test_func: Callable, start_index: int = 0) -> int:
	var count: int = 0
	
	for i:int in range(start_index, array.size()):
		if test_func.call(array[i]):
			count += 1
	
	return count

static func find_var(array: Array, test_func: Callable, start_index: int = 0) -> int:
	for i:int in range(start_index, array.size()):
		if test_func.call(array[i]):
			return i
	
	return array.size()

static func packed_int_any(array: PackedInt32Array, test_func: Callable) -> bool:
	for e:int in array:
		if test_func.call(e):
			return true
	
	return false

static func find_all_var(array: Array, test_func: Callable, start_index: int = 0) -> PackedInt32Array:
	var found_ids: PackedInt32Array = []
	
	for i:int in range(start_index, array.size()):
		if test_func.call(array[i]):
			found_ids.push_back(i)

	return found_ids
