extends BaseState

@onready var delay_timer := $delay
@export var delay_time: float = 0.3: set = _set_delay_time
@onready var interaction_scene := preload("res://Scenes_and_scripts/Diagram/interaction.tscn")
@onready var particle_line_scene := preload("res://Scenes_and_scripts/Diagram/particle_line.tscn")

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

func process(_delta: float) -> State:
	if drawing == true:
		return State.Placing
	return State.Null

func input(event: InputEvent) -> State:
	if Input.is_action_just_pressed("editing"):
		cancel_placement()
		return State.Hovering
	elif Input.is_action_just_pressed("deleting"):
		cancel_placement()
		return State.Deleting
	elif Input.is_action_just_pressed("clear"):
		cancel_placement()
	elif (
		(event is InputEventScreenTouch and event.is_released())
		or Input.is_action_just_released("click")
	):
		cancel_placement()
		return State.Idle
		
	return State.Null

func start_drawing() -> void:
	if drawing:
		return
	
	drawing = true
	Diagram.start_drawing(start_crosshair_position)

func crosshair_moved(current_position : Vector2, old_position : Vector2) -> void:
	if crosshair.is_same_state_line(current_position, old_position):
		return
	
	start_drawing()

func _on_delay_timeout() -> void:
	if state_manager.state == State.Drawing:
		start_drawing()

func cancel_placement() -> void:
	Diagram.remove_last_diagram_from_history()
