class_name ListItem
extends PanelContainer

signal deleted(item: ListItem)

var index: int: set = _set_index

func load_data(_data) -> void:
	pass

func _set_index(new_value: int) -> void:
	index = new_value
