extends Node

signal signal_draw_diagram
signal signal_draw_raw_diagram
signal signal_add_floating_menu

func draw_diagram(drawing_matrix: DrawingMatrix) -> void:
	emit_signal("signal_draw_diagram", drawing_matrix)

func draw_diagram_raw(connection_matrix: ConnectionMatrix) -> void:
	emit_signal("signal_draw_raw_diagram", connection_matrix)

func add_floating_menu(menu: Node) -> void:
	emit_signal("signal_add_floating_menu", menu)
