extends Node

@onready var TitleDiagram : DrawingMatrix = ResourceLoader.load("res://saves/title_diagram.tres")

enum ColourScheme {TeaStain, SeaFoam, Professional}
enum COLOURS {primary, secondary, pencil, primary_highlight, invalid, invalid_highlight}
enum Scene {Level, MainMenu}
enum Vision {Colour, Shade, Strength, None}

var in_main_menu: bool = true
var load_mode: BaseMode.Mode = BaseMode.Mode.Sandbox
var creating_problem: Problem = Problem.new()
var creating_problem_set_file: String = ''
var load_problem_set: ProblemSet = ProblemSet.new()
var problem_selection_menu_position: Vector2
var problem_selection_menu_showing: bool

enum STATE_LINE {INITIAL, FINAL}

enum CURSOR {default, point, hold, snip, snipped, middle, hover, press, disabled, sampler}

const REPLACEMENT_SHADER := preload('res://Resources/Shaders/replacement_material.tres')

const MISSING_COLOUR := Color('ff1bea')

const COLOUR_SCHEMES : Array = [
	[Color('e1cba0'), Color('d1bd97'), Color('383930'), Color('e3d3c0'), Color('df3e3e'), Color('e35959')],
	[Color('FFFFFF'), Color('FFFFFF'), Color('000000'), Color('e3d3c0'), Color('df3e3e'), Color('e35959')]]


const VISION_COLOURS : Array = [
	[Color('c13e3e'), Color('3ec13e'), Color('4057be')],
	[Color('ffffff'), Color('000000'), Color('727272')]
]

@onready var PARTICLE_TEXTURES = {}

var is_on_build: bool:
	get:
		return OS.has_feature("standalone")

func _ready():
	load_problem_set.problems.push_back(creating_problem)

func get_unique_file_name(folder_path: String, suffix: String = '.txt') -> String:
	var random_hex : String = "%x" % (randi() % 4095)
	
	var files: Array[String] = get_files_in_folder(folder_path)
	
	while folder_path + random_hex + suffix in files:
		random_hex = "%x" % (randi() % 4095)
	
	return folder_path + random_hex + suffix

func create_file(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("")
	file = null

func create_text_file(data: String, path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		return
	
	create_file(path)
	
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_var(data)
	file.close()

func get_resource_save_data(resource: Resource) -> String:
	return var_to_str(resource)

func save_data(data: Resource, path: String = "res://saves/") -> Error:
	return ResourceSaver.save(data, path)

func load_data(path: String) -> Resource:
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path)
	
	return null

func save(p_obj: Resource, p_path: String) -> void:
	var file = FileAccess.open(p_path, FileAccess.WRITE)
	
	if !file: return
	
	var var_as_str: String = var_to_str(p_obj)
	
	file.store_string(var_as_str)
	file.close()

func load(p_path: String) -> Resource:
	var file = FileAccess.open(p_path, FileAccess.READ)
	var obj: Resource = str_to_var(file.get_as_text())
	file.close()
	return obj

func delete_file(path: String) -> Error:
	return DirAccess.remove_absolute(path)

func get_files_in_folder(folder_path: String) -> Array[String]:
	var files : Array[String] = []
	var dir := DirAccess.open(folder_path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(folder_path + file)

	return files

func flatten(array: Array) -> Array:
	var flat_array: Array = []
	
	for element in array:
		flat_array.append_array(element)
	
	return flat_array

func filter(array: Array, test_func: Callable) -> Array:
	var filtered_array : Array = []
	
	for element in array:
		if test_func.call(element):
			filtered_array.push_back(element)
	
	return filtered_array

func any(array: Array, test_func: Callable) -> bool:
	return array.any(test_func)

func find_var(array: Array, test_func: Callable, start_index: int = 0) -> int:
	for i in range(start_index, array.size()):
		if test_func.call(array[i]):
			return i
	
	return array.size()

func find_all_var(array: Array, test_func: Callable, start_index: int = 0) -> PackedInt32Array:
	var found_ids: PackedInt32Array = []
	
	for i in range(start_index, array.size()):
		if test_func.call(array[i]):
			found_ids.push_back(i)

	return found_ids
