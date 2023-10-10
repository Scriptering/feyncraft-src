extends Node

signal signal_draw_diagram
signal signal_draw_raw_diagram
signal signal_add_floating_menu
signal signal_change_cursor
signal signal_enter_game
signal signal_exit_game(mode: BaseMode.Mode, created_problem: Problem)
signal signal_change_palette(palette: ImageTexture)
signal signal_diagram_action_taken
signal signal_button_created(button: PanelButton)

func draw_diagram(drawing_matrix: DrawingMatrix) -> void:
	signal_draw_diagram.emit(drawing_matrix)

func draw_diagram_raw(connection_matrix: ConnectionMatrix) -> void:
	signal_draw_raw_diagram.emit(connection_matrix)

func add_floating_menu(menu: Node) -> void:
	signal_add_floating_menu.emit(menu)

func change_cursor(new_cursor: GLOBALS.CURSOR) -> void:
	signal_change_cursor.emit(new_cursor)

func enter_game(
	mode: BaseMode.Mode, problem_set: ProblemSet = null, problem: Problem = null, creating_problem_set_file: String = ''
) -> void:
	GLOBALS.load_mode = mode
	GLOBALS.load_problem_set = problem_set
	GLOBALS.creating_problem = problem
	GLOBALS.creating_problem_set_file = creating_problem_set_file
	GLOBALS.in_main_menu = false
	
	signal_enter_game.emit()

func exit_game(mode: BaseMode.Mode, problem: Problem = null) -> void:
	GLOBALS.in_main_menu = true
	get_tree().change_scene_to_file("res://Scenes and Scripts/UI/Menus/MainMenu/main_menu.tscn")
	
	await get_tree().process_frame
	
	signal_exit_game.emit(mode, problem)

func change_palette(palette: ImageTexture) -> void:
	signal_change_palette.emit(palette)

func button_created(button: PanelButton) -> void:
	signal_button_created.emit(button)
