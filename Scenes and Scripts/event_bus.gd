extends Node

signal signal_draw_diagram
signal signal_draw_raw_diagram

func draw_diagram(drawing_matrix: DrawingMatrix) -> void:
	emit_signal("signal_draw_diagram", drawing_matrix)

func draw_diagram_raw(connection_matrix: ConnectionMatrix) -> void:
	emit_signal("signal_draw_raw_diagram", connection_matrix)
