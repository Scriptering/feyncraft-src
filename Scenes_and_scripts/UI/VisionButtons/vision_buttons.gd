extends PullOutTab

@onready var ButtonContainer: VBoxContainer = $MovingContainer/Tab/ButtonContainer

@export var avg_seconds_per_blink := 2000

var eye_open := preload("res://Textures/Buttons/eye/eye_open.png")
var eye_middle := preload("res://Textures/Buttons/eye/eye_middle.png")
var eye_closed := preload("res://Textures/Buttons/eye/eye_closed.png")

signal vision_button_toggled(active_vision: Globals.Vision, toggle: bool)

var vision_button_group: ButtonGroup = ButtonGroup.new()

func _ready() -> void:
	super._ready()
	
	vision_button_group.allow_unpress = true
	for button in ButtonContainer.get_children():
		button.button_group = vision_button_group
	
	vision_button_group.pressed.connect(_vision_button_toggled)

func _physics_process(delta: float) -> void:
	if 1-(delta*60/avg_seconds_per_blink) < randf():
		blink()
		
func blink() -> void:
	print("blink")
	$AnimationPlayer.play("blink")
	$AnimationPlayer.play_backwards("blink")

func get_active_vision() -> Globals.Vision:
	for i:int in range(ButtonContainer.get_children().size()):
		if ButtonContainer.get_children()[i].button_pressed:
			return i as Globals.Vision
	return Globals.Vision.None

func _vision_button_toggled(button: Button) -> void:
	vision_button_toggled.emit(get_active_vision(), button.button_pressed)
