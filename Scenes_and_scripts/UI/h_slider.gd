extends HSlider

func _ready() -> void:
	drag_ended.connect(_on_drag_ended)

func _on_drag_ended(_value_changed: bool) -> void:
	release_focus()
