extends PullOutTab

signal exit_pressed
signal toggled_line_labels(button_pressed: bool)

@onready var exit: PanelContainer = $MovingContainer/ContentContainer/HBoxContainer/Exit
@onready var mute: PanelContainer = $MovingContainer/ContentContainer/HBoxContainer/Mute

func _on_exit_pressed() -> void:
	exit_pressed.emit()

func _on_show_labels_toggled(button_pressed: bool) -> void:
	toggled_line_labels.emit(button_pressed)
