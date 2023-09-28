class_name InfoPanel
extends PanelContainer

signal previous
signal next
signal exit

@export var next_button: PanelButton
@export var prev_button: PanelButton
@export var exit_button: PanelButton

func _ready() -> void:
	if next_button:
		next_button.pressed.connect(_next)
	if prev_button:
		prev_button.pressed.connect(_prev)
	if exit_button:
		exit_button.pressed.connect(_exit)

func _next() -> void:
	next.emit()

func _prev() -> void:
	previous.emit()

func _exit() -> void:
	exit.emit()
