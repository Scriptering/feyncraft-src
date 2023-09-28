extends Control

var level := preload("res://Scenes and Scripts/Levels/world.tscn")

func _ready() -> void:
	EVENTBUS.signal_enter_game.connect(enter_game)

func _process(_delta: float) -> void:
	update_cursor()
	
func update_cursor() -> void:
	var hovering_disabled := get_tree().get_nodes_in_group("button").any(
		func(button: PanelButton): return button.disabled and button.is_hovered
	)
	
	if hovering_disabled:
		$Cursor.change_cursor(GLOBALS.CURSOR.disabled)
	elif Input.is_action_pressed("click"):
		$Cursor.change_cursor(GLOBALS.CURSOR.press)
	else:
		$Cursor.change_cursor(GLOBALS.CURSOR.default)

func enter_game() -> void:
	get_tree().change_scene_to_packed(level)
