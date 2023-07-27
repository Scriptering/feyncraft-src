extends PullOutTab

@export var avg_seconds_per_blink := 6000

enum Vision {Colour, Shade, Strength}

var eye_open := load("res://Textures/Buttons/eye/eye_open.png")
var eye_middle := load("res://Textures/Buttons/eye/eye_middle.png")
var eye_closed := load("res://Textures/Buttons/eye/eye_closed.png")

signal vision_button_toggled

func _physics_process(delta: float) -> void:
	if 1-(delta/avg_seconds_per_blink) < randf():
		blink()
		
func blink() -> void:
	print("blink")
	$AnimationPlayer.play("blink")
	$AnimationPlayer.play_backwards("blink")

func get_active_visions() -> Array[Vision]:
	var active_visions : Array[Vision] = []
	for i in range($MovingContainer/Tab/MovingContainer.get_children().size()):
		if $MovingContainer/Tab/MovingContainer.get_children()[i].button_pressed:
			active_visions.append(i)
	return active_visions

func _on_colour_toggled(button_pressed):
	emit_signal("vision_button_toggled", Vision.Colour, button_pressed)

func _on_shade_toggled(button_pressed):
	emit_signal("vision_button_toggled", Vision.Shade, button_pressed)

func _on_strength_toggled(button_pressed):
	RenderingServer.global_shader_parameter_set("interaction_strength_showing", button_pressed)
	emit_signal("vision_button_toggled", Vision.Strength, button_pressed)

