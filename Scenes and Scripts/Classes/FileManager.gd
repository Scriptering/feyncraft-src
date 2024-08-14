extends Object
class_name FileManager

static func get_unique_file_name(folder_path: String, suffix: String = '.tres') -> String:
	#print("getting unique file name")
	#print(folder_path)
	
	var random_hex : String = "%x" % (randi() % 4095)
	
	var files: Array[String] = get_files_in_folder(folder_path)
	
	while folder_path + random_hex + suffix in files:
		random_hex = "%x" % (randi() % 4095)
	
	#print(folder_path + random_hex + suffix)
	
	return folder_path + random_hex + suffix

static func create_file(path: String) -> void:
	#print("creating file")
	#print(path)
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	print(file.get_error())
	file.store_string("")
	file = null

static func create_text_file(data: String, path: String) -> void:
	#print("creating text file")
	#print(path)
	
	if DirAccess.dir_exists_absolute(path):
		return
	
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	print(file.get_error())
	file.store_string(data)
	file.close()

static func get_resource_save_data(resource: Resource) -> String:
	return var_to_str(resource)

static func load_data(path: String) -> Resource:
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path)
	
	return null

static func get_file_prefix() -> String:
	if OS.has_feature("web"):
		return "user://"
	
	return "res://"

static func save(p_obj: Resource, p_path: String) -> void:
	var file := FileAccess.open(p_path, FileAccess.WRITE)
	
	if !file: return
	
	var var_as_str: String = var_to_str(p_obj)
	
	file.store_string(var_as_str)
	file.close()

static func load_txt(p_path: String) -> Resource:
	#print("loading txt")
	#print(p_path)
	
	var file := FileAccess.open(p_path, FileAccess.READ)
	#print(file.get_as_text())
	var obj: Resource = str_to_var(file.get_as_text())
	file.close()
	return obj

static func delete_file(path: String) -> Error:
	var error: Error = DirAccess.remove_absolute(path)
	
	if !Globals.is_on_editor:
		var refresh_path: String = "user://saves/ProblemSets/Default/electromagnetic.txt"
		save(load_txt(refresh_path), refresh_path)
	
	return error
	
static func get_files_in_folder(folder_path: String) -> Array[String]:
	#print("getting files in folder")
	
	var files : Array[String] = []
	var dir := DirAccess.open(folder_path)
	dir.list_dir_begin()

	while true:
		var file := dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(folder_path + file)
	
	#print(files)

	return files

static func create_save_folders() -> void:
	print("creating save folders")
	
	DirAccess.make_dir_absolute("user://saves/")
	DirAccess.make_dir_absolute("user://saves/Palettes")
	DirAccess.make_dir_absolute("user://saves/Palettes/Custom")
	DirAccess.make_dir_absolute("user://saves/ProblemSets")
	DirAccess.make_dir_absolute("user://saves/ProblemSets/Custom")
	DirAccess.make_dir_absolute("user://saves/ProblemSets/Default")
