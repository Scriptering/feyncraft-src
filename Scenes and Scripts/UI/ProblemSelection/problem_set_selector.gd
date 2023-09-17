extends PanelContainer

var problem_set: ProblemSet
var is_custom: bool = false

@onready var Title : LineEdit = $VBoxContainer/LineEdit
@onready var ButtonContainer = $VBoxContainer/TabContainer/ProblemSetContainer/ButtonContainer
@onready var Tabs = $VBoxContainer/TabContainer

func _ready() -> void:
	hide_buttons()
	
	$VBoxContainer/TabContainer.returned.connect(options_returned)

func _on_mouse_entered() -> void:
	show_buttons()

func _on_mouse_exited() -> void:
	if get_global_rect().has_point(get_global_mouse_position()):
		return

	hide_buttons()

func hide_buttons() -> void:
	var tween = get_tree().create_tween()
	tween.finished.connect(ButtonContainer.hide)
	tween.tween_property(ButtonContainer.material, "shader_parameter/alpha", 0, .05)

func show_buttons() -> void:
	var tween = get_tree().create_tween()
	ButtonContainer.show()
	tween.tween_property(ButtonContainer.material, "shader_parameter/alpha", 1, .05)

func _on_modify_pressed() -> void:
	Tabs.current_tab = 1
	Title.editable = true

func options_returned() -> void:
	Title.editable = false
