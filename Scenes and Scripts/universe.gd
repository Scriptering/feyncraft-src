extends Node2D

signal save_files

enum Scene {Level, MainMenu}

@onready var MainMenu: Control = $MainMenu
@onready var Level: Node2D = $World
@onready var StateManager: Node = $state_manager
@onready var Cursor: Sprite2D = $Cursor
@onready var ControlsTab: Control = $PullOutTabs/ControlsTab
@onready var PaletteMenu: GrabbableControl = $FloatingMenus/PaletteMenu

var modifying_problem_item = null

var enter_funcs: Dictionary = {
	Scene.Level: enter_level,
	Scene.MainMenu: enter_main_menu
}

@onready var scenes: Dictionary = {
	Scene.Level: Level,
	Scene.MainMenu: MainMenu
}

func _ready() -> void:
	MainMenu.sandbox_pressed.connect(_on_sandbox_pressed)
	
	remove_child(Level)
	
	save_files.connect(EVENTBUS.save_files)
	EVENTBUS.signal_change_scene.connect(change_scene)
	EVENTBUS.signal_problem_modified.connect(_on_problem_modified)
	EVENTBUS.signal_problem_set_played.connect(_on_problem_set_played)
	EVENTBUS.signal_add_floating_menu.connect(add_floating_menu)
	
	Level.init(StateManager, ControlsTab, PaletteMenu)
	MainMenu.init(StateManager, ControlsTab, PaletteMenu)
	StateManager.init(MainMenu.Diagram, MainMenu.ControlsTab)

func add_floating_menu(menu: Control) -> void:
	$FloatingMenus.add_child(menu)

func change_scene(scene: Scene, args: Array = []) -> void:
	for child in $FloatingMenus.get_children():
		child.hide()
	ControlsTab.release_buttons()
	
	switch_child_scene(scene)
	StateManager.change_scene(scenes[scene].Diagram, scenes[scene].ControlsTab)
	
	enter_funcs[scene].call(args)
	EVENTBUS.change_cursor(GLOBALS.CURSOR.default)

func switch_child_scene(new_scene: Scene) -> void:
	remove_child(scenes[(new_scene + 1) % 2])
	add_child(scenes[new_scene])
	move_child(scenes[new_scene], 0)

func enter_level(args: Array = [BaseMode.Mode.Sandbox]) -> void:
	GLOBALS.in_main_menu = false
	Level.current_mode = args[0]

func enter_main_menu(_args: Array = []) -> void:
	GLOBALS.in_main_menu = true
	modifying_problem_item = null
	
	MainMenu.reload_problem_selection()

func _on_sandbox_pressed() -> void:
	change_scene(Scene.Level, [BaseMode.Mode.Sandbox])

func _on_world_problem_submitted() -> void:
	GLOBALS.save(GLOBALS.load_problem_set, GLOBALS.creating_problem_set_file)
	modifying_problem_item.load_problem(GLOBALS.creating_problem)
	
	change_scene(Scene.MainMenu)
	
	save_files.emit()
	
func _on_problem_modified(problem_item) -> void:
	modifying_problem_item = problem_item
	
	GLOBALS.creating_problem = modifying_problem_item.problem

	change_scene(Scene.Level, [BaseMode.Mode.ParticleSelection])

func _on_problem_set_played(problem_set: ProblemSet, index: int) -> void:
	change_scene(Scene.Level, [BaseMode.Mode.ProblemSolving])
	Level.load_problem_set(problem_set, index)

func _on_tree_exited() -> void:
	save_files.emit()
