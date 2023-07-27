extends PanelContainer

@export var minRange : int = 0
@export var maxRange : int = 10
@export var minValue : int = 0 : set = _set_min_value
@export var maxValue : int = 10 : set = _set_max_value
@export var tickCount : int = 11

@export var showEndLabels : bool = true
@export var showMinLabel : bool = true
@export var showMaxLabel : bool = true

enum {MIN, MAX}

@onready var Min = get_node('Sliders/Min')
@onready var Max = get_node('Sliders/Max')
@onready var SegmentStart = get_node('Sliders/SegmentContainer/SegmentContainer/Start')
@onready var SegmentEnd = get_node('Sliders/SegmentContainer/SegmentContainer/End')
@onready var LabelContainer = get_node('EndLabels/HBoxContainer')
@onready var MinLabelNode = get_node('MinLabelNode')
@onready var MaxLabelNode = get_node('MaxLabelNode')
@onready var StartLabel = get_node('EndLabels/HBoxContainer/Start')
@onready var EndLabel = get_node('EndLabels/HBoxContainer/End')
@onready var MinMax := [Min, Max]

@onready var N_steps : float = (maxRange - minRange + 1) / Min.step
var step_separation : float
var maxPosition : float

var hovering := false

const grab_range : float = 6.0
const grab_range_y : float = 15.0
const segment_margin : float = 3.0
const GrabberLabelOffset : float = -0.2

func _ready():
	for slider in MinMax:
		slider.tick_count = tickCount
		slider.min_value = minRange
		slider.max_value = maxRange
	
	self.minValue = minValue
	self.maxValue = maxValue
	
	if showEndLabels:
		StartLabel.show()
		StartLabel.text = str(minRange)
		EndLabel.show()
		EndLabel.text = str(maxRange)
		
	if showMinLabel:
		MinLabelNode.get_node('MinLabel').show()
	if showMaxLabel:
		MaxLabelNode.get_node('MaxLabel').show()
	
	await get_tree().process_frame
	step_separation = Min.size.x / N_steps
	maxPosition = N_steps * step_separation

func _on_Min_value_changed(value) -> void:
	minValue = value
	
	Max.value = max(minValue, maxValue)
	
	set_min_labels()

func _on_Max_value_changed(value) -> void:
	maxValue = value
	Min.value = min(minValue, maxValue)
	
	set_max_labels()

func _set_min_value(new_value : int) -> void:
	minValue = new_value
	Min.value = new_value
	
	set_min_labels()

func _set_max_value(new_value : int) -> void:
	maxValue = new_value
	Max.value = new_value
	
	set_max_labels()

func _process(_delta) -> void:
	if Min.value == minRange or Min.value == maxRange:
		MinLabelNode.get_node('MinLabel').hide()
	elif showMinLabel:
		MinLabelNode.get_node('MinLabel').show()
	
	if Max.value == minRange or Max.value == maxRange:
		MaxLabelNode.get_node('MaxLabel').hide()
	elif showMaxLabel:
		MaxLabelNode.get_node('MaxLabel').show()
	
	
	for i in [MIN, MAX]:
		var slider = MinMax[i]
		var mouse_pos = slider.get_local_mouse_position()
			
		if (
		abs(mouse_pos.x - get_grabber_position(i)) < grab_range
		and abs(mouse_pos.y - slider.size.y * 0.5) < grab_range_y):
			slider.mouse_filter = MOUSE_FILTER_PASS
			slider.editable = true
		else:
			slider.mouse_filter = MOUSE_FILTER_IGNORE
			slider.editable = false
			slider.release_focus()

func get_grabber_position(slider : int) -> float:
	return (MinMax[slider].value - minRange) * step_separation + segment_margin

func is_hovered() -> bool:
	return hovering

func set_min_labels() -> void:
	SegmentStart.custom_minimum_size.x = get_grabber_position(MIN)
	MinLabelNode.position.x = segment_margin + get_grabber_position(MIN) + GrabberLabelOffset
	MinLabelNode.get_node('MinLabel').text = str(Min.value)

func set_max_labels() -> void:
	SegmentEnd.custom_minimum_size.x = maxPosition - get_grabber_position(MAX)
	MaxLabelNode.position.x = segment_margin + get_grabber_position(MAX) + GrabberLabelOffset
	MaxLabelNode.get_node('MaxLabel').text = str(Max.value)
