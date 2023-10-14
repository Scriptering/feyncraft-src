@tool
extends PanelContainer
class_name PanelButton

signal hide_tooltip
signal pressed
signal on_pressed
signal button_toggled(button_pressed: bool, button: PanelButton)
signal toggled(button_pressed: bool)
signal button_mouse_entered(button)
signal button_mouse_exited
signal button_down
signal button_up

@export var icon: Texture2D : set = _set_button_icon
@export var text: String : set = _set_button_text
@export var minimum_size: Vector2 : set = _set_button_minimum_size
@export var toggle_mode: bool : set = _set_toggle_mode
@export var expand_icon: bool : set = _set_expand_icon
@export var button_pressed: bool: set = _set_button_pressed, get = _get_button_pressed
@export var disabled: bool = false: set = _set_button_disabled
@export var icon_use_parent_material: bool = false: set = _set_icon_use_parent_material
@export var mute: bool = false
@export var action_mode: Button.ActionMode = Button.ACTION_MODE_BUTTON_PRESS :
	set = _set_action_mode
@export var button_group: ButtonGroup : set = _set_button_button_group
@export var icon_text_seperation: int = 3: set = _set_icon_text_seperation
@export var flip_icon_v: bool = false:
	set(new_value):
		flip_icon_v = new_value
		$ContentContainer/HBoxContainer/ButtonIcon.flip_v = new_value
@export var flip_icon_h: bool = false:
	set(new_value):
		flip_icon_h = new_value
		$ContentContainer/HBoxContainer/ButtonIcon.flip_h = new_value
@export var flat: bool = false:
	set(new_value):
		flat = new_value
		get_node("Button").flat = flat

@onready var button = $Button
@onready var label = $ContentContainer/HBoxContainer/ButtonText
@onready var iconSprite = $ContentContainer/HBoxContainer/ButtonIcon

enum {NORMAL, PRESSED}
const ButtonState : Array[String] = ['normal', 'pressed']

var previous_button_pressed : bool
var is_hovered: bool:
	get:
		return button.is_hovered()
var is_just_pressed: bool:
	get:
		return just_pressed_counter > 0
var just_pressed_counter: int = 0
var is_just_released: bool:
	get:
		return just_released_counter > 0
var just_released_counter: int = 0

func _process(_delta: float) -> void:
	if just_pressed_counter > 0:
		just_pressed_counter -= 1
	
	if just_released_counter > 0:
		just_released_counter -= 1

func _ready() -> void:
	add_to_group("button", true)
	
	previous_button_pressed = button_pressed
	set_content_margins(ButtonState[int(button_pressed)])
	
	visibility_changed.connect(_on_visibility_changed)
	
	$Button.mouse_entered.connect(
		func(): 
			mouse_entered.emit()
			button_mouse_entered.emit(self)
	)
	
	$Button.mouse_exited.connect(
		func(): 
			mouse_exited.emit()
			button_mouse_exited.emit(self)
	)
	
	if EVENTBUS.has_method("button_created"):
		EVENTBUS.button_created(self)

func _set_icon_use_parent_material(new_value: bool) -> void:
	icon_use_parent_material = new_value
	$ContentContainer/HBoxContainer/ButtonIcon.use_parent_material = new_value

func _set_button_pressed(new_value: bool) -> void:
	button_pressed = new_value
	$Button.button_pressed = new_value
	
	set_content_margins(ButtonState[int(button_pressed)])

func _set_button_disabled(new_value: bool) -> void:
	if disabled == new_value:
		return
	
	disabled = new_value
	$Button.disabled = new_value
	
	if is_inside_tree() and disabled:
		await get_tree().process_frame
		self.button_pressed = false
		_on_button_button_up()

func _set_toggle_mode(new_value: bool) -> void:
	toggle_mode = new_value
	
	$Button.toggle_mode = new_value

func _set_expand_icon(new_value: bool) -> void:
	expand_icon = new_value
	
	if new_value:
		$ContentContainer/HBoxContainer/ButtonIcon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		$ContentContainer/HBoxContainer/ButtonIcon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		$ContentContainer/HBoxContainer/ButtonIcon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		$ContentContainer/HBoxContainer/ButtonIcon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED

func _get_button_pressed() -> bool:
	return get_node("Button").button_pressed
	
func _set_button_button_group(new_value: ButtonGroup) -> void:
	button_group = new_value
	get_node("Button").button_group = button_group

func _set_button_icon(new_value: Texture2D) -> void:
	icon = new_value
	
	$ContentContainer/HBoxContainer/ButtonIcon.texture = new_value
	if new_value == null:
		$ContentContainer/HBoxContainer/ButtonIcon.hide()
	else:
		$ContentContainer/HBoxContainer/ButtonIcon.show()

func _set_button_text(new_value: String) -> void:
	text = new_value
	
	$ContentContainer/HBoxContainer/ButtonText.text = new_value

	if new_value == '':
		$ContentContainer/HBoxContainer/ButtonText.hide()
	else:
		$ContentContainer/HBoxContainer/ButtonText.show()

func _set_button_minimum_size(new_value: Vector2) -> void:
	minimum_size = new_value
	
	$Button.set_custom_minimum_size(new_value)

func _set_action_mode(new_value: Button.ActionMode):
	action_mode = new_value
	
	get_node("Button").action_mode = new_value

func _set_icon_text_seperation(new_value: int) -> void:
	icon_text_seperation = new_value
	
	$ContentContainer/HBoxContainer.add_theme_constant_override("separation", icon_text_seperation) 

func _on_button_pressed() -> void:
	pressed.emit()
	on_pressed.emit(self)
	hide_tooltip.emit()

func set_content_margins(button_state: String) -> void:
	$ContentContainer.add_theme_constant_override("margin_top",
		$Button.get_theme_stylebox(button_state).get_margin(SIDE_TOP)
	)
	$ContentContainer.add_theme_constant_override("margin_left",
		$Button.get_theme_stylebox(button_state).get_margin(SIDE_LEFT)
	)
	$ContentContainer.add_theme_constant_override("margin_right",
		$Button.get_theme_stylebox(button_state).get_margin(SIDE_RIGHT)
	)
	$ContentContainer.add_theme_constant_override("margin_bottom",
		$Button.get_theme_stylebox(button_state).get_margin(SIDE_BOTTOM)
	)

func _on_button_button_down():
	if toggle_mode:
		return
	
	if !mute:
		play_sound(true)
		
	set_content_margins(ButtonState[PRESSED])
	
	button_down.emit()
	
	just_pressed_counter += 2

func _on_button_button_up():
	if toggle_mode:
		return
	
	if !mute:
		play_sound(false)

	set_content_margins(ButtonState[NORMAL])
	
	button_up.emit()

	just_released_counter += 2

func _on_button_theme_changed():
	set_content_margins(ButtonState[NORMAL])

func get_button() -> Button:
	return $Button

func _on_button_toggled(button_pressed_state: bool) -> void:
	button_toggled.emit(button_pressed_state, self)
	toggled.emit(button_pressed_state)
	if button_pressed_state:
		just_pressed_counter += 2
	else:
		just_released_counter += 2
	
	if button_pressed_state == previous_button_pressed:
		return
	previous_button_pressed = button_pressed_state
	
	play_sound(button_pressed_state)
	if button_pressed_state:
		set_content_margins(ButtonState[PRESSED])
	else:
		set_content_margins(ButtonState[NORMAL])

func play_sound(button_pressed_state: bool) -> void:
	if !is_inside_tree():
		return
		
	if !is_hovered:
		return
	
	if button_pressed_state:
		SOUNDBUS.button_down()
	elif !$Button.button_group:
		SOUNDBUS.button_up()
	elif $Button.button_group.get_pressed_button() == null:
		SOUNDBUS.button_up()

func _on_visibility_changed() -> void:
	await get_tree().process_frame
	
	if button_pressed:
		set_content_margins(ButtonState[PRESSED])
	else:
		set_content_margins(ButtonState[NORMAL])
