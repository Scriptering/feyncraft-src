extends PullOutTab

@onready var Snip : PanelButton = $MovingContainer/ContentContainer/GridContainer/Snip
@onready var Grab : PanelButton = $MovingContainer/ContentContainer/GridContainer/Grab
@onready var Clear : PanelButton = $MovingContainer/ContentContainer/GridContainer/Reset
@onready var Undo : PanelButton = $MovingContainer/ContentContainer/GridContainer/Undo
@onready var Redo : PanelButton = $MovingContainer/ContentContainer/GridContainer/Redo

signal clear_diagram
signal undo
signal redo

func _on_reset_pressed() -> void:
	emit_signal("clear_diagram")

func _on_undo_pressed() -> void:
	emit_signal("undo")

func _on_redo_pressed() -> void:
	emit_signal("redo")
