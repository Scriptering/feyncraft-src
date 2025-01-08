extends PanelContainer

signal clicked_on

func _ready() -> void:
	$Button.text = "v%s"%[ProjectSettings.get_setting("application/config/version")]


func _on_button_pressed() -> void:
	clicked_on.emit()
