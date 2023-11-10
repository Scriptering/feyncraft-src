extends BaseState

@onready var delay_timer := $delay
@export var delay_time: float = 0.3: set = _set_delay_time
@onready var Interaction := preload("res://Scenes and Scripts/Diagram/interaction.tscn")
@onready var Line := preload("res://Scenes and Scripts/Diagram/line.tscn")

var drawing : bool = false
var start_crosshair_position : Vector2 = Vector2(0, 0)

func _ready() -> void:
	delay_timer.wait_time = delay_time

func _set_delay_time(new_value: float) -> void:
	if !is_inside_tree(): return
	delay_time = new_value
	delay_timer.wait_time = delay_time

func enter() -> void:
	super.enter()
	drawing = false
	start_crosshair_position = crosshair.position
	crosshair.drawing_started()
	delay_timer.start()

func exit() -> void:
	crosshair.drawing_ended()

func input(_event: InputEvent) -> State:
	if Input.is_action_just_pressed("editing"):
		cancel_placement()
		return State.Hovering
	elif Input.is_action_just_pressed("deleting"):
		cancel_placement()
		return State.Deleting
	elif Input.is_action_just_pressed("clear"):
		cancel_placement()
	elif Input.is_action_just_released("click"):
		if drawing:
			end_drawing()
			drawing = false
		return State.Idle
		
	return State.Null

func start_drawing() -> void:
	if Input.is_action_pressed("click") and !drawing:
		drawing = true
		Diagram.add_diagram_to_history()
		Diagram.place_line(start_crosshair_position)
		Diagram.place_interaction(start_crosshair_position)

func crosshair_moved(current_position : Vector2, old_position : Vector2) -> void:
	if crosshair.is_same_state_line(current_position, old_position):
		return
	
	start_drawing()

func _on_delay_timeout():
	if state_manager.state == State.Drawing:
		start_drawing()

func end_drawing() -> void:
	if !is_valid_end_position():
		cancel_placement()
		return
	
	for line in Diagram.get_particle_lines():
		if !line.is_placed:
			line.place()

	Diagram.place_interaction(crosshair.position)

func is_valid_end_position() -> bool:
	if crosshair.position == start_crosshair_position:
		return false
	return true

func cancel_placement() -> void:
	Diagram.remove_last_diagram_from_history()
	for line in Diagram.get_particle_lines():
		if !line.is_placed:
			Diagram.delete_line(line)

