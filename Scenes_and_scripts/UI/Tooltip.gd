extends Node
class_name Tooltip

@export var offset: Vector2 = Vector2(15, 15)
@export var show_delay: float = 0.4
@export var hide_delay: float = -1
@export var manual_placement: bool = false

@export var TooltipPanel: PanelContainer
@export var TooltipLabel: Label
@export var TooltipContainer: HBoxContainer

@export var tooltip: String = "" :
	set(new_value):
		tooltip = new_value
		TooltipLabel.text = new_value
		
@onready var Parent: Node = get_parent()

var show_timer : Timer
var hide_timer : Timer

func _ready() -> void:
	connect_parent_signals()
	
	if show_delay > 0:
		show_timer = Timer.new()
		add_child(show_timer)
		show_timer.one_shot = true
		show_timer.wait_time = show_delay
		show_timer.timeout.connect(_on_show_timer_timeout)
	
	if hide_delay > 0:
		hide_timer = Timer.new()
		add_child(hide_timer)
		hide_timer.one_shot = true
		hide_timer.wait_time = hide_delay
		hide_timer.timeout.connect(_on_hide_timer_timeout)

func _on_parent_hide_tooltip() -> void:
	hide_tooltip()

func _on_parent_mouse_entered() -> void:
	if show_timer:
		show_timer.start()
	else:
		show_tooltip()

func _on_parent_mouse_exited() -> void:
	hide_tooltip()

func _on_show_timer_timeout() -> void:
	if Parent.visible:
		show_tooltip()

func _on_hide_timer_timeout() -> void:
	hide_tooltip()

func show_tooltip() -> void:
	if tooltip == "" and TooltipContainer.get_child_count() == 1:
		return
	
	if !manual_placement:
		var viewport_middle: Vector2 = Parent.get_viewport_rect().size/2
		var direction_to_centre: Vector2 = (viewport_middle - Parent.get_global_position()).normalized()
		TooltipPanel.position = Parent.get_global_position() + (offset + Vector2(TooltipPanel.get_rect().size.x / 2, 0)) * direction_to_centre

	TooltipPanel.show()
	
	if hide_timer:
		hide_timer.start()

func hide_tooltip() -> void:
	if show_timer:
		show_timer.stop()
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

func connect_parent_signals() -> void:
	for signal_dict: Dictionary in Parent.get_signal_list():
		var signal_name: String = signal_dict['name']
		
		match signal_name:
			"hide_tooltip": Parent.hide_tooltip.connect(_on_parent_hide_tooltip)
			"mouse_entered": Parent.mouse_entered.connect(_on_parent_mouse_entered)
			"mouse_exited": Parent.mouse_exited.connect(_on_parent_mouse_exited)
			"visibility_changed": Parent.visibility_changed.connect(_on_parent_visibility_changed)
