@tool

class_name ColourButton
extends PanelButton

signal colour_changed(button: ColourButton, colour: Color)

@export var picker_offset: Vector2 = Vector2.ZERO
@export var icon_colour: Color: set = _set_icon_colour

var picker_panel: GrabbableControl

@onready var PickerPanel: PackedScene = preload("res://Scenes and Scripts/UI/ColourPicker/ColourPickerPanel.tscn")

func _set_icon_colour(new_value: Color) -> void:
	icon_colour = new_value
	get_node("ContentContainer/HBoxContainer/ButtonIcon").modulate = icon_colour

func _on_button_toggled(button_pressed_state: bool) -> void:
	super._on_button_toggled(button_pressed_state)
	
	if button_pressed_state:
		create_picker_panel()
	else:
		picker_panel.queue_free()

func _on_color_picker_color_changed(color: Color) -> void:
	self.icon_colour = color
	colour_changed.emit(self, color)

func _on_popup_panel_popup_hide() -> void:
	self.button_pressed = false

func create_picker_panel() -> void:
	picker_panel = PickerPanel.instantiate()
	picker_panel.title = name
	picker_panel.starting_colour = icon_colour
	picker_panel.position = get_global_position() + picker_offset
	picker_panel.colour_changed.connect(_on_color_picker_color_changed)
	picker_panel.closed.connect(
		func(): self.button_pressed = false
	)
	
	await get_tree().process_frame
	
	EVENTBUS.add_floating_menu(picker_panel)
