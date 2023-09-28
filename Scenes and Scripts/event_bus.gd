extends Node

signal signal_draw_diagram
signal signal_draw_raw_diagram
signal signal_add_floating_menu
signal signal_change_cursor
signal signal_enter_game
signal signal_change_palette(palette: ImageTexture)
signal signal_diagram_action_taken

func draw_diagram(drawing_matrix: DrawingMatrix) -> void:
	signal_draw_diagram.emit(drawing_matrix)

func draw_diagram_raw(connection_matrix: ConnectionMatrix) -> void:
	signal_draw_raw_diagram.emit(connection_matrix)

func add_floating_menu(menu: Node) -> void:
	signal_add_floating_menu.emit(menu)

func change_cursor(new_cursor: GLOBALS.CURSOR) -> void:
	signal_change_cursor.emit(new_cursor)

func enter_game(mode: BaseMode.Mode, problem_set: ProblemSet = null, problem: Problem = null) -> void:
	GLOBALS.load_mode = mode
	GLOBALS.load_problem_set = problem_set
	GLOBALS.creating_problem = problem
	
	signal_enter_game.emit()

func change_palette(palette: ImageTexture) -> void:
	signal_change_palette.emit(palette)
