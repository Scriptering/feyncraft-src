extends ScrollContainer

@onready var Level = get_tree().get_nodes_in_group('level')[0]
@onready var Cursor = Level.get_node('Cursor')
@onready var Clock = get_node('Clock')

func _ready():
# warning-ignore:return_value_discarded
	get_h_scroll_bar().connect('value_changed', Callable(self, '_on_Scroll'))
	get_h_scroll_bar().mouse_filter = Control.MOUSE_FILTER_PASS
	
func _on_Scroll(_value):
	Cursor.override = true
	Cursor.change_cursor(GLOBALS.CURSOR.hold)
	Clock.start(0.01)

func _on_Clock_timeout():
	if !Input.is_action_pressed('click'):
		Cursor.change_cursor(GLOBALS.CURSOR.point)
