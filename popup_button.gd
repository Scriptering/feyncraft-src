@tool
extends PanelButton
class_name PopUpButton

signal popup_opened
signal popup_closed

@export var popup_scene: PackedScene
@export var persistant: bool = false
var popup: Node

func _ready() -> void:
	super()
	
	if persistant:
		create_popup()
		popup.hide()
	
	hidden.connect(_on_hidden)

func _on_button_toggled(toggle: bool) -> void:
	super._on_button_toggled(toggle)
	
	if toggle:
		if persistant:
			popup.show()
		else:
			create_popup()
	else:
		if persistant:
			popup.hide()
		else:
			destroy_popup()

func create_popup() -> void:
	popup = popup_scene.instantiate()
	EventBus.add_floating_menu.emit(popup)
	popup.close.connect(close_popup)
	popup_opened.emit()

func destroy_popup() -> void:
	if is_instance_valid(popup):
		popup.queue_free()
		popup_closed.emit()

func close_popup() -> void:
	button_pressed = false
	destroy_popup()

func get_popup() -> Node:
	return popup 

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		destroy_popup()

func _on_hidden() -> void:
	close_popup()
