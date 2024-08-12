@tool

extends PanelButton

signal submitted(submitted_text: String)

enum Mode {Load, Upload}

@export var mode: Mode = Mode.Load:
	set(new_value):
		mode = new_value
		
		icon = icon_dict[mode]

var LoadPanel : PackedScene = preload("res://Scenes and Scripts/UI/load_box.tscn")
var load_panel: GrabbableControl

var icon_dict: Dictionary = {
	Mode.Load: preload("res://Textures/Buttons/icons/load.png"),
	Mode.Upload: preload("res://Textures/Buttons/icons/share.png")
}

func _ready() -> void:
	super._ready()
	self.mode = mode

func _on_button_toggled(button_pressed_state: bool) -> void:
	super._on_button_toggled(button_pressed_state)
	
	if button_pressed_state:
		create_load_panel()
	else:
		load_panel.queue_free()
	
func create_load_panel() -> void:
	load_panel = LoadPanel.instantiate()
	load_panel.mode = mode
	load_panel.position = get_global_position()
	load_panel.closed.connect(close_load_panel)
	load_panel.submitted.connect(
		func(submitted_text: String) -> void:
			submitted.emit(submitted_text)
	)
	EventBus.add_floating_menu.emit(load_panel)

func close_load_panel() -> void:
	self.button_pressed = false

func invalid_submission() -> void:
	if load_panel:
		load_panel.invalid_submission()

func set_text(new_text: String) -> void:
	load_panel.set_text(new_text)

func load_result(valid: bool) -> void:
	if !load_panel:
		return
		
	if !valid:
		load_panel.show_popup("Load Error!")
	else:
		close_load_panel()
