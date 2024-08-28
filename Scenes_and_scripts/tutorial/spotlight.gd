extends Panel

var focus_object: Node

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	position = focus_object.get_global_position()
	size = focus_object.size
