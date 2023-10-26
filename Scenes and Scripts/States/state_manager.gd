extends Node

signal state_changed

@onready var states = {
	BaseState.State.Idle: $idle,
	BaseState.State.Hovering: $hovering,
	BaseState.State.Placing: $placing,
	BaseState.State.Deleting: $deleting,
	BaseState.State.Drawing: $drawing
}

var current_state: BaseState
var previous_state: BaseState.State
var state: BaseState.State

func change_state(new_state: BaseState.State) -> void:
	if current_state:
		current_state.exit()
	
	state_changed.emit(new_state, state)
	previous_state = state
	current_state = states[new_state]
	state = new_state
	current_state.enter()

func init(Diagram: DiagramBase) -> void:
	var crosshair = Diagram.get_node("DiagramArea/Crosshair")
	
	for child in get_children():
		child.change_cursor.connect(Callable(EVENTBUS.change_cursor))
		child.state_manager = self
		child.Diagram = Diagram
		child.crosshair = crosshair
		
	crosshair.moved.connect(crosshair_moved)
	state_changed.connect(crosshair._state_changed)
	change_state(BaseState.State.Idle)

func change_scene(Diagram: DiagramBase) -> void:
	var crosshair = Diagram.get_node("DiagramArea/Crosshair")
	
	for child in get_children():
		child.Diagram = Diagram
		child.crosshair = crosshair
	
	if !crosshair.moved.is_connected(crosshair_moved):
		crosshair.moved.connect(crosshair_moved)

func _input(event: InputEvent) -> void:
	var new_state = current_state.input(event)
	if new_state != BaseState.State.Null:
		change_state(new_state)

func _process(delta: float) -> void:
	var new_state = current_state.process(delta)
	if new_state != BaseState.State.Null:
		change_state(new_state)

func _physics_process(delta: float) -> void:
	var new_state = current_state.physics_process(delta)
	if new_state != BaseState.State.Null:
		change_state(new_state)

func crosshair_moved(current_position: Vector2, old_position: Vector2) -> void:
	current_state.crosshair_moved(current_position, old_position)
