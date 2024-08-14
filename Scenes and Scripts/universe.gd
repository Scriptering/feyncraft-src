extends Node2D

enum Scene {Level, MainMenu}

var current_scene: Scene

@onready var MainMenu: Node2D = $MainMenu
@onready var Level: Node2D = $World
@onready var StateManager: Node = $state_manager

var modifying_problem_item : PanelContainer = null

var enter_funcs: Dictionary = {
	Scene.Level: enter_level,
	Scene.MainMenu: enter_main_menu
}

@onready var scenes: Dictionary = {
	Scene.Level: Level,
	Scene.MainMenu: MainMenu
}

func _ready() -> void:
	Globals.load_problem_set.problems.push_back(Globals.creating_problem)
	
	if !Globals.is_on_editor and !DirAccess.dir_exists_absolute("User://saves/"):
		create_save_folders()
		
		if !FileAccess.file_exists("user://saves/ProblemSets/Default/electromagnetic.tres"):
			create_default_problem_sets()

	MainMenu.sandbox_pressed.connect(_on_sandbox_pressed)
	MainMenu.tutorial_pressed.connect(_on_tutorial_pressed)
	
	current_scene = Scene.MainMenu
	remove_child(Level)
	
	EventBus.signal_change_scene.connect(change_scene)
	EventBus.signal_problem_modified.connect(_on_problem_modified)
	EventBus.signal_problem_set_played.connect(_on_problem_set_played)
	EventBus.add_floating_menu.connect(add_floating_menu)
	
	StateManager.init(MainMenu.Diagram)
	
	$ControlsLayer/Buttons.visible = Globals.is_on_mobile()
	$ControlsLayer/Cursor.visible = !Globals.is_on_mobile()
	
	MainMenu.init(StateManager)
	Level.init(StateManager)

func add_floating_menu(menu: Control) -> void:
	scenes[current_scene].add_floating_menu(menu)

func change_scene(scene: Scene, args: Array = []) -> void:
	switch_child_scene(scene)
	StateManager.change_scene(scenes[scene].Diagram)
	
	enter_funcs[scene].call(args)
	EventBus.change_cursor.emit(Globals.Cursor.default)

func switch_child_scene(new_scene: Scene) -> void:
	current_scene = new_scene
	remove_child(scenes[(new_scene + 1) % 2])
	add_child(scenes[new_scene])
	move_child(scenes[new_scene], 0)

func enter_level(args: Array = [BaseMode.Mode.Sandbox]) -> void:
	Globals.in_main_menu = false
	Level.current_mode = args[0]

func enter_main_menu(_args: Array = []) -> void:
	Globals.in_main_menu = true
	modifying_problem_item = null
	
	EventBus.save_files.emit()

func _on_sandbox_pressed() -> void:
	change_scene(Scene.Level, [BaseMode.Mode.Sandbox])

func _on_tutorial_pressed() -> void:
	change_scene(Scene.Level, [BaseMode.Mode.Tutorial])

func _on_world_problem_submitted() -> void:
	modifying_problem_item.save()
	
	change_scene(Scene.MainMenu)

func _on_problem_modified(problem_item: PanelContainer) -> void:
	modifying_problem_item = problem_item
	
	Globals.creating_problem = modifying_problem_item.problem

	change_scene(Scene.Level, [BaseMode.Mode.ParticleSelection])

func _on_problem_set_played(problem_set: ProblemSet, index: int) -> void:
	change_scene(Scene.Level, [BaseMode.Mode.ProblemSolving])
	Level.load_problem_set(problem_set, index)

func _on_world_save_problem_set() -> void:
	EventBus.save_files.emit()

func create_save_folders() -> void:
	print("creating save folders")
	
	DirAccess.make_dir_absolute("user://saves/")
	DirAccess.make_dir_absolute("user://saves/Palettes")
	DirAccess.make_dir_absolute("user://saves/Palettes/Custom")
	DirAccess.make_dir_absolute("user://saves/ProblemSets")
	DirAccess.make_dir_absolute("user://saves/ProblemSets/Custom")
	DirAccess.make_dir_absolute("user://saves/ProblemSets/Default")

func create_default_problem_sets() -> void:
	for file_path:String in FileManager.get_files_in_folder("res://saves/ProblemSets/Default/"):
		DirAccess.copy_absolute(file_path, "user://saves/ProblemSets/Default/")
	
	await get_tree().process_frame
