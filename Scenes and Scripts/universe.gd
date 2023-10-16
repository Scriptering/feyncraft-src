extends Node2D

@onready var MainMenu: Control = $MainMenu
@onready var Level: Node2D = $World

var modifying_problem_item = null

var enter_funcs: Dictionary = {
	GLOBALS.Scene.Level: enter_level,
	GLOBALS.Scene.MainMenu: enter_main_menu
}

func _ready() -> void:
	Level.exit_to_main_menu.connect(enter_main_menu)
	MainMenu.sandbox_pressed.connect(_on_sandbox_pressed)
	
	for child in get_children():
		child.show()
	
	remove_child(Level)
	
	EVENTBUS.signal_problem_modified.connect(_on_problem_modified)
	EVENTBUS.signal_problem_set_played.connect(_on_problem_set_played)
	EVENTBUS.signal_add_floating_menu.connect(add_floating_menu)

func add_floating_menu(menu: Control) -> void:
	$FloatingMenus.add_child(menu)

func change_scene(scene: GLOBALS.Scene, args: Array = []) -> void:
	for child in $FloatingMenus.get_children():
		child.hide()
	
	enter_funcs[scene].call(args)

func enter_level(args: Array = [BaseMode.Mode.Sandbox]) -> void:
	GLOBALS.in_main_menu = false
	remove_child(MainMenu)
	add_child(Level)
	move_child(Level, 0)
	
	Level.current_mode = args[0]

func enter_main_menu(_args: Array = []) -> void:
	GLOBALS.in_main_menu = true
	remove_child(Level)
	add_child(MainMenu)
	move_child(MainMenu, 0)
	
	modifying_problem_item = null

func _on_sandbox_pressed() -> void:
	enter_level([BaseMode.Mode.Sandbox])

func _on_world_problem_submitted() -> void:
	GLOBALS.save(GLOBALS.load_problem_set, GLOBALS.creating_problem_set_file)
	modifying_problem_item.load_problem(GLOBALS.creating_problem)
	
	enter_main_menu()
	
func _on_problem_modified(problem_item) -> void:
	modifying_problem_item = problem_item
	
	enter_level([BaseMode.Mode.ParticleSelection])

func _on_problem_set_played(problem_set: ProblemSet, index: int) -> void:
	Level.load_problem_set(problem_set, index)
	
	enter_level([BaseMode.Mode.ProblemSolving])
