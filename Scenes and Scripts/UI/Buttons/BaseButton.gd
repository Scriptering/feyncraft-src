class_name ButtonBase extends Button

signal on_pressed

func _ready() -> void:
	self.connect("pressed", Callable(self, "on_press"))

	set_visible_mouse_filter()

func on_press() -> void:
	emit_signal("on_pressed", self)

func visible_changed() -> void:
	set_visible_mouse_filter()

func set_visible_mouse_filter() -> void:
	if is_visible_in_tree():
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	
