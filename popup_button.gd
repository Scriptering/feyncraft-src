@tool
extends PanelButton
class_name PopUpButton

@export var popup_scene: PackedScene
var popup: Node

func _on_button_toggled(toggle: bool) -> void:
	super._on_button_toggled(toggle)
	
	if toggle:
		create_popup()
	else:
		destroy_popup()

func create_popup() -> void:
	popup = popup_scene.instantiate()
	EventBus.add_floating_menu.emit(popup)
	popup.close.connect(close_popup)

func destroy_popup() -> void:
	popup.queue_free()

func close_popup() -> void:
	button_pressed = false
	destroy_popup()
