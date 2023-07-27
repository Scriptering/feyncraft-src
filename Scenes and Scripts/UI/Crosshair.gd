extends Node2D

@export var grid_size: int
@export var grid_margin: int

signal moved(current_position, old_position)
@onready var Level = get_tree().get_nodes_in_group('level')[0]
@onready var StateManager = Level.get_node("state_manager")
@onready var GridArea: Panel = Level.get_node('GridArea')
@onready var Initial = Level.get_node('Initial')
@onready var Final = Level.get_node('Final')
@onready var IdleCrosshair = $IdleCrosshair
@onready var InteractionCrosshair = $InteractionCrosshair

const Z_INDEX_IDLE := 1
const Z_INDEX_DRAWING := 3

var can_draw: bool
var old_position: Vector2 = Vector2.ZERO
var clamp_left : float
var clamp_right : float
var clamp_up : float
var clamp_down : float
var on_state_line : bool

func _ready():
	clamp_left = Initial.position.x
	clamp_right = Final.position.x
	clamp_up = GridArea.position.y + grid_size
	clamp_down = GridArea.position.y + GridArea.size.y - grid_size
	
	GridArea.connect("mouse_entered", Callable(self, "GridAreaMouseEntered"))
	GridArea.connect("mouse_exited", Callable(self, "GridAreaMouseExited"))

func _process(_event):
	move_crosshair()

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
	var mouse_position = get_global_mouse_position()
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
	
	if (
		get_tree().get_first_node_in_group("interactions").number_of_placing_lines > 1 and
		is_on_stateline(try_position)
	):
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

func GridAreaMouseEntered():
	show()
	can_draw = true

func GridAreaMouseExited():
	if StateManager.state != BaseState.State.Placing and StateManager.state != BaseState.State.Drawing:
		hide()
	can_draw = false

func _state_changed(new_state: BaseState.State, _old_state: BaseState.State) -> void: 
	if new_state == BaseState.State.Idle:
		visible = can_draw
		
