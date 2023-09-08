@tool

class_name MiniDiagramViewer
extends GrabbableControl

signal diagram_deleted
signal load_diagram
signal closed

@export var title: String:
	set(new_value):
		print("title set")
		title = new_value
		get_node("VBoxContainer/HBoxContainer/Title").text = new_value

var drag_vector_start: Vector2
var current_diagram: MiniDiagram:
	get:
		return DiagramContainer.get_current_tab_control()

var last_loaded_tab: int = 0

@onready var Diagram := preload("res://Scenes and Scripts/UI/MiniDiagram/mini_diagram.tscn")
@onready var DiagramContainer := $VBoxContainer/PanelContainer/VBoxContainer/CenterContainer/MiniDiagramContainer

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
	DiagramContainer.current_tab = min(DiagramContainer.current_tab + 1, DiagramContainer.get_tab_count()-1)
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
	var diagram_count: int = get_diagram_count()
	var current_index: int = DiagramContainer.current_tab + 1 if diagram_count != 0 else 0
	
	$VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/IndexContainer/IndexLabel.text = (
		str(current_index) + "/" + str(diagram_count)
	)

func update_delete_button() -> void:
	$VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Delete.disabled = DiagramContainer.get_child_count() == 0

func create_diagram(matrix) -> void:
	var new_diagram : MiniDiagram = Diagram.instantiate()
	DiagramContainer.add_child(new_diagram)
	
	if matrix is ConnectionMatrix:
		new_diagram.draw_raw_diagram(matrix)
	
	elif matrix is DrawingMatrix:
		new_diagram.draw_diagram(matrix)
	
	await get_tree().process_frame
	
	update_index_label()
	update_delete_button()

func remove_diagram(index: int = DiagramContainer.current_tab) -> void:
	DiagramContainer.get_child(index).queue_free()
	
	emit_signal("diagram_deleted", index)
	
	await get_tree().process_frame
	
	update_index_label()
	update_delete_button()

func get_diagram_count() -> int:
	return DiagramContainer.get_tab_count()

func _on_delete_pressed() -> void:
	remove_diagram()

func _on_x_pressed() -> void:
	emit_signal("closed")
