extends Area2D

signal button_down()
signal button_up()
signal pressed()

@export var action_mode := BaseButton.ACTION_MODE_BUTTON_PRESS
@export var button_mask := MOUSE_BUTTON_LEFT

var hover := false
var button_pressed := false: set = _set_button_pressed

func _set_button_pressed(new_value: bool) -> void:
	if button_pressed == new_value:
		return
	
	button_pressed = new_value
	
	if button_pressed:
		button_down.emit()
	else:
		button_up.emit()

func _input(event: InputEvent) -> void:
	if !event is InputEventMouseButton:
		return
	
	handle_event(event)

func _on_mouse_entered() -> void:
	hover = true

func _on_mouse_exited() -> void:
	hover = false

func handle_event(event: InputEventMouseButton) -> void:
	if event.button_index != button_mask:
		return

	if !hover:
		self.button_pressed = false
		return
		

	if self.button_pressed == event.pressed:
		return
	
	self.button_pressed = event.pressed
	if event.pressed == (action_mode == BaseButton.ACTION_MODE_BUTTON_PRESS):
		pressed.emit()
