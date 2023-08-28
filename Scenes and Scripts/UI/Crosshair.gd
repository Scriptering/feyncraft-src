extends Node2D

@export var grid_margin: int

signal moved(current_position, old_position)
@onready var Level = get_tree().get_nodes_in_group('level')[0]
@onready var StateManager = Level.get_node("state_manager")
@onready var IdleCrosshair = $IdleCrosshair
@onready var InteractionCrosshair = $InteractionCrosshair

const Z_INDEX_IDLE := 0
const Z_INDEX_DRAWING := 0

var can_draw: bool
var old_position: Vector2 = Vector2.ZERO
var clamp_left : float
var clamp_right : float
var clamp_up : float
var clamp_down : float
var on_state_line : bool

var Diagram: DiagramBase
var Initial: StateLine
var Final: StateLine
var grid_size: int

func _process(_event):
	move_crosshair()

func init(diagram: DiagramBase, state_lines: Array, gridsize: int) -> void:
	Diagram = diagram
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
			emit_signal("moved", position, old_position)
		old_position = position

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

func is_same_state_line(position1: Vector2, position2: Vector2) -> bool:
	if position1.x == Initial.position.x and position2.x == Initial.position.x:
		return true
	elif position1.x == Final.position.x and position2.x == Final.position.x:
		return true
	return false

func is_try_position_valid(try_position: Vector2) -> bool:
	if StateManager.state == BaseState.State.Drawing:
		return is_drawing_position_valid(try_position)
	
	elif StateManager.state == BaseState.State.Placing:
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
	
	var interactions := Diagram.get_interactions()
	
	if interactions.size() > 0 and interactions.front().number_of_placing_lines > 1 and is_on_stateline(try_position):
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

func interaction_picked_up(interaction: Interaction) -> void:
	z_index = Z_INDEX_DRAWING
	
	InteractionCrosshair.show()
	IdleCrosshair.hide()
	
	if interaction.get_on_state_line() == StateLine.StateType.None:
		$InteractionDot.visible = interaction.Dot.visible
	InteractionCrosshair.animation = interaction.Ball.animation
	
	print($InteractionDot.visible)

func interaction_placed(_interaction: Interaction) -> void:
	IdleCrosshair.show()
	InteractionCrosshair.hide()
	$InteractionDot.hide()

func is_on_stateline(test_position: Vector2 = position) -> bool:
	return test_position.x == Initial.position.x or test_position.x == Final.position.x

func is_on_interaction(test_position: Vector2 = position) -> bool:
	for interaction in get_tree().get_nodes_in_group("interactions"):
		if test_position == interaction.position:
			return true
	return false

func DiagramMouseEntered():
	show()
	can_draw = true

func DiagramMouseExited():
	if StateManager.state != BaseState.State.Placing and StateManager.state != BaseState.State.Drawing:
		hide()
	can_draw = false

func _state_changed(new_state: BaseState.State, _old_state: BaseState.State) -> void: 
	if new_state == BaseState.State.Idle:
		visible = can_draw
		
