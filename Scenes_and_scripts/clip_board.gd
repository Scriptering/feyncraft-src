extends Node

signal copied()
signal pasted()

func copy(content: String) -> void:
	DisplayServer.clipboard_set(content)
	copied.emit()

func paste() -> String:
	pasted.emit()
	return DisplayServer.clipboard_get()
