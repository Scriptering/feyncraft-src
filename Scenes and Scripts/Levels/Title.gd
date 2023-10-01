extends "res://Scenes and Scripts/Classes/line_edit.gd"

func _on_text_changed(new_text: String) -> void:
	visible = editable or new_text != ''
