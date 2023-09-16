extends PanelContainer

var problem_set: ProblemSet
var is_custom: bool = false

@onready var ButtonContainer = $VBoxContainer/ProblemSetContainer/ButtonContainer

func _ready() -> void:
	hide_buttons()

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

