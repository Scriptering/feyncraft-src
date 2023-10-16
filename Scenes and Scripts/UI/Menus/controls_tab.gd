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
	clear_diagram.emit()

func _on_undo_pressed() -> void:
	undo.emit()

func _on_redo_pressed() -> void:
	redo.emit()

func release_buttons() -> void:
	for control_button in [Snip, Grab]:
		control_button.button_pressed = false
