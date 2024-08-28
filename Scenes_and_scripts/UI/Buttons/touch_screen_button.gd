extends TouchScreenButton
class_name TouchScreenButtonBase

func _ready() -> void:
	EventBus.using_touchscreen_changed.connect(_on_using_touchscreen_changed)

func _on_using_touchscreen_changed(using_touchscreen: bool) -> void:
	print(using_touchscreen)
	visible = using_touchscreen
