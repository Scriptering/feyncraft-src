extends GrabbableControl

signal close()
signal submitted(ranges: Array[Vector2i])

var ranges: Array[Vector2i] = []
var current_force : Globals.Force = Globals.Force.none
var force_group : ButtonGroup = load("res://Scenes_and_scripts/UI/MiniDiagram/filter_buttongroup.tres")
@onready var force_buttons : Array[PanelButton] = [%EM, %Strong, %Weak, %Electroweak]

func _ready() -> void:
	super()
	ranges.resize(Globals.Force.size())
	ranges.fill(Vector2i(0, 10))
	force_group.pressed.connect(force_button_pressed)

func _on_close_pressed() -> void:
	close.emit()

func set_ranges() -> void:
	%MinDegree.value = ranges[current_force].x
	%MaxDegree.value = ranges[current_force].y

func force_button_pressed(button: BaseButton) -> void:
	if !button.button_pressed:
		current_force = Globals.Force.none
		set_ranges()
		return
	
	current_force = ArrayFuncs.find_var(
		force_buttons,
		func(force_button: PanelButton) -> bool:
			return button == force_button.get_button()
	)
	set_ranges()

func _on_min_degree_value_changed(value: float) -> void:
	ranges[current_force].x = int(value)

func _on_max_degree_value_changed(value: float) -> void:
	ranges[current_force].y = int(value)

func _on_set_pressed() -> void:
	submitted.emit(ranges)
