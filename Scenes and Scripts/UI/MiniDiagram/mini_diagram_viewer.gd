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

var diagrams: Array[DrawingMatrix] = []
var current_index: int = 0:
	set(new_value):
		var clamped_value = clamp(new_value, 0, max(0, diagrams.size() - 1))
		current_index = clamped_value
		
		if diagrams.size() != 0:
			Diagram.draw_diagram(diagrams[current_index])

		update_index_label()

@onready var Diagram : MiniDiagram = $VBoxContainer/PanelContainer/VBoxContainer/CenterContainer/MiniDiagramContainer/MiniDiagram

func _ready() -> void:
	super._ready()
	
	load_diagram.connect(EVENTBUS.draw_diagram)

func _on_load_pressed() -> void:
	emit_signal("load_diagram", diagrams[current_index])

func _on_left_pressed() -> void:
	self.current_index -= 1
	update_index_label()

func _on_right_pressed() -> void:
	self.current_index += 1
	update_index_label()

func clear() -> void:
	diagrams.clear()

func toggle_visible() -> void:
	visible = !visible
	self.current_index = 0

func store_diagram(matrix) -> void:
	if matrix is DrawingMatrix:
		diagrams.push_back(matrix)
	elif matrix is ConnectionMatrix:
		var drawing_matrix := DrawingMatrix.new()
		drawing_matrix.initialise_from_connection_matrix(matrix)
		Diagram.create_diagram_interaction_positions(drawing_matrix)
		diagrams.push_back(drawing_matrix)
	
	self.current_index = current_index
	
	update_diagram_visibility()

func store_diagrams(matrices: Array) -> void:
	clear()
	
	for matrix in matrices:
		store_diagram(matrix)
	
	self.current_index = 0
	update_index_label()

func update_index_label() -> void:
	var label_index: int = current_index + 1 if diagrams.size() != 0 else 0
	
	$VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/IndexContainer/IndexLabel.text = (
		str(label_index) + "/" + str(diagrams.size())
	)

func update_diagram_visibility() -> void:
	Diagram.visible = diagrams.size() > 0

func update_delete_button() -> void:
	$VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Delete.disabled = diagrams.size() == 0

func remove_diagram(index: int = current_index) -> void:
	diagrams.remove_at(index)
	
	emit_signal("diagram_deleted", index)
	
	current_index = clamp(current_index, 0, diagrams.size()-1)
	
	await get_tree().process_frame
	
	update_index_label()
	update_delete_button()
	update_diagram_visibility()

func get_diagram_count() -> int:
	return diagrams.size()

func _on_delete_pressed() -> void:
	remove_diagram()

func _on_x_pressed() -> void:
	emit_signal("closed")
