extends Node

@onready var TitleDiagram : DrawingMatrix = ResourceLoader.load("res://saves/Diagrams/title_diagram.tres")

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

enum Cursor {default, point, hold, snip, snipped, middle, hover, press, disabled, confused, loving}

const VISION_COLOURS : Array = [
	[Color('c13e3e'), Color('3ec13e'), Color('4057be')],
	[Color('ffffff'), Color('000000'), Color('727272')]
]

@onready var PARTICLE_TEXTURES = {}

var is_on_editor: bool

func _ready():
	is_on_editor = OS.has_feature("editor")
	load_problem_set.problems.push_back(creating_problem)
	
	if !is_on_editor and !DirAccess.dir_exists_absolute("User://saves/"):
		create_save_folders()
		
		if !FileAccess.file_exists("user://saves/ProblemSets/Default/electromagnetic.txt"):
			create_default_problem_sets()


func create_save_folders() -> void:
	print("creating save folders")
	
	print(DirAccess.make_dir_absolute("user://saves/"))
	print(DirAccess.make_dir_absolute("user://saves/Palettes"))
	print(DirAccess.make_dir_absolute("user://saves/Palettes/Custom"))
	print(DirAccess.make_dir_absolute("user://saves/ProblemSets"))
	print(DirAccess.make_dir_absolute("user://saves/ProblemSets/Custom"))
	print(DirAccess.make_dir_absolute("user://saves/ProblemSets/Default"))

func create_default_problem_sets() -> void:
	for file_path in get_files_in_folder("res://saves/ProblemSets/Default/"):
		var default_file = FileAccess.open(file_path, FileAccess.READ)
		create_text_file(
			default_file.get_as_text(), "user://saves/ProblemSets/Default/" + file_path.trim_prefix("res://saves/ProblemSets/Default/")
		)
		default_file.close()
	
	await get_tree().process_frame
	
	print(get_files_in_folder("user://saves/ProblemSets/Default/"))

func is_on_mobile() -> bool:
	return OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("android") or OS.has_feature("ios")

func get_unique_file_name(folder_path: String, suffix: String = '.txt') -> String:
	print("getting unique file name")
	print(folder_path)
	
	var random_hex : String = "%x" % (randi() % 4095)
	
	var files: Array[String] = get_files_in_folder(folder_path)
	
	while folder_path + random_hex + suffix in files:
		random_hex = "%x" % (randi() % 4095)
	
	print(folder_path + random_hex + suffix)
	
	return folder_path + random_hex + suffix

func create_file(path: String) -> void:
	print("creating file")
	print(path)
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	print(file.get_error())
	file.store_string("")
	file = null

func create_text_file(data: String, path: String) -> void:
	print("creating text file")
	print(path)
	
	if DirAccess.dir_exists_absolute(path):
		return
	
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	print(file.get_error())
	file.store_string(data)
	file.close()

func get_resource_save_data(resource: Resource) -> String:
	return var_to_str(resource)

func load_data(path: String) -> Resource:
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path)
	
	return null

func get_file_prefix() -> String:
	if OS.has_feature("web"):
		return "user://"
	
	return "res://"

func save(p_obj: Resource, p_path: String) -> void:
	var file = FileAccess.open(p_path, FileAccess.WRITE)
	
	if !file: return
	
	var var_as_str: String = var_to_str(p_obj)
	
	file.store_string(var_as_str)
	file.close()

func load_txt(p_path: String) -> Resource:
	print("loading txt")
	print(p_path)
	var file = FileAccess.open(p_path, FileAccess.READ)
	print(file.get_as_text())
	var obj: Resource = str_to_var(file.get_as_text())
	file.close()
	return obj

func delete_file(path: String) -> Error:
	return DirAccess.remove_absolute(path)

func get_files_in_folder(folder_path: String) -> Array[String]:
	print("getting files in folder")
	
	var files : Array[String] = []
	var dir := DirAccess.open(folder_path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(folder_path + file)
	
	print(files)

	return files

func is_vec_zero_approx(vec: Vector2) -> bool:
	return is_zero_approx(vec.x) and is_zero_approx(vec.y)

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
