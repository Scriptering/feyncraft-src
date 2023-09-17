extends Node

signal mode_changed

var modes : Dictionary = {}

var current_mode: BaseMode
var previous_mode: BaseMode.Mode
var mode: BaseMode.Mode

func _ready() -> void:
	for mode in get_children():
		modes[mode.mode] = mode

func change_mode(new_mode: BaseMode.Mode) -> void:
	if current_mode:
		current_mode.exit()
	
	emit_signal("mode_changed", new_mode, mode)
	previous_mode = mode
	current_mode = modes[new_mode]
	mode = new_mode
	current_mode.enter()

func get_modes() -> Array[BaseMode]:
	var Modes: Array[BaseMode] = []
	
	for mode in modes.values():
		Modes.push_back(mode)
	
	return Modes

func init(Level: Node2D, start_mode: BaseMode.Mode) -> void:
	for mode in get_modes():
		mode.VisionTab = Level.VisionTab
		mode.GenerationTab = Level.GenerationTab
		mode.OptionsTab = Level.OptionsTab
		mode.ProblemTab = Level.ProblemTab
		mode.ParticleButtons = Level.ParticleButtons

	change_mode(start_mode)

func _input(event: InputEvent) -> void:
	var new_mode = current_mode.input(event)
	if new_mode != BaseMode.Mode.Null:
		change_mode(new_mode)

func _process(delta: float) -> void:
	var new_mode = current_mode.process(delta)
	if new_mode != BaseMode.Mode.Null:
		change_mode(new_mode)

func _physics_process(delta: float) -> void:
	var new_mode = current_mode.physics_process(delta)
	if new_mode != BaseMode.Mode.Null:
		change_mode(new_mode)
