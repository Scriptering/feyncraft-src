extends Node2D

@onready var MainMenu: Control = $MainMenu
@onready var Level: Node2D = $World

var modifying_problem_item = null

func _ready() -> void:
	Level.exit_to_main_menu.connect(enter_main_menu)
	MainMenu.sandbox_pressed.connect(_on_sandbox_pressed)
	
	for child in get_children():
		child.show()
	
	remove_child(Level)
	
	EVENTBUS.signal_problem_modified.connect(_on_problem_modified)
	EVENTBUS.signal_problem_set_played.connect(_on_problem_set_played)

func enter_level(mode: BaseMode.Mode) -> void:
	remove_child(MainMenu)
	add_child(Level)
	
	Level.current_mode = GLOBALS.load_mode

func enter_main_menu() -> void:
	remove_child(Level)
	add_child(MainMenu)
	
	modifying_problem_item = null

func _on_sandbox_pressed() -> void:
	enter_level(BaseMode.Mode.Sandbox)

func _on_world_problem_submitted() -> void:
	GLOBALS.save(GLOBALS.load_problem_set, GLOBALS.creating_problem_set_file)
	modifying_problem_item.load_problem(GLOBALS.creating_problem)
	
	enter_main_menu()
	
func _on_problem_modified(problem_item) -> void:
	modifying_problem_item = problem_item
	
	enter_level(BaseMode.Mode.ParticleSelection)

func _on_problem_set_played(problem_set: ProblemSet, index: int) -> void:
	Level.load_problem_set(problem_set, index)
	
	enter_level(BaseMode.Mode.ProblemSolving)
