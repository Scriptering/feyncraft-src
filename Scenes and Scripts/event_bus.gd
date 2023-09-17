extends Node

signal signal_draw_diagram
signal signal_draw_raw_diagram
signal signal_add_floating_menu
signal signal_change_cursor
signal signal_mode_changed

func draw_diagram(drawing_matrix: DrawingMatrix) -> void:
	signal_draw_diagram.emit(drawing_matrix)

func draw_diagram_raw(connection_matrix: ConnectionMatrix) -> void:
	signal_draw_raw_diagram.emit(connection_matrix)

func add_floating_menu(menu: Node) -> void:
	signal_add_floating_menu.emit(menu)

func change_cursor(new_cursor: GLOBALS.CURSOR) -> void:
	signal_change_cursor.emit(new_cursor)

func mode_changed(prev_mode: GLOBALS.Mode, new_mode: GLOBALS.Mode) -> void:
	signal_mode_changed.emit(prev_mode, new_mode)
