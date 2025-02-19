extends Node

signal press(press_position: Vector2)

signal crosshair_moved(new_position: Vector2i, old_position: Vector2i)
signal crosshair_area_mouse_entered()
signal crosshair_area_mouse_exited()
signal crosshair_area_finger_entered(index: int)
signal crosshair_area_finger_exited(index: int)

signal using_touchscreen_changed(using_touchscreen: bool)

signal diagram_mouse_entered()
signal diagram_mouse_exited()
signal diagram_finger_pressed(index: int)
signal diagram_mouse_pressed()

signal grabbable_object_clicked(obj: Node)
signal deletable_object_clicked(obj: Node)
signal deletable_object_hover_changed(obj: Node, hovered: bool)

signal problem_modified(problem_item: PanelContainer)
signal problem_set_played(problem_set: ProblemSet, index: int)

signal show_disabled
signal hide_disabled
signal change_cursor
signal toggle_cursor_heart(toggle: bool)

signal draw_diagram
signal draw_raw_diagram

signal add_floating_menu
signal save_files
signal change_palette(palette: ImageTexture)
signal show_feedback(feedback: String)
signal diagram_submitted(diagram: DrawingMatrix, submissions: Array[DrawingMatrix])
signal signal_enter_game
signal signal_change_scene(scene: Globals.Scene, args: Array)
signal signal_exit_game(mode: int, created_problem: Problem)
signal toggle_scene

signal message(message: String)

signal crosshair_mobile_event_handled()

func enter_game(
	mode: int, problem_set: ProblemSet = null, problem: Problem = null, creating_problem_set_file: String = ''
) -> void:
	Globals.load_mode = mode
	Globals.load_problem_set = problem_set
	Globals.creating_problem = problem
	Globals.creating_problem_set_file = creating_problem_set_file
	Globals.in_main_menu = false
	
	toggle_scene.emit()
	signal_enter_game.emit()

func exit_game(mode: int, problem: Problem = null) -> void:
	Globals.in_main_menu = true
	
	await get_tree().process_frame
	
	toggle_scene.emit()
	signal_exit_game.emit(mode, problem)

func change_scene(scene: Globals.Scene, args: Array = []) -> void:
	signal_change_scene.emit(scene, args)
