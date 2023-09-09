extends Node2D

@export var offset: Vector2 = Vector2(15, 15)
@export var delay: float = 0.25

@export var tooltip: String = "" :
	set(new_value):
		tooltip = new_value
		$TooltipPanel/HBoxContainer/Label.text = new_value

func _ready() -> void:
	get_parent().mouse_entered.connect(_on_parent_mouse_entered)
	get_parent().mouse_exited.connect(_on_parent_mouse_exited)
	
	if get_parent().get_signal_list().any(
		func(signal_dict: Dictionary): return signal_dict['name'] == "hide_tooltip"
	):
		get_parent().hide_tooltip.connect(_on_parent_hide_tooltip)

	$TooltipTimer.wait_time = delay

func _on_parent_hide_tooltip() -> void:
	$TooltipTimer.stop()
	hide_tooltip()

func _on_parent_mouse_entered() -> void:
	$TooltipTimer.start()

func _on_parent_mouse_exited() -> void:
	$TooltipTimer.stop()
	hide_tooltip()

func _on_tooltip_timer_timeout() -> void:
	show_tooltip()

func show_tooltip() -> void:
	if tooltip == "" and $TooltipPanel/HBoxContainer.get_child_count() == 1:
		return
	
	position = offset
	show()

func hide_tooltip() -> void:
	hide()

func add_content(content: Node) -> void:
	$TooltipPanel/HBoxContainer.add_child(content)

func remove_content() -> void:
	for child in $TooltipPanel/HBoxContainer.get_children():
		if child == $TooltipPanel/HBoxContainer/Label:
			pass
		
		child.queue_free()