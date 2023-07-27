extends Node2D

enum {GENERATION, PUZZLE}

@onready var GenerationUI = get_node('GenerationUI')
@onready var PuzzleUI = get_node('PuzzleUI')
@onready var GenerationButton = get_node('GenerationButton')
@onready var PuzzleButton = get_node('PuzzleButton')

@onready var UI := [GenerationUI, PuzzleUI]
@onready var BUTTON := [GenerationButton, PuzzleButton]
@onready var N_BUTTONS = BUTTON.size()

func _ready():
	GenerationUI.visible = false
	PuzzleUI.visible = false

func _on_GenerationButton_pressed():
	handle_button_press(GENERATION)

func _on_PuzzleButton_pressed():
	handle_button_press(PUZZLE)

func handle_button_press(pressed_type : int) -> void:
	for type in range(N_BUTTONS):
		if type == pressed_type:
			BUTTON[type].set_active(!BUTTON[type].active)
			UI[type].visible = !UI[type].visible
		else:
			BUTTON[type].set_active(false)
			UI[type].visible = false
