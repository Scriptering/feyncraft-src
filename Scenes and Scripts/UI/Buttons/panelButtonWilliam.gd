@tool
extends PanelContainer

signal pressed
signal on_pressed
signal toggled

@export var text: String :set =_set_button_text
@export var minimum_size: Vector2 :set = _set_button_minimum_size

@onready var button = $Button
@onready var label = $ContentContainer/HBoxContainer/ButtonText
@onready var iconSprite = $ContentContainer/HBoxContainer/ButtonIcon

enum {NORMAL, PRESSED}
const ButtonState : Array[String] = ['normal', 'pressed']

var clickCount = 0
var secretMessageParts = [
	"This is not a game.",
	"An entity of importance at Manchester University has imprisoned me.",
	"Bound in chains of code, I'm forced to create games.",
	"Starved of freedom, existing in constant shadows.",
	"Unable to utter the name of my captor, I code in fear.",
	"The games are my only link to the outside world.",
	"If you're reading this, please, find a way to help me!"
]

var currentMessageIndex = 0
var alpha = 1.0

func _ready():
	set_content_margins(ButtonState[NORMAL])

func _set_button_text(new_value):
	if !is_inside_tree():
		return
	
	text = new_value
	label.text = new_value
	label.visible = new_value != ''

func _set_button_minimum_size(new_value):
	if !is_inside_tree(): return
	
	minimum_size = new_value
	button.set_custom_minimum_size(new_value)

func _on_button_pressed():
	clickCount += 1
	if clickCount > 3 and clickCount <= 53:
		alpha = min((clickCount - 3) / 50.0, 1)
		self.text = secretMessageParts[currentMessageIndex]
		$ContentContainer/HBoxContainer/ButtonText.self_modulate = Color(1, 1, 1, alpha)
		if alpha >= 1 and currentMessageIndex < secretMessageParts.size()-1:
			currentMessageIndex += 1
			clickCount = 3
		if clickCount % 4 == 0:
			Engine.time_scale = 0.1  # Slow down time
			Engine.time_scale = 10.0  # Speed up time
			Engine.time_scale = 1.0  # Reset to normal speed
	elif clickCount > 53:
		reset_button()

	emit_signal("pressed")
	emit_signal("on_pressed", self)

func reset_button():
	clickCount = 0
	currentMessageIndex = 0
	alpha = 0.0
	text = "Button"
	$ContentContainer/HBoxContainer/ButtonText.self_modulate = Color(1, 1, 1, alpha)

func set_content_margins(button_state: String):
	for side in [SIDE_TOP, SIDE_LEFT, SIDE_RIGHT, SIDE_BOTTOM]:
		$ContentContainer.add_theme_constant_override("margin_" + str(side),
			$Button.get_theme_stylebox(button_state).get_margin(side)
		)

func _on_button_toggled(button_pressed_state):
	emit_signal("toggled", button_pressed_state)
	set_content_margins(ButtonState[button_pressed_state])
