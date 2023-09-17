extends PanelContainer

signal return_to_main_menu

@onready var CustomSolutions: CheckButton = $VBoxContainer2/VBoxContainer/CustomSolutions
@onready var LimitedParticles: CheckButton = $VBoxContainer2/VBoxContainer/VBoxContainer/LimitedParticles
@onready var HiddenParticles: CheckButton = $VBoxContainer2/VBoxContainer/VBoxContainer/HiddenParticles

func _on_limited_particles_toggled(button_pressed: bool) -> void:
	HiddenParticles.visible = button_pressed

func _on_return_pressed() -> void:
	emit_signal("return_to_main_menu")
