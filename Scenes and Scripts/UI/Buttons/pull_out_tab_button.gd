@tool
extends MarginContainer

signal pressed

@export var ArrowIn: Texture2D
@export var ArrowOut: Texture2D
@export var TabIcon: Texture2D : set = _set_tab_icon
@export var TabText: String : set = _set_tab_text
@export var TabMinimumSize: Vector2 : set = _set_tab_minimum_size

@onready var TabButton = $TabButton

func _ready() -> void:
	if !TabButton.is_connected("pressed", Callable(self, "_on_tab_button_pressed")):
		$TabButton.connect("pressed", Callable(self, "_on_tab_button_pressed"))
	return

func change_state(tab_out: bool) -> void:
	if tab_out:
		$VBoxContainer/MarginContainer/Arrow.texture = ArrowOut
	else:
		$VBoxContainer/MarginContainer/Arrow.texture = ArrowIn

func _set_tab_icon(new_value: Texture2D) -> void:
	TabIcon = new_value
	
	$TabButton.icon = new_value

func _set_tab_text(new_value: String) -> void:
	TabText = new_value
	
	$TabButton.text = new_value

func _set_tab_minimum_size(new_value: Vector2) -> void:
	TabMinimumSize = new_value
	
	if get_child_count() == 0: return
	
	$TabButton.minimum_size = new_value
	

func _on_tab_button_pressed():
	emit_signal("pressed")
