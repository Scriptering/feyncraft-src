extends PanelContainer


@onready var CustomSolutions: CheckButton = $PanelContainer/VBoxContainer/CustomSolutions
@onready var LimitedParticles: CheckButton = $PanelContainer/VBoxContainer/VBoxContainer/LimitedParticles
@onready var HiddenParticles: CheckButton = $PanelContainer/VBoxContainer/VBoxContainer/HiddenParticlesContainer/HiddenParticles


func _on_limited_particles_toggled(button_pressed: bool) -> void:
	$PanelContainer/VBoxContainer/VBoxContainer/HiddenParticlesContainer.visible = button_pressed
	
