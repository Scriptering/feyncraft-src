extends Node2D

enum Scene {Level, MainMenu}

var current_scene: Scene

@onready var MainMenu: Node2D = $MainMenu
@onready var Level: Node2D = $World
@onready var StateManager: Node = $state_manager

var modifying_problem_item : PanelContainer = null

var daily_problem_set := ProblemSet.new()

var enter_funcs: Dictionary = {
	Scene.Level: enter_level,
	Scene.MainMenu: enter_main_menu
}

@onready var scenes: Dictionary = {
	Scene.Level: Level,
	Scene.MainMenu: MainMenu
}

const seconds_in_day: int = 24 * 60 * 60

func _ready() -> void:
	get_viewport().physics_object_picking_sort = true
	get_viewport().physics_object_picking_first_only = true
	
	$ControlsLayer/Buttons.visible = false
	$ControlsLayer/Cursor.visible = true

	Globals.load_problem_set.problems.push_back(Globals.creating_problem)
	
	if !Globals.is_on_editor and !DirAccess.dir_exists_absolute("User://saves/"):
		FileManager.create_save_folders()
		
		if !FileAccess.file_exists("user://saves/ProblemSets/Default/electromagnetic.tres"):
			create_default_problem_sets()
	
	MainMenu.sandbox_pressed.connect(_on_sandbox_pressed)
	MainMenu.tutorial_pressed.connect(_on_tutorial_pressed)
	
	if should_reset_daily_streak():
		StatsManager.stats.daily_streak = 0
	daily_problem_set.end_reached.connect(_on_daily_completed)
	
	current_scene = Scene.MainMenu
	remove_child(Level)
	
	EventBus.signal_change_scene.connect(change_scene)
	EventBus.signal_problem_modified.connect(_on_problem_modified)
	EventBus.signal_problem_set_played.connect(_on_problem_set_played)
	EventBus.add_floating_menu.connect(add_floating_menu)
	
	StateManager.init(MainMenu.Diagram)
	
	EventBus.using_touchscreen_changed.connect(_on_using_touchscreen_changed)
	
	MainMenu.init(StateManager)
	Level.init(StateManager)
	
	var last_palette: Palette = StatsManager.stats.palette
	if !last_palette:
		EventBus.change_palette.emit(load("res://saves/Palettes/Default/teastain.tres").generate_palette_texture())
	else:
		EventBus.change_palette.emit(last_palette.generate_palette_texture())

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

func create_default_problem_sets() -> void:
	for file_path:String in FileManager.get_files_in_folder("res://saves/ProblemSets/Default/"):
		file_path = file_path.trim_suffix(".remap")
		var user_path: String = "user" + file_path.trim_prefix("res")
		ResourceSaver.save(load(file_path), user_path)
	
	await get_tree().process_frame

func load_daily() -> void:
	if daily_problem_set.problems.size() == 0:
		var date: Dictionary = Time.get_datetime_dict_from_system()

		var set_seed: int = int("%s%s%s"%[date.day, date.month, date.year])

		var daily_problem := ProblemGeneration.setup_new_problem(ProblemGeneration.generate(
			3, 6, ProblemGeneration.HadronFrequency.Allowed, ProblemGeneration.get_all_particles(),
			set_seed
		))
		daily_problem.title = "Daily"

		daily_problem_set.problems.push_back(daily_problem)
		daily_problem_set.current_index = 0

	change_scene(Scene.Level, [BaseMode.Mode.ProblemSolving])
	Level.load_problem_set(daily_problem_set, 0)

func _on_main_menu_daily_pressed() -> void:
	load_daily()

func _on_daily_completed() -> void:
	var last_date := StatsManager.stats.last_daily_completed_date
	var date := Time.get_datetime_dict_from_system()
	
	if !last_date or !is_same_day(last_date, date):
		StatsManager.stats.last_daily_completed_date = Time.get_datetime_dict_from_system()
		StatsManager.stats.daily_streak += 1
		MainMenu.set_daily_counter()

func is_same_day(dateA: Dictionary, dateB: Dictionary) -> bool:
	return (
		dateA.day == dateB.day
		&& dateA.month == dateB.month
		&& dateA.year == dateB.year
	)

func get_day_difference(dateA: Dictionary, dateB: Dictionary) -> int:
	return floor(abs(
		Time.get_unix_time_from_datetime_dict(dateA)
		- Time.get_unix_time_from_datetime_dict(dateB)
	) / seconds_in_day)

func should_reset_daily_streak() -> bool:
	if !StatsManager.stats.last_daily_completed_date:
		return false
	
	var day_difference: int = get_day_difference(
		StatsManager.stats.last_daily_completed_date,
		Time.get_datetime_dict_from_system()
	)
	
	return day_difference > 1

func _on_using_touchscreen_changed(using_touchscreen: bool) -> void:
	EventBus.show_feedback.emit("Touch screen changed")
	$ControlsLayer/Cursor.visible = !using_touchscreen
