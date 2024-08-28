extends Node2D

@onready var tooltip:Tooltip = $Tooltip
@onready var tile:Decoration = $Decoration

var start_pos: Vector2
var min_message_distance: float = 8
var message_shown: bool = false
var shown_first_message: bool = false

const messages: Array[String] = [
	"Please put that back.",
	"What a nice graph you have.",
	"I hope you're enjoying the game!"
]

func _input(event: InputEvent) -> void:
	if message_shown:
		return
	
	if !event is InputEventMouseMotion:
		return
	
	if !tile.grabbed:
		return
	
	if (tile.position - start_pos).length() >= min_message_distance:
		show_message()

func show_message() -> void:
	message_shown = true
	
	if !shown_first_message:
		shown_first_message = true
		tooltip.tooltip = "Hello there!"
		tooltip.show_tooltip()
		return
	
	if randf() > 0.5:
		tooltip.tooltip = messages.pick_random()
		tooltip.show_tooltip()

func _on_decoration_picked_up(obj: GrabbableControl) -> void:
	start_pos = obj.position

func _on_decoration_dropped(_object: GrabbableControl) -> void:
	message_shown = false
