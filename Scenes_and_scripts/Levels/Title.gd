extends "res://Scenes_and_scripts/Classes/line_edit.gd"

func _ready() -> void:
	super._ready()
	
	self.editable = Globals.load_mode == BaseMode.Mode.ParticleSelection

func _on_text_changed(new_text: String) -> void:
	visible = editable or new_text != ''
