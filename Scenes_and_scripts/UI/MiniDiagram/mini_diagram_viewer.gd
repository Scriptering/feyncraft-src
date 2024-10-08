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
@export var max_index_label: Label
@export var index: SpinBox
@export var left: PanelButton
@export var right: PanelButton

var diagrams: Array[Variant] = []
var filtered_diagrams : Array[Variant] = []

var current_index: int = 0:
	set(new_value):
		var clamped_value : int = clamp(new_value, 0, max(0, filtered_diagrams.size() - 1))
		current_index = clamped_value
		
		if filtered_diagrams.size() != 0:
			filtered_diagrams[current_index] = get_drawing_matrix(current_index)
			mini_diagram.draw_diagram(filtered_diagrams[current_index])

		update()

func _ready() -> void:
	super._ready()
	
	resave_button.visible = allow_resaving
	BigDiagram.action.connect(update_resave_button)

func init(big_diagram: MainDiagram) -> void:
	BigDiagram = big_diagram

func _on_load_pressed() -> void:
	EventBus.draw_diagram.emit(get_drawing_matrix(current_index))
	update_resave_button()

func _on_left_pressed() -> void:
	self.current_index -= 1
	update_index_label()

func get_drawing_matrix(index: int) -> DrawingMatrix:
	var matrix: Variant = filtered_diagrams[index]
	
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
	filtered_diagrams.clear()
	current_index = 0
	
	%Filter.reset()
	
	update()

func toggle_visible() -> void:
	visible = !visible
	self.current_index = 0

func update_index() -> void:
	if filtered_diagrams.size() == 0:
		index.min_value = 0
		index.set_value_no_signal(0)
	else:
		index.min_value = 1
		index.set_value_no_signal(current_index + 1)
	update_index_label()
	left.disabled = current_index == 0
	right.disabled = current_index == filtered_diagrams.size() - 1 or filtered_diagrams.size() == 0

func update_max_index() -> void:
	index.max_value = filtered_diagrams.size()

func store_diagram(matrix: Variant) -> void:
	diagrams.push_back(matrix)
	
	filter_diagrams()
	
	self.current_index = current_index
	update()

func store_diagrams(matrices: Array) -> void:
	clear()
	
	diagrams.append_array(matrices)
	filtered_diagrams = diagrams
	
	self.current_index = 0
	update()

func update() -> void:
	update_index()
	update_max_index()
	update_diagram_visibility()
	update_delete_button()
	update_resave_button()

func update_index_label() -> void:
	max_index_label.text = "/" + str(filtered_diagrams.size())

func update_diagram_visibility() -> void:
	mini_diagram.visible = filtered_diagrams.size() > 0

func update_resave_button(drawn_diagram: DrawingMatrix = BigDiagram.get_current_diagram()) -> void:
	if !visible or !allow_resaving:
		return
	
	if filtered_diagrams.size() == 0:
		resave_button.disabled = true
		return
	
	var reordered_diagram: DrawingMatrix = filtered_diagrams[current_index].duplicate(true)
	reordered_diagram.reorder_state_ids()
	
	var reordered_drawn_diagram: DrawingMatrix = drawn_diagram.duplicate(true)
	reordered_drawn_diagram.reorder_state_ids()
	
	resave_button.disabled = !reordered_drawn_diagram.is_duplicate(reordered_diagram)

func update_delete_button() -> void:
	delete_button.disabled = diagrams.size() == 0

func remove_diagram(index: int = current_index) -> void:
	var diagram: Variant = filtered_diagrams[index]
	
	diagrams.erase(diagram)
	filtered_diagrams.erase(diagram)
	diagram_deleted.emit(index)
	
	self.current_index = clamp(current_index, 0, filtered_diagrams.size()-1)
	update()

func get_diagram_count() -> int:
	return diagrams.size()

func _on_delete_pressed() -> void:
	remove_diagram()

func _on_close_pressed() -> void:
	closed.emit()

func _on_resave_pressed() -> void:
	resave_diagram(BigDiagram.generate_drawing_matrix_from_diagram())

func resave_diagram(new_diagram: DrawingMatrix) -> void:
	var diagram: Variant = filtered_diagrams[current_index]
	
	filtered_diagrams[current_index] = new_diagram
	diagrams[diagrams.find(diagram)] = new_diagram
	
	mini_diagram.draw_diagram(get_drawing_matrix(current_index))
	diagram_resaved.emit(current_index)
	update()

func _on_index_value_changed(value: float) -> void:
	if current_index == value - 1:
		return

	self.current_index = max(0, value - 1)

func filter_diagram(diagram: ConnectionMatrix) -> bool:
	var filters: Dictionary = %Filter.filters
	var filter_ranges : Array[Vector2i] = filters["degree_ranges"]
		
	for i:int in filter_ranges.size():
		if (
			filter_ranges[i].x == 0
			and filter_ranges[i].y == 0
		):
			continue
		
		var diagram_force_count: int = diagram.get_force_count(i)
		if (
			diagram_force_count < filter_ranges[i].x
			or diagram_force_count > filter_ranges[i].y
		):
			return false
	
	if filters["only_4_vertex"] and ArrayFuncs.packed_int_all(
		diagram.get_state_ids(StateLine.State.None),
		func(id: int) -> bool:
			return ParticleData.degree(
				diagram.get_connected_particles(id, true)
			) <= 1
	):
		return false
	
	return true

func filter_diagrams() -> void:
	filtered_diagrams = diagrams.filter(filter_diagram)
	current_index = current_index

func _on_filter_filters_submitted() -> void:
	filter_diagrams()
	update()
