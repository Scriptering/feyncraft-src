@tool

extends PopUpButton

signal filters_submitted

var filters : Dictionary = {
	"degree_ranges" : [],
	"only_4_vertex" : false
}

func _ready() -> void:
	super()
	
	reset()
	popup_opened.connect(_on_filters_opened)

func reset() -> void:
	var new_ranges : Array[Vector2i] = []
	new_ranges.clear()
	new_ranges.resize(Globals.Force.size())
	new_ranges.fill(Vector2i(0, 10))
	
	filters["degree_ranges"] = new_ranges
	filters["only_4_vertex"] = false
	
	if is_instance_valid(popup):
		popup.set_filters(filters)

func _on_filters_opened() -> void:
	popup.set_filters(filters)
	popup.submitted.connect(_on_filters_submitted)
	popup.reset_pressed.connect(
		func() -> void:
			reset()
			filters_submitted.emit()
	)

func _on_filters_submitted(new_filters: Dictionary) -> void:
	filters = new_filters
	filters_submitted.emit()
