extends Node2D

@onready var Spotlight: PackedScene = preload("res://Scenes and Scripts/tutorial/spotlight.tscn")
@onready var Spotlights: Control = $CanvasGroup/Spotlights
@onready var TutorialInfo: GrabbableControl = $TutorialInfo

var current_step: BaseTutorialStep

var current_index: int:
	get:
		return get_steps().find(current_step)

signal load_hadron_problem

func _ready() -> void:
	$Steps/Hadrons.load_hadron_problem.connect(
		func(): load_hadron_problem.emit()
	)
	current_step = get_steps().front()

func get_steps() -> Array[BaseTutorialStep]:
	var steps: Array[BaseTutorialStep] = []
	
	for child in $Steps.get_children():
		steps.append(child)
	
	return steps

func init(world: Node2D) -> void:
	for step in get_steps():
		step.init(world)
	
	change_step(get_steps().front())

func clear() -> void:
	toggle_spotlight(false)
	clear_spotlights()

func toggle_spotlight(toggle: bool) -> void:
	$CanvasGroup.visible = toggle

func set_spotlight(p_position: Vector2, p_rect: Vector2) -> void:
	Spotlight.position = p_position
	Spotlight.size = p_rect

func create_spotlights(focus_objects: Array[Node]) -> void:
	for focus_object in focus_objects:
		create_spotlight(focus_object)

func create_spotlight(focus_object: Node) -> void:
	var spotlight: Panel = Spotlight.instantiate()
	spotlight.focus_object = focus_object
	Spotlights.add_child(spotlight)

func clear_spotlights() -> void:
	for spotlight in Spotlights.get_children():
		spotlight.queue_free()

func change_step(step: BaseTutorialStep) -> void:
	current_step.exit()
	
	current_step = step
	
	clear_spotlights()
	
	step.enter()
	
	if step.enable_spotlight:
		toggle_spotlight(true)
		create_spotlights(step.FocusObjects)
	else:
		toggle_spotlight(false)
	
	TutorialInfo.set_text(step.text)

func _on_tutorial_info_next_pressed() -> void:
	if current_index == get_steps().size() - 1:
		return
	
	TutorialInfo.show_prev()
	change_step(get_steps()[current_index + 1])

func _on_tutorial_info_prev_pressed() -> void:
	if current_index == 0:
		return
	
	TutorialInfo.show_next()
	change_step(get_steps()[current_index - 1])
