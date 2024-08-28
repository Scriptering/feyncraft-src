extends Node

@onready var parent : Variant = get_parent()

func _ready() -> void:
	parent.mouse_entered.connect(_on_parent_mouse_entered)
	parent.mouse_exited.connect(_on_parent_mouse_exited)

func _on_parent_mouse_entered() -> void:
	if parent.disabled:
		EventBus.show_disabled.emit()

func _on_parent_mouse_exited() -> void:
	if parent.disabled:
		EventBus.hide_disabled.emit()
