extends Node

@onready var ParentButton: BaseButton = get_parent()
@export var mute: bool = false
@export var on_pressed: bool = false

func _ready() -> void:
	if !ParentButton: return
	
	ParentButton.button_down.connect(_on_parent_button_down)
	ParentButton.button_up.connect(_on_parent_button_up)
	ParentButton.pressed.connect(_on_parent_button_pressed)

func _on_parent_button_down() -> void:
	if mute or on_pressed: return
	
	SOUNDBUS.button_down()

func _on_parent_button_up() -> void:
	if mute or on_pressed: return
	
	SOUNDBUS.button_up()

func _on_parent_button_pressed() -> void:
	if !on_pressed:
		return
	
	match ParentButton.action_mode:
		ParentButton.ACTION_MODE_BUTTON_PRESS:
			SOUNDBUS.button_down()
		ParentButton.ACTION_MODE_BUTTON_RELEASE:
			SOUNDBUS.button_up()
