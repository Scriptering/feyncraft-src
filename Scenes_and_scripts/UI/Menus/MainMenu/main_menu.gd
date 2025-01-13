extends Node2D

signal sandbox_pressed
signal tutorial_pressed
signal daily_pressed

var Level := preload("res://Scenes_and_scripts/Levels/world.tscn")
var placing: bool = false

@onready var Diagram: MainDiagram = $Diagram
@onready var daily:PanelButton = $Center/VBoxContainer/GridContainer/Daily
@onready var welcome_message:GrabbableControl = $FloatingMenus/WelcomeMessage

func _ready() -> void:
	EventBus.signal_exit_game.connect(_on_exit_game)
	
	if (
		StatsManager.stats.last_seen_message_id != welcome_message.message_id
		and StatsManager.stats.last_seen_message_id != 0
	):
		welcome_message.show()
		StatsManager.stats.last_seen_message_id = welcome_message.message_id

func init(state_manager: Node) -> void:
	$Diagram.init(state_manager)

	Diagram.draw_diagram(Globals.TitleDiagram)
	set_daily_counter()

func _on_sandbox_pressed() -> void:
	sandbox_pressed.emit()

func _on_exit_game(_mode: int, _problem: Problem) -> void:
	return

func add_floating_menu(menu: Control) -> void:
	$FloatingMenus.add_child(menu)

func _on_tutorial_pressed() -> void:
	tutorial_pressed.emit()

func _on_daily_pressed() -> void:
	daily_pressed.emit()

func set_daily_counter() -> void:
	var streak: int = StatsManager.stats.daily_streak
	daily.text = "Daily%s"%[" %s"%[streak] if streak > 0 else ""]
	daily.hide_icon = streak == 0

func update() -> void:
	if is_instance_valid(%Problems.get_popup()):
		%Problems.get_popup().update()

func _on_version_clicked_on() -> void:
	welcome_message.show()
