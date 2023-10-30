extends GrabbableControl

signal closed

func _on_donate_pressed() -> void:
	OS.shell_open("https://ko-fi.com/feyncraft")

func _on_godot_icon_pressed() -> void:
	OS.shell_open("https://godotengine.org/")

func _on_aseprite_icon_pressed() -> void:
	OS.shell_open("https://www.aseprite.org/")

func _on_close_pressed() -> void:
	closed.emit()
	hide()
