extends Tooltip

func _ready() -> void:
	super._ready()
	ClipBoard.copied.connect(_clipboard_copied)
	ClipBoard.pasted.connect(_clipboard_pasted)
	EventBus.show_feedback.connect(
		func(feedback: String) -> void:
			tooltip = feedback
			show_tooltip()
	)

func _clipboard_copied() -> void:
	tooltip = "Copied to clipboard!"
	show_tooltip()

func _clipboard_pasted() -> void:
	tooltip = "Pasted from clipboard!"
	show_tooltip()
