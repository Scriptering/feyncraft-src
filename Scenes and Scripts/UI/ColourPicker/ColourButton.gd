@tool
extends PanelContainer

class_name ColourButton

signal colour_changed(button: ColourButton, colour: Color)

@export var picker_offset: Vector2 = Vector2.ZERO
@export var icon_colour: Color: set = _set_icon_colour
@export var colour_name: String

var picker_panel: GrabbableControl

@onready var PickerPanel: PackedScene = preload("res://Scenes and Scripts/UI/ColourPicker/ColourPickerPanel.tscn")

func _set_icon_colour(new_value: Color) -> void:
	icon_colour = new_value
	$MarginContainer/ColorRect.modulate = icon_colour

func _on_color_picker_color_changed(color: Color) -> void:
	self.icon_colour = color
	colour_changed.emit(self, color)

func _on_popup_panel_popup_hide() -> void:
	self.button_pressed = false

func create_picker_panel() -> void:
	picker_panel = PickerPanel.instantiate()
	picker_panel.set_title(colour_name)
	picker_panel.starting_colour = icon_colour
	picker_panel.position = get_global_position() + picker_offset
	picker_panel.colour_changed.connect(_on_color_picker_color_changed)
	picker_panel.closed.connect(
		func() -> void:
			$Button.button_pressed = false
	)
	
	await get_tree().process_frame
	
	EventBus.add_floating_menu.emit(picker_panel)

func _on_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		create_picker_panel()
	else:
		picker_panel.queue_free()

func set_disabled(disable: bool) -> void:
	$Button.disabled = disable

func _on_button_mouse_entered() -> void:
	$MarginContainer/ColorRect.modulate *= 1.1

func _on_button_mouse_exited() -> void:
	$MarginContainer/ColorRect.modulate /= 1.1
