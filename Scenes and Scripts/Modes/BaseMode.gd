extends Node
class_name BaseMode

@export var mode: Mode

enum Mode {
	ParticleSelection,
	ProblemCreation,
	SolutionCreation,
	Sandbox,
	ProblemSolving,
	Null
}

var ProblemTab: Control
var VisionTab: Control
var GenerationTab: Control
var MenuTab: Control
var ParticleButtons: Control
var CreationInformation: Control

func enter() -> void:
	toggle_menu_visibility()
	CreationInformation.change_mode(mode)

func exit() -> void:
	pass

func input(_event: InputEvent) -> Mode:
	return Mode.Null

func process(_delta: float) -> Mode:
	return Mode.Null

func physics_process(_delta: float) -> Mode:
	return Mode.Null

func toggle_menu_visibility() -> void:
	pass
