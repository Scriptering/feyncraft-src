extends PullOutTab

@onready var ButtonContainer: VBoxContainer = $MovingContainer/Tab/ButtonContainer

@export var avg_seconds_per_blink := 6000

var eye_open := load("res://Textures/Buttons/eye/eye_open.png")
var eye_middle := load("res://Textures/Buttons/eye/eye_middle.png")
var eye_closed := load("res://Textures/Buttons/eye/eye_closed.png")

signal vision_button_toggled(active_vision: GLOBALS.Vision)

var vision_button_group: ButtonGroup = ButtonGroup.new()

func _ready() -> void:
	super._ready()
	
	vision_button_group.allow_unpress = true
	for button in ButtonContainer.get_children():
		button.button_group = vision_button_group
	
	vision_button_group.pressed.connect(_vision_button_toggled)

func _physics_process(delta: float) -> void:
	if 1-(delta/avg_seconds_per_blink) < randf():
		blink()
		
func blink() -> void:
	print("blink")
	$AnimationPlayer.play("blink")
	$AnimationPlayer.play_backwards("blink")

func get_active_vision() -> GLOBALS.Vision:
	for i in range(ButtonContainer.get_children().size()):
		if ButtonContainer.get_children()[i].button_pressed:
			return i
	return GLOBALS.Vision.None

func _vision_button_toggled(_button: Button) -> void:
	vision_button_toggled.emit(get_active_vision())
