class_name MainDiagram
extends DiagramBase

signal action_taken

@export var freeze_vision: bool = false
@export var freeze_statelines: bool = false

@export var vision_line_offset: float = 6
@export var min_vision_line_offset_factor: float = 5
@export var max_vision_line_offset_factor: float = 15

@onready var Crosshair := $DiagramArea/Crosshair
@onready var DiagramArea := $DiagramArea
@onready var VisionLines := $DiagramArea/VisionLines
@export var Title: LineEdit

@onready var VisionLine := preload("res://Scenes and Scripts/Diagram/vision_line.tscn")

var ParticleButtons: Control
var Controls: Node
var VisionButtons: Control
var Vision: Node
var StateManager: Node

var line_diagram_actions: bool = true
var show_line_labels: bool = true:
	set = _set_show_line_labels

var hovering: bool = false

var vision_update_queued: bool = false

var crosshair_above_interactions: bool = false

const MASS_PRECISION: float = 1e-4

const MAX_DIAGRAM_HISTORY_SIZE : int = 10
var diagram_history: Array[DrawingMatrix] = []
var diagram_future: Array[DrawingMatrix] = []
var current_diagram: DrawingMatrix = null
var diagram_added_to_history: bool = false

var update_queued: bool = true
var drawing_matrix: DrawingMatrix

func _ready() -> void:
	Crosshair.moved_and_rested.connect(_crosshair_moved)
	Crosshair.moved.connect(_crosshair_moved)
	mouse_entered.connect(Crosshair.DiagramMouseEntered)
	mouse_exited.connect(Crosshair.DiagramMouseExited)
	EventBus.signal_draw_raw_diagram.connect(draw_raw_diagram)
	EventBus.signal_draw_diagram.connect(draw_diagram)
	action_taken.connect(EventBus.action_taken)
	
	for state_line:StateLine in StateLines:
		state_line.init(self)

func init(
	particle_buttons: Control, controls: Node, vision_buttons: Control, vision: Node, state_manager: Node
) -> void:
	ParticleButtons = particle_buttons
	Controls = controls
	VisionButtons = vision_buttons
	Vision = vision
	StateManager = state_manager
	
	Crosshair.init(self, StateLines, grid_size)
	
	Controls.clear_diagram.connect(
		func() -> void: 
			add_diagram_to_history()
			clear_diagram()
	)
	Controls.undo.connect(undo)
	Controls.redo.connect(redo)
	
	vision_buttons.vision_button_toggled.connect(_on_vision_button_toggled)

func _process(_delta: float) -> void:
	for stateline:StateLine in StateLines:
		if stateline.grabbed:
			move_stateline(stateline)

	flush_update_queue()

func flush_update_queue():
	if update_queued:
		update_queued = false
	
	for interaction:Interaction in $DiagramArea/Interactions.get_children():
		if interaction.update_queued:
			interaction.update_queued = false
			interaction.update()

	for particle_line:ParticleLine in $DiagramArea/ParticleLines.get_children():
		if particle_line.update_queued:
			particle_line.update_queued = false
			particle_line.update()

	if vision_update_queued:
		vision_update_queued = false
		update_vision()

func move_connected_particle_lines(interaction:Interaction) -> void:
	for particle_line:ParticleLine in interaction.connected_lines:
		particle_line.move(particle_line.get_connected_point(interaction), interaction.positioni())

func _crosshair_moved(new_position: Vector2i, old_position: Vector2i) -> void:
	if (
		StateManager.state != BaseState.State.Placing
		&& StateManager.state != BaseState.State.Drawing
	):
		return
	
	for interaction:Interaction in get_interactions():
		if interaction.grabbed:
			move_interaction(interaction, new_position)

	for pos:Vector2i in [new_position, old_position]:
		var state_to_update := position_stateline(position)
		
		if state_to_update == StateLine.State.None:
			continue
		
		StateLines[state_to_update].queue_update()

func move_interaction(interaction: Interaction, to_position: Vector2i) -> void:
	interaction.move(to_position)
	move_connected_particle_lines(interaction)
	queue_vision_update()

func position_stateline(pos: Vector2i) -> StateLine.State:
	if StateLines[StateLine.State.Initial].position.x == pos.x:
		return StateLine.State.Initial
	
	if StateLines[StateLine.State.Final].position.x == pos.x:
		return StateLine.State.Final
	
	return StateLine.State.None

func _set_show_line_labels(new_value: bool) -> void:
	show_line_labels = new_value
	
	for particle_line:ParticleLine in get_particle_lines():
		particle_line.show_labels = show_line_labels 
		particle_line.set_text_visiblity()

func load_problem(problem: Problem, mode: BaseMode.Mode) -> void:
	clear_diagram()
	
	set_title(problem.title)
	
	var is_creating_problem: bool = mode in [BaseMode.Mode.ParticleSelection, BaseMode.Mode.ProblemCreation, BaseMode.Mode.SolutionCreation]
	
	set_title_visible(is_creating_problem or problem.title != '')
	set_title_editable(is_creating_problem)

func are_quantum_numbers_matching(ignore_weak_quantum_numbers: bool = true) -> bool:
	var initial_quantum_numbers: PackedFloat32Array = StateLines[StateLine.State.Initial].get_quantum_numbers()
	var final_quantum_numbers: PackedFloat32Array = StateLines[StateLine.State.Final].get_quantum_numbers()
	
	for quantum_number:ParticleData.QuantumNumber in ParticleData.QuantumNumber.values():
		if ignore_weak_quantum_numbers and quantum_number in ParticleData.WEAK_QUANTUM_NUMBERS:
			continue
		
		if !is_zero_approx(initial_quantum_numbers[quantum_number]-final_quantum_numbers[quantum_number]):
			return false
	
	return true

func convert_path_colours(path_colours: Array, vision: Globals.Vision) -> Array[Color]:
	var path_colors: Array[Color] = []
	
	for path_colour:int in path_colours:
		path_colors.push_back(Globals.vision_colours[vision][path_colour])
	
	return path_colors

func update_colourless_interactions(
	paths: Array[PackedInt32Array], path_colours: Array, diagram: DrawingMatrix, is_vision_matrix: bool = false
) -> void:
	if paths.size() == 0:
		return

	var colourless_interactions: PackedInt32Array = Vision.find_colourless_interactions(paths, path_colours, diagram, is_vision_matrix)
	
	for id:int in range(diagram.matrix_size):
		get_interaction_from_matrix_id(id, diagram).valid_colourless = id not in colourless_interactions

func sort_drawing_interactions(interaction1: Interaction, interaction2: Interaction) -> bool:
	var state1: StateLine.State = position_stateline(interaction1.positioni())
	var state2: StateLine.State = position_stateline(interaction2.positioni())
	
	if state1 != state2:
		return state1 < state2
	
	var pos_y1: int = int(interaction1.position.y)
	var pos_y2: int = int(interaction2.position.y)
	
	if state1 == StateLine.State.None:
		return pos_y1 < pos_y2
	
	var particle1: ParticleData.Particle = interaction1.connected_particles.front()
	var particle2: ParticleData.Particle = interaction2.connected_particles.front()
	
	if abs(particle1) != abs(particle2):
		return abs(particle1) < abs(particle2) 
	
	if particle1 != particle2:
		return particle1 < particle2
	
	return pos_y1 < pos_y2

func is_valid_vision_interaction(interaction: Interaction) -> bool:
	if !interaction:
		return false
	
	if !interaction.valid:
		return false
	
	return true

func generate_drawing_matrix_from_diagram(get_only_valid: bool = false) -> DrawingMatrix:
	var generated_matrix := DrawingMatrix.new()
	var interactions: Array[Interaction] = get_interactions()
	
	interactions.sort_custom(sort_drawing_interactions)

	for interaction:Interaction in interactions:
		generated_matrix.add_interaction_with_position(
			interaction.position, grid_size, position_stateline(interaction.positioni())
		)

	for particle_line:ParticleLine in get_particle_lines():
		if get_only_valid and !particle_line.connected_interactions.all(is_valid_vision_interaction):
			continue
		
		generated_matrix.connect_interactions(
			generated_matrix.get_interaction_positions().find(particle_line.points[ParticleLine.Point.Start] / grid_size),
			generated_matrix.get_interaction_positions().find(particle_line.points[ParticleLine.Point.End] / grid_size),
			particle_line.base_particle
		)
	
	for state:int in StateLines.size():
		generated_matrix.state_line_positions[state] = int(StateLines[state].position.x / grid_size)
	
	var hadron_ids: Array[PackedInt32Array] = []
	for hadron_joint:HadronJoint in get_hadron_joints():
		var hadron_id: PackedInt32Array = []
		for interaction:Interaction in interactions.filter(
			func(interaction: Interaction) -> bool: 
				return interaction in hadron_joint.get_hadron_interactions()
		):
			hadron_id.push_back(
				ArrayFuncs.find_var(
					generated_matrix.get_interaction_positions(grid_size),
					func(interaction_position: Vector2) -> bool:
						return interaction.position == interaction_position
			))
		hadron_ids.push_back(hadron_id)
	generated_matrix.split_hadron_ids = hadron_ids
	
	return generated_matrix

func update_colour(diagram: DrawingMatrix, current_vision: Globals.Vision) -> void:
	var colour_matrix: DrawingMatrix = Vision.generate_vision_matrix(Globals.Vision.Colour, diagram)
	
	var time := Time.get_ticks_usec()
	var zip: Array = Vision.generate_vision_paths(Globals.Vision.Colour, colour_matrix, true)
	
	
	if zip == []:
		return
	
	var colour_paths: Array[PackedInt32Array] = zip.front()
	var colour_path_colours: Array = zip.back()
	
	update_colourless_interactions(colour_paths, colour_path_colours, colour_matrix, true)
	
	if current_vision == Globals.Vision.Colour:
		draw_vision_lines(colour_paths, convert_path_colours(colour_path_colours, current_vision), colour_matrix)
	print(Time.get_ticks_usec() - time)

func update_path_vision(diagram: DrawingMatrix, current_vision: Globals.Vision) -> void:
	var vision_matrix: DrawingMatrix = Vision.generate_vision_matrix(current_vision, diagram)
	var zip : Array = Vision.generate_vision_paths(current_vision, vision_matrix, true)
	
	if zip == []:
		return
	
	var paths : Array[PackedInt32Array] = zip.front()
	var path_colours : Array = zip.back()
	
	if paths.size() == 0:
		return

	draw_vision_lines(paths, convert_path_colours(path_colours,current_vision), vision_matrix)

func update_vision(
	diagram: DrawingMatrix = generate_drawing_matrix_from_diagram(true), current_vision: Globals.Vision = VisionButtons.get_active_vision()
) -> void:
	
	if freeze_vision:
		return
	
	clear_vision_lines()
	
	if get_interactions().size() == 0:
		return
	
	update_colour(diagram, current_vision)
	
	if current_vision in [Globals.Vision.Shade]:
		update_path_vision(diagram,current_vision)
		return

func _on_vision_button_toggled(_vision: Globals.Vision) -> void:
	queue_vision_update()

func move_stateline(stateline: StateLine) -> void:
	var non_state_interactions : Array[Interaction] = []
	var state_interactions : Array[Interaction] = []
	var interaction_x_positions : Array[int] = []
	
	for interaction:Interaction in get_interactions():
		if position_stateline(interaction.positioni()) == StateLine.State.None:
			non_state_interactions.push_back(interaction)
			interaction_x_positions.push_back(interaction.positioni().x)
		elif position_stateline(interaction.positioni()) == stateline.state:
			state_interactions.push_back(interaction)
	
	stateline.position.x = get_movable_state_line_position(stateline.state, interaction_x_positions)
	
	for interaction:Interaction in state_interactions:
		var interaction_position: Vector2 = interaction.position
		interaction.position.x = stateline.position.x
		
		for particle_line in interaction.connected_lines:
			particle_line.points[particle_line.get_point_at_position(interaction_position)].x = stateline.position.x
			particle_line.queue_update()
		
		interaction.queue_update()

func get_movable_state_line_position(state: StateLine.State, interaction_x_positions: Array) -> int:
	var test_position : int = snapped(get_local_mouse_position().x - DiagramArea.position.x, grid_size)
	
	match state:
		StateLine.State.Initial:
			test_position = min(test_position, StateLines[StateLine.State.Final].position.x - grid_size)
			
			if interaction_x_positions.size() != 0:
				test_position = min(test_position, interaction_x_positions.min() - grid_size)
		
		StateLine.State.Final:
			test_position = max(test_position, StateLines[StateLine.State.Initial].position.x + grid_size)
			
			if interaction_x_positions.size() != 0:
				test_position = max(test_position, interaction_x_positions.max() + grid_size)
	
	test_position = clamp(test_position, 0, DiagramArea.size.x)
	
	return test_position

func update_statelines() -> void:
	if freeze_statelines:
		return
	
	for state_line:StateLine in StateLines:
		state_line.queue_update()

func is_interaction_placement_valid(interaction: Interaction) -> bool:
	for test_interaction:Interaction in get_interactions():
		if test_interaction == interaction:
			continue
		
		if test_interaction.positioni() == interaction.positioni():
			return false
	
	return true

func connect_particle_line(
	particle_line: ParticleLine,
	point:ParticleLine.Point,
	interaction:Interaction=null
):
	var prev_interaction:Interaction = particle_line.connected_interactions[point]
	
	if interaction and prev_interaction:
		if interaction == prev_interaction:
			return
		
		prev_interaction.disconnect_line(particle_line)
	
	if interaction:
		particle_line.connect_interaction(interaction, point)
		interaction.connect_line(particle_line)
	else:
		var to_connect_interaction := get_interaction_at_position(particle_line.points[point])
		
		to_connect_interaction.connect_line(particle_line)
		particle_line.connect_interaction(to_connect_interaction, point)

func is_line_placement_valid(particle_line: ParticleLine) -> bool:
	if (
		particle_line.points[ParticleLine.Point.Start]
		== particle_line.points[ParticleLine.Point.End]
	):
		return false
	
	for comparison_particle_line:ParticleLine in get_particle_lines():
		if particle_line.is_duplicate(comparison_particle_line):
			return false
		
	for comparison_particle_line:ParticleLine in get_particle_lines():
		if particle_line.is_overlapping(comparison_particle_line):
			return false
	
	var start_stateline := position_stateline(particle_line.points[ParticleLine.Point.Start])
	if (
		start_stateline != StateLine.State.None
		and (
		start_stateline
		== position_stateline(particle_line.points[ParticleLine.Point.End])
		)
	):
		return false
	
	return true

func get_interactions() -> Array[Interaction]:
	var interactions : Array[Interaction] = []
	
	for child:Interaction in $DiagramArea/Interactions.get_children():
		if child and !child.is_queued_for_deletion():
			interactions.push_back(child)

	return interactions

func get_particle_lines() -> Array[ParticleLine]:
	var particle_lines : Array[ParticleLine] = []
	
	for child:ParticleLine in $DiagramArea/ParticleLines.get_children():
		if child and !child.is_queued_for_deletion():
			particle_lines.push_back(child)

	return particle_lines

func get_selected_particle() -> ParticleData.Particle:
	return ParticleButtons.selected_particle

func action() -> void:
	update_vision()
	action_taken.emit()

func queue_vision_update() -> void:
	vision_update_queued = true

func update_particle_lines() -> void:
	for particle_line:ParticleLine in get_particle_lines():
		particle_line.queue_update()

func update_interactions() -> void:
	for interaction:Interaction in get_interactions():
		interaction.queue_update()

func disconnect_line(particle_line:ParticleLine) -> void:
	for interaction:Interaction in particle_line.connected_interactions:
		interaction.disconnect_line(particle_line)

func delete_line(particle_line: ParticleLine, add_to_history:bool = true) -> void:
	if add_to_history:
		add_diagram_to_history()

	particle_line.delete()
	
	disconnect_line(particle_line)
	
	remove_lonely_interactions(particle_line.connected_interactions)
	
	check_rejoin_lines(particle_line.connected_interactions)
	queue_vision_update()

func delete_interaction(interaction: Interaction, add_to_history:bool = true) -> void:
	if add_to_history:
		add_diagram_to_history()

	interaction.delete()
	var connected_lines : Array[ParticleLine] = interaction.connected_lines.duplicate()
	for particle_line:ParticleLine in connected_lines:
		delete_line(particle_line, false)
	queue_vision_update()

func remove_lonely_interactions(interactions: Array[Interaction] = get_interactions()):
	for interaction:Interaction in interactions:
		if interaction.connected_lines.size() == 0:
			interaction.queue_free()

func split_line(line_to_split: ParticleLine, split_interaction: Interaction) -> void:
	var new_start_point: Vector2 = line_to_split.points[ParticleLine.Point.Start]
	
	line_to_split.points[ParticleLine.Point.Start] = split_interaction.positioni()
	
	var new_particle_line := draw_particle_line(
		new_start_point, split_interaction.positioni(), line_to_split.base_particle
	)
	
	connect_particle_line(
		new_particle_line,
		ParticleLine.Point.Start,
		line_to_split.connected_interactions[ParticleLine.Point.Start]
	)
	connect_particle_line(
		new_particle_line,
		ParticleLine.Point.End,
		split_interaction
	)
	connect_particle_line(
		line_to_split,
		ParticleLine.Point.Start,
		split_interaction
	)
	
	line_to_split.queue_update()
	new_particle_line.queue_update()
	queue_vision_update()

func is_interaction_on_line(interaction: Interaction, particle_line: ParticleLine) -> bool:
	if particle_line in interaction.connected_lines:
		return false
		
	return particle_line.is_position_on_line(interaction.position)

func get_interaction_on_particle_line(particle_line: ParticleLine) -> Interaction:
	for interaction:Interaction in get_interactions():
		if is_interaction_on_line(interaction, particle_line):
			return interaction
	
	return null

func get_particle_line_on_interaction(interaction: Interaction) -> ParticleLine:
	for particle_line:ParticleLine in get_particle_lines():
		if is_interaction_on_line(interaction, particle_line):
			return particle_line
	
	return null

func check_rejoin_lines(interactions: Array[Interaction] = get_interactions()) -> void:
	if !line_diagram_actions:
		return
	
	for interaction:Interaction in interactions:
		if interaction.connected_lines.size() != 2:
			continue
		if interaction.connected_lines.any(
			func(particle_line:ParticleLine) -> bool:
				return !is_instance_valid(particle_line)
		):
			continue
		
		if can_rejoin_lines(interaction.connected_lines[0], interaction.connected_lines[1]):
			rejoin_lines(interaction.connected_lines[0], interaction.connected_lines[1])
			interaction.delete()

func can_rejoin_lines(line1: ParticleLine, line2: ParticleLine) -> bool:
	if line1.particle != line2.particle:
		return false

	if (
		line1.line_vector.normalized() == line2.line_vector.normalized() or
		line1.line_vector.normalized() == -line2.line_vector.normalized()
	):
		return true
	
	return false

func rejoin_lines(line_to_extend: ParticleLine, line_to_delete: ParticleLine) -> void:
	var point_to_move : int
	
	if line_to_extend.points[ParticleLine.Point.Start] in line_to_delete.points:
		point_to_move = ParticleLine.Point.Start
	else:
		point_to_move = ParticleLine.Point.End
	
	var point_to_move_to : int
	if line_to_delete.points[ParticleLine.Point.Start] in line_to_extend.points:
		point_to_move_to = ParticleLine.Point.End
	else:
		point_to_move_to = ParticleLine.Point.Start
	
	line_to_extend.points[point_to_move] = line_to_delete.points[point_to_move_to]
	line_to_extend.connected_interactions[point_to_move] = line_to_delete.connected_interactions[point_to_move_to]
	line_to_extend.connected_interactions[point_to_move].connect_line(line_to_extend)
	
	line_to_delete.delete()
	disconnect_line(line_to_delete)
	line_to_extend.queue_update()
	queue_vision_update()

func connect_interaction(interaction:Interaction) -> void:
	for particle_line:ParticleLine in get_particle_lines():
		if interaction.positioni() not in particle_line.points:
			continue
		
		interaction.connect_line(particle_line)
		particle_line.connect_interaction(interaction)

func get_interaction_at_position(pos: Vector2i) -> Interaction: 
	for interaction:Interaction in get_interactions():
		if interaction.grabbed:
			continue
		
		if interaction.positioni() == pos:
			return interaction
	
	return null

func start_drawing(start_position: Vector2i) -> void:
	add_diagram_to_history()
	
	if !get_interaction_at_position(start_position):
		draw_interaction(start_position)
	
	var grabbed_interaction: Interaction = InteractionInstance.instantiate()
	grabbed_interaction.pick_up()
	place_interaction(Crosshair.position, grabbed_interaction)
	
	var particle_line := draw_particle_line(start_position)
	
	connect_particle_line(
		particle_line,
		ParticleLine.Point.Start,
		get_interaction_at_position(start_position)
	)
	connect_particle_line(
		particle_line,
		ParticleLine.Point.End,
		grabbed_interaction
	)

func transfer_interaction_connections(from_interaction:Interaction, to_interaction:Interaction) -> void:
	for particle_line:ParticleLine in from_interaction.connected_lines:
		connect_particle_line(
			particle_line,
			particle_line.get_connected_point(from_interaction),
			to_interaction
		)

func drop_interaction(interaction: Interaction) -> void:
	if ArrayFuncs.is_vec_zero_approx(interaction.position - interaction.start_grab_position):
		remove_last_diagram_from_history()
	
	print("interaction dropped")
	
	for particle_line:ParticleLine in interaction.connected_lines:
		if !is_line_placement_valid(particle_line):
			print("line placement invalid")
			delete_line(particle_line)
			continue
		
		check_split_lines(particle_line)
	
	if interaction.is_queued_for_deletion():
		return
	
	var connected_lines: Array[ParticleLine] = interaction.connected_lines.duplicate()
	if is_interaction_placement_valid(interaction):
		interaction.drop()
		check_split_lines(interaction)
	else:
		interaction.queue_free()
		var interaction_at_position := get_interaction_at_position(interaction.positioni())
		transfer_interaction_connections(
			interaction,
			interaction_at_position
		)
	
	for particle_line:ParticleLine in connected_lines:
		check_rejoin_lines(particle_line.connected_interactions)

func draw_interaction(
	interaction_position: Vector2, interaction: Node = InteractionInstance.instantiate(), is_action: bool = true
) -> Interaction:
	place_interaction(interaction_position, interaction)
	check_split_lines(interaction)
	
	return interaction

func check_split_lines(object: Variant) -> void:
	if object is Interaction:
		var splitting_line := get_particle_line_on_interaction(object)
		if splitting_line:
			split_line(splitting_line, object)
	
	if object is ParticleLine:
		var splitting_interaction := get_interaction_on_particle_line(object)
		if splitting_interaction:
			split_line(object, splitting_interaction)

func split_interaction(interaction: Interaction) -> void:
	if interaction.connected_lines.size() == 1: 
		return
	
	var picked_particle_line: ParticleLine = choose_split_particle_line(interaction)
	
	var staying_interaction: Interaction = InteractionInstance.instantiate()
	place_interaction(interaction.position, staying_interaction)
	
	var connected_lines := interaction.connected_lines.duplicate()
	for particle_line:ParticleLine in connected_lines:
		if particle_line == picked_particle_line:
			continue
		
		connect_particle_line(
			particle_line,
			particle_line.get_connected_point(interaction),
			staying_interaction
		)
	
	interaction.update_dot_visual()
	interaction.valid = interaction.validate()
	
	check_rejoin_lines([staying_interaction])

func choose_split_particle_line(splitting_interaction: Interaction) -> ParticleLine:
	var interaction_position: Vector2 = splitting_interaction.position
	var mouse_position: Vector2 = Interactions.get_local_mouse_position()
	var interaction_to_mouse_vector: Vector2 = (mouse_position - interaction_position).normalized()
	
	var smallest_angle: float = 2*PI
	
	var chosen_particle_line: ParticleLine
	
	for particle_line in splitting_interaction.connected_lines:
		var line_vector: Vector2 = splitting_interaction.get_unconnected_line_vector(particle_line).normalized()
		var angle: float = min(
			min(line_vector.angle_to(interaction_to_mouse_vector), interaction_to_mouse_vector.angle_to(line_vector)),
			min(line_vector.angle_to(-interaction_to_mouse_vector), (-interaction_to_mouse_vector).angle_to(line_vector))
		)
		
		if angle <= smallest_angle:
			smallest_angle = angle
			chosen_particle_line = particle_line
	
	return chosen_particle_line

func can_place_interaction(test_position: Vector2, test_interaction: Interaction = null) -> bool:
	for interaction:Interaction in Interactions.get_children():
		if interaction == test_interaction:
			continue
		
		if interaction.is_queued_for_deletion():
			continue
		
		if interaction.position == test_position:
			return false

	return true

func draw_particle_line(
	start_position: Vector2i, end_position: Vector2i = Vector2i.ZERO,
	base_particle: ParticleData.Particle = ParticleButtons.selected_particle
) -> ParticleLine:
	var particle_line : ParticleLine = create_particle_line()
	particle_line.init(self)
	
	particle_line.points[particle_line.Point.Start] = start_position
	
	if end_position == Vector2i.ZERO:
		particle_line.points[particle_line.Point.End] = Crosshair.positioni()
	else:
		particle_line.points[particle_line.Point.End] = end_position
	
	particle_line.base_particle = base_particle
	particle_line.show_labels = show_line_labels
	
	ParticleLines.add_child(particle_line)
	particle_line.update()
	
	return particle_line

func draw_raw_diagram(connection_matrix : ConnectionMatrix) -> void:
	if !is_inside_tree():
		return
	
	add_diagram_to_history()
	
	super.draw_raw_diagram(connection_matrix)

func clear_vision_lines() -> void:
	for vision_line in VisionLines.get_children():
		vision_line.queue_free()

func clear_diagram() -> void:
	for interaction:Interaction in Interactions.get_children():
		delete_interaction(interaction)
	for state_line:StateLine in StateLines:
		state_line.clear_hadrons()
	clear_vision_lines() 

func draw_diagram(drawing_matrix: DrawingMatrix) -> void:
	if !is_inside_tree():
		return
	
	line_diagram_actions = false
	
	clear_diagram()
	
	for state:int in StateLines.size():
		StateLines[state].position.x = drawing_matrix.state_line_positions[state] * grid_size

	for interaction_position:Vector2 in drawing_matrix.get_interaction_positions():
		place_interaction(interaction_position * grid_size)
		
	for drawing_particle:ParticleLine in super.draw_diagram_particles(drawing_matrix):
		ParticleLines.add_child(drawing_particle)
		connect_particle_line(
			drawing_particle,
			ParticleLine.Point.Start,
			get_interaction_at_position(drawing_particle.points[ParticleLine.Point.Start])
		)
		connect_particle_line(
			drawing_particle,
			ParticleLine.Point.End,
			get_interaction_at_position(drawing_particle.points[ParticleLine.Point.End])
		)

func undo() -> void:
	if !is_inside_tree():
		return
	
	move_backward_in_history()
	
	await get_tree().process_frame

func redo() -> void:
	if !is_inside_tree():
		return
	
	move_forward_in_history()
	
	await get_tree().process_frame
func add_diagram_to_history(clear_future: bool = true, diagram: DrawingMatrix = generate_drawing_matrix_from_diagram()) -> void:
	if !is_inside_tree():
		return
	
	diagram_history.append(diagram)
	
	if clear_future:
		diagram_future.clear()
	
	if diagram_history.size() > MAX_DIAGRAM_HISTORY_SIZE:
		diagram_history.pop_front()

func add_diagram_to_future(diagram: DrawingMatrix = generate_drawing_matrix_from_diagram()) -> void:
	diagram_future.push_back(diagram)
	
func remove_last_diagram_from_history() -> void:
	diagram_history.pop_back()

func move_forward_in_history() -> void:
	if diagram_future.size() == 0:
		return
		
	add_diagram_to_history(false, current_diagram)
	current_diagram = diagram_future.back()
	diagram_future.pop_back()
	
	draw_diagram(current_diagram)

func move_backward_in_history() -> void:
	if diagram_history.size() == 0:
		return
	elif diagram_future.size() == 0:
		add_diagram_to_future()
	else:
		add_diagram_to_future(current_diagram)
	
	current_diagram = diagram_history.back()
	diagram_history.pop_back()
	draw_diagram(current_diagram)

func print_history_sizes() -> void:
	print("Diagram history size = " + str(diagram_history.size()))
	print("Diagram future  size  = " + str(diagram_future.size()))

func draw_history() -> void:
	if !is_inside_tree():
		return
	
	for diagram in diagram_history:
		draw_diagram(diagram)
		await get_tree().create_timer(0.5).timeout
	
	for diagram in diagram_future:
		draw_diagram(diagram)
		await get_tree().create_timer(0.5).timeout

func is_valid() -> bool:
	return get_interactions().all(
		func(interaction: Interaction) -> bool: 
			return interaction.valid
	)

func is_fully_connected(bidirectional: bool) -> bool:
	var diagram: DrawingMatrix = generate_drawing_matrix_from_diagram()
	
	return (
		diagram.is_fully_connected(bidirectional) and
		diagram.get_lonely_extreme_points(
			ConnectionMatrix.EntryFactor.Both
		).size() == 0
	)

func is_energy_conserved() -> bool:
	var state_base_particles: Array = StateLines.map(
		func(state_line: StateLine) -> Array:
			return state_line.get_connected_base_particles()
	)
	
	var state_masses: Array = state_base_particles.map(
		func(base_particles: Array) -> float:
			return base_particles.reduce(
				func(accum: float, particle: ParticleData.Particle) -> float:
					return accum + ParticleData.PARTICLE_MASSES[particle],
				0.0
		)
	)
	
	for state_type:StateLine.State in StateLine.STATES:
		if state_base_particles[state_type].size() > 1:
			continue
		
		if state_masses[state_type] < state_masses[(state_type + 1) % 2] - MASS_PRECISION:
			return false
	
	return true

func get_interaction_from_matrix_id(id: int, matrix: DrawingMatrix) -> Interaction:
	var interaction_position: Vector2 = matrix.get_interaction_positions(grid_size)[id]
	
	return get_interactions()[
		ArrayFuncs.find_var(
			get_interactions(),
			func(interaction: Interaction) -> bool:
				return interaction.position == interaction_position
	)]

func vector_intercept_factor(vec1_start: Vector2, vec1_dir: Vector2, vec2_start: Vector2, vec2_dir: Vector2) -> float:
	var nominator: float = (vec2_dir.x * (vec2_start.y - vec1_start.y) + vec2_dir.y * (vec1_start.x - vec2_start.x))
	var denominator: float = (vec2_dir.x * vec1_dir.y - vec2_dir.y * vec1_dir.x)
	
	return nominator / denominator

func vector_intercept(vec1_start: Vector2, vec1_dir: Vector2, vec2_start: Vector2, vec2_dir: Vector2) -> Vector2:
	return vec1_start + vector_intercept_factor(vec1_start, vec1_dir, vec2_start, vec2_dir) * vec1_dir

func get_starting_vision_offset_vector(
	path: PackedInt32Array, interaction_positions: PackedVector2Array, vision_matrix: DrawingMatrix
) -> Vector2:
	var forward_vector: Vector2 = interaction_positions[path[1]] - interaction_positions[path[0]]
	
	if vision_matrix.is_lonely_extreme_point(path[0]):
		return (interaction_positions[path[1]] - interaction_positions[path[0]]).orthogonal().normalized() * vision_line_offset
	
	if vision_matrix.get_state_from_id(path[0]) != StateLine.State.None:
		return (Vector2.UP * StateLine.state_factor[vision_matrix.get_state_from_id(path[0])]).normalized() * vision_line_offset
	
	var backward_vector: Vector2 = interaction_positions[path[-1]] - interaction_positions[path[-2]]
	
	if is_zero_approx(backward_vector.angle_to(forward_vector)):
		return forward_vector.orthogonal() * vision_line_offset
	
	return middle_vector(forward_vector, -backward_vector).normalized() * clamp(
		middle_vector(forward_vector, -backward_vector).length() * vision_line_offset,
		min_vision_line_offset_factor, max_vision_line_offset_factor
	)

func get_vision_offset_vector(
	current_point: int, path: PackedInt32Array, interaction_positions: PackedVector2Array, vision_matrix: DrawingMatrix
) -> Vector2:
	if vision_matrix.is_lonely_extreme_point(path[current_point+1]):
		return (interaction_positions[path[current_point+1]] - interaction_positions[path[current_point]]).orthogonal().normalized()
	
	if vision_matrix.get_state_from_id(path[current_point+1]) != StateLine.State.None:
		return (Vector2.UP * StateLine.state_factor[vision_matrix.get_state_from_id(path[current_point+1])]).normalized()
	
	var look_ahead_count: int = 2 + int(current_point == path.size() - 2)
	
	if is_zero_approx(
		(
			interaction_positions[path[(current_point+look_ahead_count) % path.size()]] -
			interaction_positions[path[(current_point+1) % path.size()]]).angle_to( 
			interaction_positions[path[(current_point+1) % path.size()]] - interaction_positions[path[current_point]]
		)
	):
		return (
			interaction_positions[path[(current_point+1) % path.size()]] -
			interaction_positions[path[current_point]]).orthogonal().normalized()
	
	return middle_vector(
		interaction_positions[path[(current_point+look_ahead_count) % path.size()]] -
		interaction_positions[path[(current_point+1) % path.size()]],
		interaction_positions[path[current_point]] - interaction_positions[path[(current_point+1) % path.size()]]
	).normalized()

func middle_vector(vec1: Vector2, vec2: Vector2) -> Vector2:
	return (vec1.normalized() + vec2.normalized()) * [-1, +1][int(vec1.angle_to(vec2) < vec2.angle_to(vec1))]

func get_starting_vision_line_position(
	path: PackedInt32Array, interaction_positions: PackedVector2Array, vision_matrix: DrawingMatrix
) -> Vector2:
	return (
		interaction_positions[path[0]] +
		get_starting_vision_offset_vector(path, interaction_positions, vision_matrix)
	)

func calculate_vision_line_points(path: PackedInt32Array, vision_matrix: DrawingMatrix) -> PackedVector2Array:
	var interaction_positions: PackedVector2Array = vision_matrix.get_interaction_positions(grid_size)
	
	var current_position: Vector2 = get_starting_vision_line_position(path, interaction_positions, vision_matrix)
	
	var vision_line_points: PackedVector2Array = [current_position]
	
	for i:int in range(path.size() - 1):
		var path_start: Vector2 = interaction_positions[path[i]]
		var path_vector: Vector2 = interaction_positions[path[i+1]] - path_start
		var vision_offset_vector: Vector2 = get_vision_offset_vector(i, path, interaction_positions, vision_matrix)
		
		var vs : float = vector_intercept_factor(interaction_positions[path[i+1]], vision_offset_vector, current_position, path_vector)
		
		var vision_offset_factor: float = sign(vs) * clamp(
			abs(vs),
			min_vision_line_offset_factor,
			max_vision_line_offset_factor
		)
		
		current_position = vision_offset_factor * vision_offset_vector + interaction_positions[path[i+1]]
		
		vision_line_points.push_back(current_position)
	
	return vision_line_points

func draw_vision_line(points: PackedVector2Array, path_colour: Color) -> void:
	var is_loop: bool = ArrayFuncs.is_vec_zero_approx(points[0] - points[-1])
	var vision_line : Line2D = VisionLine.instantiate()
	
	vision_line.closed = is_loop
	if is_loop:
		points.remove_at(-1)
	
	vision_line.points = points
	vision_line.colour = path_colour

	$DiagramArea/VisionLines.add_child(vision_line)

func draw_vision_lines(
	paths: Array[PackedInt32Array], path_colours: Array[Color], vision_matrix: DrawingMatrix
) -> void:
	for i:int in range(paths.size()):
		draw_vision_line(calculate_vision_line_points(paths[i], vision_matrix), path_colours[i])

func _on_mouse_entered() -> void:
	hovering = true

func _on_mouse_exited() -> void:
	hovering = false

func set_title_editable(editable: bool) -> void:
	Title.editable = editable

func set_title_visible(toggle: bool) -> void:
	Title.visible = toggle

func set_title(text: String) -> void:
	Title.text = text

func _on_title_text_submitted(new_text: String) -> void:
	Globals.creating_problem.title = new_text

func get_degree() -> int:
	var degree: int = 0
	
	for interaction:Interaction in get_interactions():
		degree += interaction.degree
	
	return degree
