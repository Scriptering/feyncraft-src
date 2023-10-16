extends PullOutTab

@onready var DiagramValid: HBoxContainer = $VBoxContainer/Tab/VBoxContainer/DiagramValid
@onready var DiagramConnected: HBoxContainer = $VBoxContainer/Tab/VBoxContainer/DiagramConnected
@onready var EnergyConservation: HBoxContainer = $VBoxContainer/Tab/VBoxContainer/EnergyConservation

var tick_circle: Texture2D = preload("res://Textures/Buttons/icons/tick_circle.png")
var invalid_circle: Texture2D = preload("res://Textures/Buttons/icons/error_circle.png")

var invalid_texture: Texture2D = preload("res://Textures/UI/Information/invalid.png")
var valid_texture: Texture2D = preload("res://Textures/UI/Information/valid.png")

var Diagram: MainDiagram

func init(diagram: MainDiagram) -> void:
	Diagram = diagram
	Diagram.action_taken.connect(check)
	
	check()

func check() -> void:
	var diagram_valid: bool = Diagram.is_valid()
	var diagram_connected: bool = Diagram.is_fully_connected(true)
	var enery_conserved: bool = Diagram.is_energy_conserved()
	
	if diagram_valid and diagram_connected and enery_conserved:
		TabButton.TabIcon = tick_circle
	else:
		TabButton.TabIcon = invalid_circle
	
	toggle_diagram_valid(diagram_valid)
	toggle_diagram_connected(diagram_connected)
	toggle_energy_conservation(enery_conserved)

func toggle_tick(container: HBoxContainer, valid: bool) -> void:
	var icon: TextureRect = container.get_node("TextureRect")
	icon.texture = valid_texture if valid else invalid_texture

func toggle_diagram_valid(valid: bool) -> void:
	toggle_tick(DiagramValid, valid)
	DiagramValid.get_node("Label").text = (
		"Diagram is valid" if valid else "Diagram is not valid"
	)

func toggle_diagram_connected(valid: bool) -> void:
	toggle_tick(DiagramConnected, valid)
	DiagramConnected.get_node("Label").text = (
		"Diagram is connected" if valid else "Diagram is not connected"
	)

func toggle_energy_conservation(valid: bool) -> void:
	toggle_tick(EnergyConservation, valid)
	EnergyConservation.get_node("Label").text = (
		"Energy is conserved" if valid else "Energy is not conserved"
	)
