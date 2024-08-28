extends PanelContainer
class_name PanelItemList

@onready var scroll_container: ScrollContainer = $MarginContainer/ScrollContainer
@onready var item_container: VBoxContainer = $MarginContainer/ScrollContainer/MarginContainer/ItemContainer

func _ready() -> void:
	scroll_container.get_v_scroll_bar().use_parent_material = true

func get_items() -> Array:
	return item_container.get_children()

func add_item(new_item: Node) -> void:
	item_container.add_child(new_item)

func remove_item(item: Node) -> void:
	item_container.remove_child(item)

func queue_free_item(item: Node) -> void:
	item.queue_free()

func get_item(i: int) -> Node:
	return item_container.get_child(i)

func queue_free_item_at(i: int) -> void:
	get_item(i).queue_free()

func remove_item_at(i: int) -> void:
	item_container.remove_child(get_item(i))

func clear_items() -> void:
	for item:Node in get_items():
		item.queue_free()

func get_item_count() -> int:
	return item_container.get_child_count()

func move_item(item: Node, i:int) -> void:
	item_container.move_child(item, i)
