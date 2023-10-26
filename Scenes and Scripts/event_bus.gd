extends Node

signal signal_draw_diagram
signal signal_draw_raw_diagram
signal signal_add_floating_menu
signal signal_change_cursor
signal signal_enter_game
signal signal_change_scene(scene: GLOBALS.Scene, args: Array)
signal signal_exit_game(mode: BaseMode.Mode, created_problem: Problem)
signal signal_change_palette(palette: ImageTexture)
signal signal_diagram_action_taken
signal signal_button_created(button: PanelButton)
signal signal_problem_modified(problem_item)
signal signal_problem_set_played(problem_set: ProblemSet, index: int)
signal toggle_scene
signal signal_save_files
signal signal_diagram_submitted(diagram: DrawingMatrix, submissions: Array[DrawingMatrix])

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
	
	toggle_scene.emit()
	signal_enter_game.emit()

func exit_game(mode: BaseMode.Mode, problem: Problem = null) -> void:
	GLOBALS.in_main_menu = true
	
	await get_tree().process_frame
	
	toggle_scene.emit()
	signal_exit_game.emit(mode, problem)

func change_scene(scene: GLOBALS.Scene, args: Array = []) -> void:
	signal_change_scene.emit(scene, args)

func change_palette(palette: ImageTexture) -> void:
	signal_change_palette.emit(palette)

func button_created(button: PanelButton) -> void:
	signal_button_created.emit(button)

func problem_modified(problem_item) -> void:
	signal_problem_modified.emit(problem_item)

func problem_set_played(problem_set: ProblemSet, index: int) -> void:
	signal_problem_set_played.emit(problem_set, index)

func save_files() -> void:
	signal_save_files.emit()

func diagram_submitted(diagram: DrawingMatrix, submissions: Array[DrawingMatrix]) -> void:
	signal_diagram_submitted.emit(diagram, submissions)
