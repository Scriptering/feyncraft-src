extends Node

@export var offset: Vector2 = Vector2(15, 15)
@export var delay: float = 0.25

@export var TooltipPanel: PanelContainer
@export var TooltipLabel: Label
@export var TooltipContainer: HBoxContainer

@export var tooltip: String = "" :
	set(new_value):
		tooltip = new_value
		TooltipLabel.text = new_value
		
@onready var Parent: Node = get_parent()

func _ready() -> void:
	Parent.mouse_entered.connect(_on_parent_mouse_entered)
	Parent.mouse_exited.connect(_on_parent_mouse_exited)
	Parent.visibility_changed.connect(_on_parent_visibility_changed)
	
	if Parent.get_signal_list().any(
		func(signal_dict: Dictionary) -> bool: 
			return signal_dict['name'] == "hide_tooltip"
	):
		Parent.hide_tooltip.connect(_on_parent_hide_tooltip)

	$TooltipTimer.wait_time = delay

func _on_parent_hide_tooltip() -> void:
	hide_tooltip()

func _on_parent_mouse_entered() -> void:
	$TooltipTimer.start()

func _on_parent_mouse_exited() -> void:
	hide_tooltip()

func _on_tooltip_timer_timeout() -> void:
	if Parent.visible:
		show_tooltip()

func show_tooltip() -> void:
	if tooltip == "" and TooltipContainer.get_child_count() == 1:
		return
	
	var viewport_middle: Vector2 = Parent.get_viewport_rect().size/2

	var direction_to_centre: Vector2 = (viewport_middle - Parent.get_global_position()).normalized()
	
	TooltipPanel.position = Parent.get_global_position() + (offset + Vector2(TooltipPanel.get_rect().size.x / 2, 0)) * direction_to_centre
	TooltipPanel.show()

func hide_tooltip() -> void:
	$TooltipTimer.stop()
	TooltipPanel.hide()

func add_content(content: Node) -> void:
	TooltipContainer.add_child(content)

func remove_content() -> void:
	for child in TooltipContainer.get_children():
		if child == TooltipLabel:
			pass
		
		child.queue_free()

func _on_parent_visibility_changed() -> void:
	hide_tooltip()
