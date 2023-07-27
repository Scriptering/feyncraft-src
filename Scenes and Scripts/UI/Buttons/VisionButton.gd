extends 'BaseButton.gd'

@onready var Level = get_tree().get_nodes_in_group('level')[0]

var blinking = false

enum EYE {OPEN, MIDDLE, CLOSED}

var vision_buttons : Array = []

var eyeframes = [preload('res://Textures/Buttons/eye/eye_open.png'), preload('res://Textures/Buttons/eye/eye_middle.png'),
preload('res://Textures/Buttons/eye/eye_closed.png')]

var state = GLOBALS.VISION_TYPE.NONE

func _ready():
	for vision_button in get_tree().get_nodes_in_group('vbuttons'):
		vision_buttons.append(vision_button)
		vision_button.connect('pressed', Callable(self, 'vision_button_pressed'))
		vision_button.visible = false

func _on_Button_pressed():
	for button in vision_buttons:
		button.visible = !button.visible

func _process(_delta):
	if randi() % 10000 == 0 and !blinking:
		blink()

func blink():
	blinking = true
	button.change_icon(eyeframes[EYE.OPEN])
	await get_tree().create_timer(0.03).timeout
	button.change_icon(eyeframes[EYE.MIDDLE])
	await get_tree().create_timer(0.03).timeout
	button.change_icon(eyeframes[EYE.CLOSED])
	await get_tree().create_timer(0.03).timeout
	button.change_icon(eyeframes[EYE.MIDDLE])
	await get_tree().create_timer(0.03).timeout
	button.change_icon(eyeframes[EYE.OPEN])
	blinking = false

func switch_state(new_state : int) -> void:
	if state != new_state:
		state = new_state
		
		set_active(true)
		
		for button in vision_buttons:
			if button.STATE == state:
				button.set_active(true)
			else:
				button.set_active(false)
		
	else:
		state = GLOBALS.VISION_TYPE.NONE
		
		set_active(false)
		
		for button in vision_buttons:
			button.set_active(false)

func vision_button_pressed(pressed_button : Object):
	switch_state(pressed_button.STATE)
	
	Level.show_vision(state, pressed_button.active)
