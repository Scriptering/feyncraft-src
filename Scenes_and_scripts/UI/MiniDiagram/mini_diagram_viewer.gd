class_name MiniDiagramViewer
extends GrabbableControl

signal diagram_deleted
signal diagram_resaved
signal closed

@export var allow_resaving: bool = false
@export var title: String:
	set(new_value):
		title = new_value
		title_label.text = new_value

@export var BigDiagram: MainDiagram

@export_group("Children")
@export var delete_button : PanelButton
@export var resave_button : PanelButton
@export var title_label: Label
@export var mini_diagram: MiniDiagram
@export var index_label: Label
@export var left: PanelButton
@export var right: PanelButton

var diagrams: Array[Variant] = []
var current_index: int = 0:
	set(new_value):
		var clamped_value : int = clamp(new_value, 0, max(0, diagrams.size() - 1))
		current_index = clamped_value
		
		if diagrams.size() != 0:
			diagrams[current_index] = get_drawing_matrix(current_index)
			mini_diagram.draw_diagram(diagrams[current_index])

		update_index()
		update_resave_button()

func _ready() -> void:
	super._ready()
	
	resave_button.visible = allow_resaving
	
	BigDiagram.action_taken.connect(update_resave_button)

func init(big_diagram: MainDiagram) -> void:
	BigDiagram = big_diagram

func _on_load_pressed() -> void:
	EventBus.draw_diagram.emit(get_drawing_matrix(current_index))

func _on_left_pressed() -> void:
	self.current_index -= 1
	update_index_label()

func get_drawing_matrix(index: int) -> DrawingMatrix:
	var matrix: Variant = diagrams[index]
	
	if matrix is DrawingMatrix:
		return matrix
	
	if matrix is ConnectionMatrix:
		var drawing_matrix := DrawingMatrix.new()
		drawing_matrix.initialise_from_connection_matrix(matrix)
		mini_diagram.create_diagram_interaction_positions(drawing_matrix)
		matrix = drawing_matrix
	
	return matrix

func _on_right_pressed() -> void:
	self.current_index += 1
	update_index_label()

func clear() -> void:
	diagrams.clear()

func toggle_visible() -> void:
	visible = !visible
	self.current_index = 0

func update_index() -> void:
	update_index_label()
	left.disabled = current_index == 0
	right.disabled = current_index == diagrams.size() - 1

func store_diagram(matrix: Variant) -> void:
	diagrams.push_back(matrix)
	self.current_index = current_index
	update_index()
	update_diagram_visibility()
	update_delete_button()

func store_diagrams(matrices: Array) -> void:
	clear()
	
	for matrix:Variant in matrices:
		diagrams.push_back(matrix)
	
	self.current_index = 0
	update_index()
	update_diagram_visibility()
	update_delete_button()

func update_index_label() -> void:
	var label_index: int = current_index + 1 if diagrams.size() != 0 else 0
	
	index_label.text = str(label_index) + "/" + str(diagrams.size())

func update_diagram_visibility() -> void:
	mini_diagram.visible = diagrams.size() > 0

func update_resave_button(drawn_diagram: DrawingMatrix = BigDiagram.generate_drawing_matrix_from_diagram()) -> void:
	if !visible or !allow_resaving:
		return
	
	resave_button.disabled = diagrams.size() == 0 || !drawn_diagram.is_duplicate(diagrams[current_index])

func update_delete_button() -> void:
	delete_button.disabled = diagrams.size() == 0

func remove_diagram(index: int = current_index) -> void:
	diagrams.remove_at(index)
	
	diagram_deleted.emit(index)
	
	self.current_index = clamp(current_index, 0, diagrams.size()-1)
	
	await get_tree().process_frame
	
	update_index_label()
	update_delete_button()
	update_diagram_visibility()

func get_diagram_count() -> int:
	return diagrams.size()

func _on_delete_pressed() -> void:
	remove_diagram()

func _on_close_pressed() -> void:
	closed.emit()

func _on_resave_pressed() -> void:
	var new_diagram: DrawingMatrix = BigDiagram.generate_drawing_matrix_from_diagram()
	
	if new_diagram.is_duplicate(get_drawing_matrix(current_index)):
		resave_diagram(new_diagram)

func resave_diagram(new_diagram: DrawingMatrix) -> void:
	diagrams.remove_at(current_index)
	diagrams.insert(current_index, new_diagram)
	
	mini_diagram.draw_diagram(get_drawing_matrix(current_index))
	
	diagram_resaved.emit(current_index)
	
	await get_tree().process_frame
	
	update_index_label()
	update_delete_button()
	update_diagram_visibility()
