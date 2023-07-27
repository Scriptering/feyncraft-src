extends Sprite2D

@onready var Level = get_tree().get_nodes_in_group('level')[0]
@onready var Heart = get_node('Heart')

@export var Scale : float = 1.0

var angry := false: set = set_angry
var playing := false
var current_cursor := -1
var override = false

var connected_buttons := []
var connected_scrollcontainers := []
var connected_sliders := []

var scrolling : bool = false
var deleting : bool = false
var scroll_hovering := false
var glowing := false: set = set_glowing

var scal = 1.2

var point := load('res://Textures/Cursors/cursor_point.png')
var hold := load('res://Textures/Cursors/cursor_hold.png')
var snip := load('res://Textures/Cursors/cursor_snip.png')
var snipped := load('res://Textures/Cursors/cursor_snipped.png')
var middle := load('res://Textures/Cursors/cursor_middle.png')
var hover := load('res://Textures/Cursors/cursor_hover.png')
var press := load('res://Textures/Cursors/cursor_press.png')
var disabled := load('res://Textures/Cursors/cursor_disabled.png')

var cursors := [0, point, hold, snip, snipped, middle, hover, press, disabled]

var control := Control.new()

func _ready():
	Heart.visible = false
	
	scale = Vector2(Scale, Scale)
	offset = Scale * Vector2(8, 22)
	Heart.offset = Scale * Vector2(9, 30)
	
	change_cursor(GLOBALS.CURSOR.point)
	
	visible = GLOBALS.isOnBuild
	Input.mouse_mode = int(GLOBALS.isOnBuild) as Input.MouseMode
	
func set_glowing(new_value : bool) -> void:
	glowing = new_value

func _process(_delta):
	if scroll_hovering and Input.is_action_pressed('click') and Level.mode != 'editing':
		start_scrolling()
	if Level.mode == 'deleting' and Input.is_action_pressed('click'):
		start_deleting()
	if Input.is_action_just_released('click'):
		end_mouse_hold()
	
	if GLOBALS.isOnBuild:
		position = get_global_mouse_position()
	
	Heart.visible = glowing and current_cursor != GLOBALS.CURSOR.disabled
	
	handle_UI()

func set_angry(anger):
	angry = anger


func change_cursor(cursor : int):
	if cursor == GLOBALS.CURSOR.default:
		if hovering_disabled_button():
			cursor = GLOBALS.CURSOR.disabled
		elif angry:
			cursor = GLOBALS.CURSOR.middle
		else:
			cursor = GLOBALS.CURSOR.point
	
	if !playing or (current_cursor == GLOBALS.CURSOR.press and Input.is_action_pressed('click')):
		if cursor != current_cursor:
			texture = cursors[cursor]
			Input.set_custom_mouse_cursor(cursors[cursor], Input.CURSOR_ARROW, Vector2(12, 6))
			current_cursor = cursor

func hovering_disabled_button() -> bool:
	var buttons = get_tree().get_nodes_in_group('UIbuttons')
	
	for button in buttons:
		if button.is_hovered() and button.disabled:
			return true
	
	return false

func change_override(bo) -> void:
	override = bo

func start_deleting() -> void:
	deleting = true
	change_cursor(GLOBALS.CURSOR.snipped)

func end_mouse_hold() -> void:
	deleting = false
	scrolling = false

func start_scrolling() -> void:
	scrolling = true
	change_cursor(GLOBALS.CURSOR.hold)

func change_scroll_hover(value : bool) -> void:
	scroll_hovering = value

func handle_UI():
	var buttons = get_tree().get_nodes_in_group('UIbuttons')
	var scrollcontainers = get_tree().get_nodes_in_group('scrollcontainers')
	var sliders = get_tree().get_nodes_in_group('sliders')

	for button in buttons:
		if !button in connected_buttons:
			button.get_node('Button').connect('button_down', Callable(self, 'change_cursor').bind(GLOBALS.CURSOR.press))
			button.get_node('Button').connect('button_up', Callable(self, 'change_cursor').bind(GLOBALS.CURSOR.default))
			button.connect('update_cursor', Callable(self, 'level_state_changed'))
			
			connected_buttons.append(button)
	
	for container in scrollcontainers:
		if !container in connected_scrollcontainers:
			container.get_v_scroll_bar().connect('mouse_entered', Callable(self, 'change_scroll_hover').bind(true))
			container.get_h_scroll_bar().connect('mouse_entered', Callable(self, 'change_scroll_hover').bind(true))
			container.get_v_scroll_bar().connect('mouse_exited', Callable(self, 'change_scroll_hover').bind(false))
			container.get_h_scroll_bar().connect('mouse_exited', Callable(self, 'change_scroll_hover').bind(false))
			
			connected_scrollcontainers.append(container)
	
	for slider in sliders:
		if !slider in connected_sliders:
			slider.connect('drag_started', Callable(self, 'change_cursor').bind(GLOBALS.CURSOR.hold))
			slider.connect('drag_ended', Callable(self, 'slider_drag_ended'))
			
			connected_sliders.append(slider)
