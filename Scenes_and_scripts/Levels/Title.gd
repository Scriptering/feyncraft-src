extends "res://Scenes_and_scripts/Classes/line_edit.gd"

func _on_text_changed(new_text: String) -> void:
	visible = editable or new_text != ''
