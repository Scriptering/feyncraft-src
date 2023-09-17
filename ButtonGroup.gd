class_name CustomButtonGroup

var buttons: Array[PanelButton] = []
var enabled: bool = true

func add_button_to_group(button: PanelButton) -> void:
	buttons.push_back(button)
	button.button_toggled.connect(_on_button_toggled)

func remove_button_to_group(button: PanelButton) -> void:
	buttons.erase(button)
	button.button_toggled.disconnect(_on_button_toggled)

func _on_button_toggled(button_pressed: bool, toggled_button: PanelButton) -> void:
	if !enabled:
		return
	
	for button in buttons:
		if button == toggled_button:
			continue
		
		if !button.button_pressed:
			continue
		
		button.button_pressed = false
