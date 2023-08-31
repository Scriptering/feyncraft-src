extends Node2D

@export var offset: Vector2 = Vector2(15, 15)
@export var delay: float = 0.25

@export var tooltip: String = "" :
	set(new_value):
		tooltip = new_value
		$TooltipPanel/Label.text = new_value

func _ready() -> void:
	get_parent().mouse_entered.connect(_on_parent_mouse_entered)
	get_parent().mouse_exited.connect(_on_parent_mouse_exited)
	
	if get_parent().hide_tooltip:
		get_parent().hide_tooltip.connect(_on_parent_hide_tooltip)
	
	$TooltipTimer.wait_time = delay

func _on_parent_hide_tooltip() -> void:
	$TooltipTimer.stop()
	hide()

func _on_parent_mouse_entered() -> void:
	$TooltipTimer.start()

func _on_parent_mouse_exited() -> void:
	$TooltipTimer.stop()
	hide()

func _on_tooltip_timer_timeout() -> void:
	show_tooltip()

func show_tooltip() -> void:
	if tooltip == "":
		return
	
	position = offset
	show()
