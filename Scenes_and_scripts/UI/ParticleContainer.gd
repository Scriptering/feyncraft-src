extends GridContainer

var items: Array[Control] = []
@onready var start_columns: int = columns

func _ready() -> void:
	items.assign(get_children())
	
	for item:Control in items:
		var control:Control = Control.new()
		control.visible = false
		item.add_sibling(control)
		item.visibility_changed.connect(_on_item_visibility_changed.bind(item))

func get_items_in_row(row:int) -> Array[Control]:
	return items.slice(row * start_columns, row + start_columns)

func item_in_column(item: Control, col: int) -> bool:
	return items.find(item) % start_columns == col

func get_items_in_column(col: int) -> Array[Control]:
	return items.filter(item_in_column.bind(col))

func get_child_index(child: Control) -> int:
	return get_children().find(child)

func get_control(item: Control) -> Control:
	return get_child(get_child_index(item) + 1)

func _on_item_visibility_changed(item: Control) -> void:
	get_control(item).visible = !item.visible

func is_hidden(item: Control) -> bool:
	return !item.visible

func hide_row(row: int) -> void:
	for item:Control in get_items_in_row(row):
		item.hide()
		get_control(item).hide()

func hide_column(col: int) -> void:
	for item:Control in get_items_in_column(col):
		item.hide()
		get_control(item).hide()

func adjust_grid() -> void:
	for row:int in ceil(items.size() / start_columns):
		if get_items_in_row(row).all(is_hidden):
			hide_row(row)
	
	var hidden_columns: int = 0
	for col:int in start_columns:
		if get_items_in_column(col).all(is_hidden):
			hide_column(col)
			hidden_columns += 1
	
	columns = start_columns - hidden_columns
