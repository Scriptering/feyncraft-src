extends Node

signal crosshair_moved(new_position: Vector2i, old_position: Vector2i)
signal crosshair_area_mouse_entered()
signal crosshair_area_mouse_exited()
signal diagram_mouse_entered()
signal diagram_mouse_exited()
signal grabbable_object_clicked(obj: Node)
signal deletable_object_clicked(obh: Node)
signal show_disabled
signal hide_disabled
signal draw_diagram
signal draw_raw_diagram
signal add_floating_menu
signal change_cursor
signal save_files
signal change_palette(palette: ImageTexture)
signal show_feedback(feedback: String)
signal diagram_submitted(diagram: DrawingMatrix, submissions: Array[DrawingMatrix])
signal signal_enter_game
signal signal_change_scene(scene: Globals.Scene, args: Array)
signal signal_exit_game(mode: BaseMode.Mode, created_problem: Problem)
signal signal_diagram_action_taken
signal signal_problem_modified(problem_item: PanelContainer)
signal signal_problem_set_played(problem_set: ProblemSet, index: int)
signal toggle_scene
signal action_taken

func enter_game(
	mode: BaseMode.Mode, problem_set: ProblemSet = null, problem: Problem = null, creating_problem_set_file: String = ''
) -> void:
	Globals.load_mode = mode
	Globals.load_problem_set = problem_set
	Globals.creating_problem = problem
	Globals.creating_problem_set_file = creating_problem_set_file
	Globals.in_main_menu = false
	
	toggle_scene.emit()
	signal_enter_game.emit()

func exit_game(mode: BaseMode.Mode, problem: Problem = null) -> void:
	Globals.in_main_menu = true
	
	await get_tree().process_frame
	
	toggle_scene.emit()
	signal_exit_game.emit(mode, problem)

func change_scene(scene: Globals.Scene, args: Array = []) -> void:
	signal_change_scene.emit(scene, args)

func problem_modified(problem_item: PanelContainer) -> void:
	signal_problem_modified.emit(problem_item)

func problem_set_played(problem_set: ProblemSet, index: int) -> void:
	signal_problem_set_played.emit(problem_set, index)
