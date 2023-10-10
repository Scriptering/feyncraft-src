extends Node

@onready var ParentButton: BaseButton = get_parent()
@export var mute: bool = false

func _ready() -> void:
	if !ParentButton: return
	
	ParentButton.button_down.connect(_on_parent_button_down)
	ParentButton.button_up.connect(_on_parent_button_up)

func _on_parent_button_down() -> void:
	if mute: return
	
	SOUNDBUS.button_down()

func _on_parent_button_up() -> void:
	if mute: return
	
	SOUNDBUS.button_up()
