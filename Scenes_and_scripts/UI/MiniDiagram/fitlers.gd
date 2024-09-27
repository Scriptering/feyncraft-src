extends GrabbableControl

signal close()
signal submitted(filters: Dictionary)
signal reset_pressed()

var filters : Dictionary = {
	"degree_ranges" : [],
	"only_4_vertex" : false
}

var ranges: Array[Vector2i] = []
var current_force : Globals.Force = Globals.Force.none
var force_group : ButtonGroup = load("res://Scenes_and_scripts/UI/MiniDiagram/filter_buttongroup.tres")
@onready var force_buttons : Array[PanelButton] = [%EM, %Strong, %Weak, %Electroweak]

func _ready() -> void:
	super()
	reset()
	force_group.pressed.connect(force_button_pressed)

func _on_close_pressed() -> void:
	close.emit()

func set_range() -> void:
	%MinDegree.value = ranges[current_force].x
	%MaxDegree.value = ranges[current_force].y

func set_ranges(p_ranges: Array[Vector2i]) -> void:
	ranges = p_ranges
	set_range()

func set_filters(new_filters: Dictionary) -> void:
	set_ranges(new_filters["degree_ranges"])
	$PanelContainer/VBoxContainer/only_4_vertex.button_pressed = new_filters["only_4_vertex"]

func reset() -> void:
	ranges.clear()
	ranges.resize(Globals.Force.size())
	ranges.fill(Vector2i(0, 10))

func force_button_pressed(button: BaseButton) -> void:
	if !button.button_pressed:
		current_force = Globals.Force.none
		set_range()
		return
	
	current_force = ArrayFuncs.find_var(
		force_buttons,
		func(force_button: PanelButton) -> bool:
			return button == force_button.get_button()
	)
	set_range()

func _on_min_degree_value_changed(value: float) -> void:
	ranges[current_force].x = int(value)

func _on_max_degree_value_changed(value: float) -> void:
	ranges[current_force].y = int(value)

func _on_set_pressed() -> void:
	filters["degree_ranges"] = ranges
	filters["only_4_vertex"] = $PanelContainer/VBoxContainer/only_4_vertex.button_pressed
	
	submitted.emit(filters)

func _on_reset_pressed() -> void:
	reset_pressed.emit()
