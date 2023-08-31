extends GrabbableControl

@onready var Row = preload("res://Scenes and Scripts/UI/Info/InfoRow.tscn")

signal closed_button_pressed

enum Tab {QuantumNumbers, Other}
enum OtherProperties {Dimensionality, ColourlessGluon, NeutralPhoton, Colour}

@onready var data_containers : Array[GridContainer] = [
	$"PanelContainer/TabContainer/Quantum Numbers/Quantum Numbers",
	$PanelContainer/TabContainer/Other/Other
]
const NUMBER_OF_TITLE_NODES : int = 4

var ConnectedInteraction: Interaction
var ID: int
var drag_vector_start: Vector2
var invalid_icon := preload("res://Scenes and Scripts/UI/Info/invalid.tscn")
var valid_icon := preload("res://Scenes and Scripts/UI/Info/valid.tscn")

#1 charge, 2 lepton num., 3 e. num, 4 mu num., 5 tau num., 6 quark num., 7 up num., 8 down num., 9 charm num., 10 strange num., 11 top num., 12 bottom num., 13 colour
var property_names = [['charge', 'lepton num.', 'electron num.', 'muon num.', 'tau num.', 'baryon num.', 'up num.', 'down num.', 'charm num.', 'strange num.', 'top num.', 'bottom num.'],
['dimensionality', 'colourless gluon?', 'neutral photon?', 'colour']]

func _ready():
	super._ready()
	
	self.connect("closed_button_pressed", Callable(ConnectedInteraction, "close_information_box"))
	
	$PanelContainer/NumberContainer/Number.text = str(ID)
	
	build_table()

func pick_up() -> void:
	super.pick_up()
	drag_vector_start = position - get_global_mouse_position()

func _process(_delta:float):
	if grabbed:
		position = get_global_mouse_position() + drag_vector_start
	
func build_table() -> void:
	clear_table()
	build_quantum_number_tab()
	build_other_tab()

func clear_table() -> void:
	for container in data_containers:
		for i in range(container.get_children().size()):
			if i < container.columns:
				continue
			container.get_child(i).queue_free()
	
func build_quantum_number_tab() -> void:
	var relevant_quantum_numbers : Array[GLOBALS.QuantumNumber] = get_relevant_quantum_numbers()
	var invalid_quantum_numbers : Array[GLOBALS.QuantumNumber] = ConnectedInteraction.get_invalid_quantum_numbers()
	var before_quantum_numbers : Array[float] = ConnectedInteraction.get_side_quantum_sum(Interaction.Side.Before)
	var after_quantum_numbers : Array[float] = ConnectedInteraction.get_side_quantum_sum(Interaction.Side.After)
	
	for quantum_number in relevant_quantum_numbers:
		add_label(data_containers[Tab.QuantumNumbers], property_names[Tab.QuantumNumbers][quantum_number])
		add_label(data_containers[Tab.QuantumNumbers], fraction_to_string(before_quantum_numbers[quantum_number]))
		add_label(data_containers[Tab.QuantumNumbers], fraction_to_string(after_quantum_numbers[quantum_number]))
		add_invalid(data_containers[Tab.QuantumNumbers], !quantum_number in invalid_quantum_numbers)

func fraction_to_string(fraction: float) -> String:
	if is_integer(fraction):
		return str(fraction)
	
	return str(int(round(fraction*3)))+'/3'

func build_other_tab() -> void:
	add_label(data_containers[Tab.Other], property_names[Tab.Other][OtherProperties.Dimensionality])
	add_label(data_containers[Tab.Other], "= "+ str(ConnectedInteraction.dimensionality) +
		(" ( <= 4 ) " if ConnectedInteraction.is_dimensionality_valid() else ' ( > 4 ) '))
	add_invalid(data_containers[Tab.Other], ConnectedInteraction.is_dimensionality_valid())
	
	if ConnectedInteraction.has_base_particle_connected(GLOBALS.Particle.gluon):
		add_label(data_containers[Tab.Other], property_names[Tab.Other][OtherProperties.ColourlessGluon])
		add_label(data_containers[Tab.Other], '  Yes  ' if ConnectedInteraction.has_colourless_gluon() else '  No  ')
		add_invalid(data_containers[Tab.Other], !ConnectedInteraction.has_colourless_gluon())
	
	if ConnectedInteraction.has_base_particle_connected(GLOBALS.Particle.photon):
		add_label(data_containers[Tab.Other], property_names[Tab.Other][OtherProperties.NeutralPhoton])
		add_label(data_containers[Tab.Other], '  Yes  ' if ConnectedInteraction.has_neutral_photon() else '  No  ')
		add_invalid(data_containers[Tab.Other], ConnectedInteraction.has_neutral_photon())

func add_label(container: GridContainer, text: String) -> void:
	var label = Label.new()
	label.text = text
	
	if container.get_child_count()%container.columns != 0:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
	container.add_child(label)

func add_invalid(container: GridContainer, valid: bool) -> void:
	if valid:
		container.add_child(valid_icon.instantiate())
	else:
		container.add_child(invalid_icon.instantiate())

func get_relevant_quantum_numbers() -> Array[GLOBALS.QuantumNumber]:
	var relevant_quantum_numbers: Array[GLOBALS.QuantumNumber] = []
	
	relevant_quantum_numbers.append(GLOBALS.QuantumNumber.charge)
	
	for base_particle in ConnectedInteraction.connected_base_particles:
		if base_particle in GLOBALS.LEPTONS:
			relevant_quantum_numbers.append(GLOBALS.QuantumNumber.lepton)
			break
	
	if (
		ConnectedInteraction.has_base_particle_connected(GLOBALS.Particle.electron) or
		ConnectedInteraction.has_base_particle_connected(GLOBALS.Particle.electron_neutrino)
	):
		relevant_quantum_numbers.append(GLOBALS.QuantumNumber.electron)
		
	if (
		ConnectedInteraction.has_base_particle_connected(GLOBALS.Particle.muon) or
		ConnectedInteraction.has_base_particle_connected(GLOBALS.Particle.muon_neutrino)
	):
		relevant_quantum_numbers.append(GLOBALS.QuantumNumber.muon)
		
	if (
		ConnectedInteraction.has_base_particle_connected(GLOBALS.Particle.tau) or
		ConnectedInteraction.has_base_particle_connected(GLOBALS.Particle.tau_neutrino)
	):
		relevant_quantum_numbers.append(GLOBALS.QuantumNumber.tau)
	
	for base_particle in ConnectedInteraction.connected_base_particles:
		if base_particle in GLOBALS.QUARKS:
			relevant_quantum_numbers.append(GLOBALS.QuantumNumber.quark)
			break

	if ConnectedInteraction.has_base_particle_connected(GLOBALS.Particle.up):
		relevant_quantum_numbers.append(GLOBALS.QuantumNumber.up)

	if ConnectedInteraction.has_base_particle_connected(GLOBALS.Particle.down):
		relevant_quantum_numbers.append(GLOBALS.QuantumNumber.down)

	if ConnectedInteraction.has_base_particle_connected(GLOBALS.Particle.charm):
		relevant_quantum_numbers.append(GLOBALS.QuantumNumber.charm)

	if ConnectedInteraction.has_base_particle_connected(GLOBALS.Particle.strange):
		relevant_quantum_numbers.append(GLOBALS.QuantumNumber.strange)

	if ConnectedInteraction.has_base_particle_connected(GLOBALS.Particle.top):
		relevant_quantum_numbers.append(GLOBALS.QuantumNumber.top)

	if ConnectedInteraction.has_base_particle_connected(GLOBALS.Particle.bottom):
		relevant_quantum_numbers.append(GLOBALS.QuantumNumber.bottom)
	
	return relevant_quantum_numbers

func is_integer(test_float: float) -> bool:
	return is_zero_approx(abs(test_float) - floor(abs(test_float)))

func _on_close_button_pressed():
	emit_signal("closed_button_pressed")

func _on_tab_container_child_entered_tree(node: Control):
	node.material = load("res://Resources/Shaders/palette_swap_material.tres")
	node.mouse_filter = Control.MOUSE_FILTER_PASS
