extends Node2D
class_name Crosshair

@export var grid_margin: int

signal moved_and_rested(current_position: Vector2i, old_position: Vector2i)
signal moved(current_position: Vector2i, old_position: Vector2i)
@onready var IdleCrosshair := $IdleCrosshair

var move_timer: Timer = Timer.new()

const Z_INDEX_IDLE := 0
const Z_INDEX_DRAWING := 0

var old_position: Vector2 = Vector2.ZERO
var old_global_position: Vector2 = Vector2.ZERO
var clamp_left : float
var clamp_right : float
var clamp_up : float
var clamp_down : float
var on_state_line : bool

var Diagram: DiagramBase
var Initial: StateLine
var Final: StateLine
var StateManager: Node
var grid_size: int

var drag_finger_index: int = -1

var last_input_inside_area: bool = false

var inside_diagram_control: bool = false
var inside_crosshair_area: bool = false
var fingers_inside_crosshair_area: Dictionary = {
	0: false,
	1: false,
	2: false,
	3: false,
	4: false
}

func _input(event: InputEvent) -> void:
	if Globals.is_on_mobile():
		handle_mobile_event(event)

	elif event is InputEventMouseMotion:
		var mouse_position: Vector2 = get_parent().get_local_mouse_position()
		last_input_inside_area = is_inside_crosshair_area(mouse_position)
		move(mouse_position)
		visible = get_state_visible(StateManager.state)

func handle_mobile_event(event: InputEvent) -> void:
	if event is InputEventScreenDrag or (event is InputEventScreenTouch and event.pressed):
		handle_drag(event)
	elif event is InputEventScreenTouch and event.is_released():
		if drag_finger_index == event.index:
			drag_finger_index = -1
		visible = false

func handle_drag(event: InputEvent) -> void:
	var drag_position: Vector2 = event.position - get_parent().global_position
	var in_crosshair_area: bool = is_inside_crosshair_area(drag_position)
	if in_crosshair_area != fingers_inside_crosshair_area[event.index]:
		if in_crosshair_area:
			EventBus.crosshair_area_finger_entered.emit(event.index)
		else:
			EventBus.crosshair_area_finger_exited.emit(event.index)
		fingers_inside_crosshair_area[event.index] = in_crosshair_area
	last_input_inside_area = in_crosshair_area
	
	if !in_crosshair_area:
		return
	
	if drag_finger_index == -1:
		drag_finger_index = event.index
	
	if event.index != drag_finger_index:
		return
	
	visible = get_state_visible(StateManager.state)
	move(drag_position)

func _ready() -> void:
	EventBus.diagram_mouse_entered.connect(_diagram_mouse_entered)
	EventBus.diagram_mouse_exited.connect(_diagram_mouse_exited)

func init(diagram: DiagramBase, state_lines: Array, gridsize: int) -> void:
	Diagram = diagram
	StateManager = diagram.StateManager
	
	StateManager.state_changed.connect(_state_changed)
	
	Initial = state_lines[StateLine.State.Initial]
	Final = state_lines[StateLine.State.Final]
	grid_size = gridsize
	
	clamp_left = Initial.position.x
	clamp_right = Final.position.x
	clamp_up = grid_size
	clamp_down = Diagram.size.y - grid_size
	
	add_child(move_timer)
	move_timer.one_shot = true
	move_timer.wait_time = 0.01
	move_timer.timeout.connect(
		func() -> void:
			moved_and_rested.emit(position, old_position)
	)

func is_inside_crosshair_area(pos: Vector2) -> bool:
	var try_position := Vector2(
		snapped(pos.x-clamp_left, grid_size)+clamp_left,
		snapped(pos.y-clamp_up, grid_size)+clamp_up
	)
	
	return (
		try_position.x < clamp_right + grid_size
		&& try_position.x > clamp_left - grid_size
		&& try_position.y < clamp_down + grid_size
		&& try_position.y > clamp_up - grid_size
	)

func move(try_position: Vector2) -> void:
	var temp: bool = is_inside_crosshair_area(try_position)
	if temp != inside_crosshair_area:
		if temp:
			EventBus.crosshair_area_mouse_entered.emit()
		else:
			EventBus.crosshair_area_mouse_exited.emit()
	
		inside_crosshair_area = temp
	
	try_position = snap_and_clamp(try_position)
	
	if try_position == old_position:
		return
	
	if is_try_position_valid(try_position):
		position = try_position
		if position != old_position:
			move_timer.start()
			moved.emit(position, old_position)
			EventBus.crosshair_moved.emit(global_position, old_global_position)
		old_position = position
		old_global_position = global_position

func positioni() -> Vector2i:
	return position

func snap_and_clamp(pos: Vector2) -> Vector2:
	pos = Vector2(
		snapped(pos.x-clamp_left, grid_size)+clamp_left,
		snapped(pos.y-clamp_up, grid_size)+clamp_up
	)

	pos = Vector2(
		clamp(pos.x, clamp_left, clamp_right),
		clamp(pos.y, clamp_up, clamp_down)
	)
	
	return pos

func is_start_drawing_position_valid() -> bool:
	if !is_inside_crosshair_area(position):
		return false
	
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
		StateManager.state == BaseState.State.Hovering
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
	var grabbed_object: Node = StateManager.current_state.grabbed_object
	
	if !(grabbed_object is Interaction):
		return true
	
	if Diagram.get_on_stateline(try_position) == StateLine.State.None:
		return true
	
	if is_crosshair_on_state_interaction(try_position):
		return false
	
	if !grabbed_object:
		return true
	
	var moving_line_count: int = grabbed_object.connected_lines.size()
	if moving_line_count > 1:
		if StateManager.state == BaseState.State.Placing:
			return false
			
		if StateManager.state == BaseState.State.Hovering and !Input.is_action_pressed("split_interaction"):
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
	for interaction:Interaction in get_tree().get_nodes_in_group("interactions"):
		if test_position == interaction.position:
			return true
	return false

func _diagram_mouse_entered() -> void:
	inside_diagram_control = true

func _diagram_mouse_exited() -> void:
	inside_diagram_control = false

func _state_changed(new_state: BaseState.State, _old_state: BaseState.State) -> void: 
	if !is_inside_tree():
		return
	
	visible = get_state_visible(new_state)

func get_state_visible(new_state: BaseState.State) -> bool:
	if !inside_diagram_control:
		return false
	
	if new_state == BaseState.State.Idle:
		return is_start_drawing_position_valid()
	
	if new_state == BaseState.State.Drawing:
		return true
	
	if new_state == BaseState.State.Deleting:
		return false
	
	return false
