extends Node2D

@export var grid_margin: int

signal moved(current_position, old_position)
@onready var IdleCrosshair = $IdleCrosshair

const Z_INDEX_IDLE := 0
const Z_INDEX_DRAWING := 0

var can_draw: bool: get = _get_can_draw
var old_position: Vector2 = Vector2.ZERO
var clamp_left : float
var clamp_right : float
var clamp_up : float
var clamp_down : float
var on_state_line : bool
var is_inside_diagram : bool = false

var Diagram: DiagramBase
var Initial: StateLine
var Final: StateLine
var StateManager: Node
var grid_size: int

func _process(_event):
	move_crosshair()

func init(diagram: DiagramBase, state_lines: Array, gridsize: int) -> void:
	Diagram = diagram
	StateManager = diagram.StateManager
	
	StateManager.state_changed.connect(_state_changed)
	
	Initial = state_lines[StateLine.StateType.Initial]
	Final = state_lines[StateLine.StateType.Final]
	grid_size = gridsize
	
	clamp_left = Initial.position.x
	clamp_right = Final.position.x
	clamp_up = grid_size
	clamp_down = Diagram.size.y - grid_size

func move_crosshair() -> void:
	var try_position: Vector2 = get_try_position()
	
	if try_position == old_position:
		return
	
	if is_try_position_valid(try_position):
		position = try_position
		if position != old_position:
			moved.emit(position, old_position)
		old_position = position
	
	visible = get_state_visible(StateManager.state)

func get_try_position() -> Vector2:
	var mouse_position = get_parent().get_local_mouse_position()
	var try_position = Vector2(
		snapped(mouse_position.x-clamp_left, grid_size)+clamp_left,
		snapped(mouse_position.y-clamp_up, grid_size)+clamp_up
	)

	try_position = Vector2(
		clamp(try_position.x, clamp_left, clamp_right),
		clamp(try_position.y, clamp_up, clamp_down)
	)
	
	return try_position

func _get_can_draw() -> bool:
	if !is_inside_diagram:
		return false
	
	return is_start_drawing_position_valid()

func is_start_drawing_position_valid() -> bool:
	if is_crosshair_on_state_interaction(position):
		return false
	
	return true

func is_same_state_line(position1: Vector2, position2: Vector2) -> bool:
	if position1.x == Initial.position.x and position2.x == Initial.position.x:
		return true
	elif position1.x == Final.position.x and position2.x == Final.position.x:
		return true
	return false

func is_try_position_valid(try_position: Vector2) -> bool:
	if StateManager.state == BaseState.State.Drawing:
		return is_drawing_position_valid(try_position)
	
	if (
		StateManager.state == BaseState.State.Placing or
		(StateManager.state == BaseState.State.Hovering and StateManager.current_state.grabbed_interaction)
	):
		return is_placing_position_valid(try_position)
	
	return true

func is_drawing_position_valid(try_position: Vector2) -> bool:
	var start_drawing_position : Vector2 = StateManager.states[BaseState.State.Drawing].start_crosshair_position
	
	if is_same_state_line(try_position, start_drawing_position):
		return false
	
	if is_crosshair_on_state_interaction(try_position):
		return false
	
	return true

func is_placing_position_valid(try_position: Vector2) -> bool:
	if is_crosshair_on_state_interaction(try_position):
		return false
	
	var grabbed_interaction: Interaction = StateManager.current_state.grabbed_interaction
	
	if !grabbed_interaction:
		return true
	
	var moving_line_count: int = grabbed_interaction.connected_lines.size()
	
	if is_on_stateline(try_position):
		if StateManager.state == BaseState.State.Placing and moving_line_count > 1:
			return false
			
		if StateManager.state == BaseState.State.Hovering and !Input.is_action_pressed("split_interaction"):
			return false
			
	
		if grabbed_interaction.connected_lines.any(
			func(particle_line: ParticleLine):
				return particle_line.get_on_state_line() == Diagram.get_on_stateline(try_position)
		):
			return false
	
	return true

func is_hovering_position_valid(try_position: Vector2) -> bool:
	if is_crosshair_on_state_interaction(try_position):
		return false
	
	var grabbed_interaction: Interaction = StateManager.current_state.grabbed_interaction
	var moving_line_count: int = grabbed_interaction.connected_lines.size()
	
	if Input.is_action_pressed("split_interaction"):
		return true
	
	if is_on_stateline(try_position) and moving_line_count > 1:
		return false
	
	return true

func is_crosshair_on_state_interaction(test_position: Vector2 = position) -> bool:
	return is_on_stateline(test_position) and is_on_interaction(test_position)

func drawing_started() -> void:
	IdleCrosshair.frame = 1
	z_index = Z_INDEX_DRAWING

func drawing_ended() -> void:
	IdleCrosshair.frame = 0
	z_index = Z_INDEX_IDLE

func is_on_stateline(test_position: Vector2 = position) -> bool:
	return test_position.x == Initial.position.x or test_position.x == Final.position.x

func is_on_interaction(test_position: Vector2 = position) -> bool:
	for interaction in get_tree().get_nodes_in_group("interactions"):
		if test_position == interaction.position:
			return true
	return false

func DiagramMouseEntered():
	is_inside_diagram = true

func DiagramMouseExited():
	is_inside_diagram = false


func _state_changed(new_state: BaseState.State, _old_state: BaseState.State) -> void: 
	if !is_inside_tree():
		return
	
	visible = get_state_visible(new_state)

func get_state_visible(new_state: BaseState.State) -> bool:
	if new_state == BaseState.State.Idle:
		return can_draw
	
	if new_state == BaseState.State.Drawing:
		return true
	
	return false

