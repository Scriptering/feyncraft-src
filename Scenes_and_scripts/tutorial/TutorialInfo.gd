extends GrabbableControl

signal next_pressed
signal prev_pressed
signal finish_pressed

@export var Text: Label

func _on_prev_step_pressed() -> void:
	prev_pressed.emit()

func _on_next_step_pressed() -> void:
	next_pressed.emit()

func _on_finish_pressed() -> void:
	finish_pressed.emit()

func set_text(text: String) -> void:
	Text.text = text

func show_finish() -> void:
	$TutorialPanel/VBoxContainer/Buttons/Finish.show()

func hide_finish() -> void:
	$TutorialPanel/VBoxContainer/Buttons/Finish.hide()

func show_next() -> void:
	$TutorialPanel/VBoxContainer/Buttons/NextStep.show()

func hide_next() -> void:
	$TutorialPanel/VBoxContainer/Buttons/NextStep.hide()

func show_prev() -> void:
	$TutorialPanel/VBoxContainer/Buttons/PrevStep.show()

func hide_prev() -> void:
	$TutorialPanel/VBoxContainer/Buttons/PrevStep.hide()
