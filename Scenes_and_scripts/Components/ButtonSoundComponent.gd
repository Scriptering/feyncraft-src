extends Node

var ParentButton : Variant = null
@export var mute: bool = false
@export var on_pressed: bool = false
@export var manual: bool = false

func _ready() -> void:
	if get_parent() == null or manual:
		return
	
	ParentButton = get_parent()
	ParentButton.button_down.connect(_on_parent_button_down)
	ParentButton.button_up.connect(_on_parent_button_up)
	ParentButton.pressed.connect(_on_parent_button_pressed)

func _on_parent_button_down() -> void:
	if on_pressed or manual: return
	
	play_button_down()

func _on_parent_button_up() -> void:
	if on_pressed or manual: return
	
	play_button_up()

func _on_parent_button_pressed() -> void:
	if !on_pressed or manual:
		return
	
	match ParentButton.action_mode:
		ParentButton.ACTION_MODE_BUTTON_PRESS:
			play_button_down()
		ParentButton.ACTION_MODE_BUTTON_RELEASE:
			play_button_up()

func play_button_down() -> void:
	if mute:
		return
	
	SOUNDBUS.button_down()

func play_button_up() -> void:
	if mute:
		return
	
	SOUNDBUS.button_up()
