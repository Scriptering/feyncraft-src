class_name MiniDiagramViewer
extends GrabbableControl

signal load_diagram

var drag_vector_start: Vector2
var current_diagram: MiniDiagram:
	get:
		return DiagramContainer.get_current_tab_control()

var last_loaded_tab: int = 0

@onready var Diagram := preload("res://Scenes and Scripts/UI/MiniDiagram/mini_diagram.tscn")
@onready var DiagramContainer := $VBoxContainer/PanelContainer/VBoxContainer/MiniDiagramContainer

func _ready() -> void:
	super._ready()
	
	load_diagram.connect(EVENTBUS.draw_diagram)

func pick_up() -> void:
	super.pick_up()
	drag_vector_start = position - get_global_mouse_position()

func _process(_delta:float) -> void:
	if grabbed:
		position = get_global_mouse_position() + drag_vector_start

func _on_load_pressed() -> void:
	emit_signal("load_diagram", DiagramContainer.get_current_tab_control().generate_drawing_matrix_from_diagram())
	last_loaded_tab = DiagramContainer.current_tab

func _on_left_pressed() -> void:
	DiagramContainer.current_tab = max(DiagramContainer.current_tab - 1, 0)
	update_index_label()

func _on_right_pressed() -> void:
	DiagramContainer.current_tab = min(DiagramContainer.current_tab + 1, DiagramContainer.get_child_count()-1)
	update_index_label()

func get_diagram(index: int) -> DiagramBase:
	return DiagramContainer.get_tab_control(index)

func clear() -> void:
	for diagram in DiagramContainer.get_children():
		diagram.queue_free()

func create_diagrams(matrices: Array) -> void:
	clear()
	
	for matrix in matrices:
		create_diagram(matrix)

func update_index_label() -> void:
	$VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/HBoxContainer/IndexLabel.text = (
		str(DiagramContainer.current_tab) + "/" + str(DiagramContainer.get_child_count())
	)
	

func create_diagram(matrix) -> void:
	var new_diagram : MiniDiagram = Diagram.instantiate()
	DiagramContainer.add_child(new_diagram)
	
	if matrix is ConnectionMatrix:
		new_diagram.draw_raw_diagram(matrix)
	
	elif matrix is DrawingMatrix:
		new_diagram.draw_diagram(matrix)

	update_index_label()
