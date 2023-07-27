class_name StateLine
extends Node2D

@onready var Level = get_tree().get_first_node_in_group('level')
@onready var HadronJoint = preload("res://Scenes and Scripts/Diagram/Hadrons/HadronJoint.tscn")

@export var hadron_label_gap : int
@export var state : StateType

enum {NOT_FOUND}

enum StateType {None = -1, Initial, Final, Both}

var hadrons : Array[Hadron] = []
var joints : Array[HadronJoint] = []
var old_quark_groups: Array = [[]]

var connected_lone_particles : Array[GLOBALS.Particle] : get = _get_connected_lone_particles

class LineYSort:
	static func InitialSorter(line1: ParticleLine, line2: ParticleLine):
		if line1.left_point.y < line2.left_point.y:
			return true
		return false
		
	static func FinalSorter(line1: ParticleLine, line2: ParticleLine):
		if line1.right_point.y < line2.right_point.y:
			return true
		return false

class LineParticleSort:
	static func ParticleSorter(line1: ParticleLine, line2: ParticleLine):
		return line1.particle < line2.particle

func update_stateline() -> void:
	var connected_lines := get_connected_lines()
	if connected_lines.size() == 0:
		return
	var quark_groups := get_quark_groups(connected_lines)

	if quark_groups != old_quark_groups:
		old_quark_groups = quark_groups.duplicate(true)
		update_hadrons(quark_groups)

func get_quark_groups(connected_lines: Array = get_connected_lines()) -> Array:
	return group_connected_quarks(sort_connected_lines(connected_lines))

func update_hadrons(quark_groups: Array = get_quark_groups()) -> void:
	clear_hadrons()
	if quark_groups.size() == 0:
		return
	sort_quark_groups(quark_groups)
	create_hadrons(quark_groups)
	create_hadron_visuals()

func clear_hadrons() -> void:
	hadrons.clear()
	for joint in joints:
		joint.queue_free()
	joints.clear()

func create_hadron_visuals() -> void:
	for hadron in hadrons:
		create_hadron_joint(hadron)

func create_hadron_joint(hadron: Hadron) -> void:
	var joint = HadronJoint.instantiate()
	joint.hadron = hadron
	joint.state = state
	joint.init()
	Level.add_child(joint)
	joints.append(joint)

func create_hadrons(quark_groups: Array) -> void:
	for i in range(quark_groups.size()):
		var quark_group:Array = quark_groups[i]
		var group_hadron : GLOBALS.Hadrons = get_quark_group_hadron(quark_group)
		if group_hadron == NOT_FOUND:
			continue
		var hadron = Hadron.new()
		hadron.init(quark_group, group_hadron)
		hadrons.append(hadron)

func get_quark_group_hadron(quark_group: Array) -> GLOBALS.Hadrons:
	var quarks : Array[GLOBALS.Particle] = []
	for line in quark_group:
		quarks.append(line.particle)
	
	for hadron in GLOBALS.Hadrons.values():
		if quarks in GLOBALS.HADRON_QUARK_CONTENT[hadron]:
			return hadron
	return GLOBALS.Hadrons.Invalid

func sort_quark_groups(quark_groups: Array) -> Array:
	for quark_group in quark_groups:
		quark_group.sort_custom(Callable(LineParticleSort, "ParticleSorter"))
	return quark_groups

func get_connected_lines() -> Array[ParticleLine]:
	var connected_lines: Array = []
	for line in get_tree().get_nodes_in_group("lines"):
		if line.get_on_state_line() == state or line.get_on_state_line() == StateType.Both:
			connected_lines.append(line)
	return connected_lines

func sort_connected_lines(connected_lines: Array) -> Array:
	if state == StateType.Initial:
		connected_lines.sort_custom(Callable(LineYSort, "InitialSorter"))
	elif state == StateType.Final:
		connected_lines.sort_custom(Callable(LineYSort, "FinalSorter"))
	return connected_lines

func group_connected_quarks(sorted_connected_lines: Array) -> Array:
	var grouped_connected_lines : Array = []

	var current_y_point : float
	var current_group := []
	for line in sorted_connected_lines:
		if !line.base_particle in GLOBALS.QUARKS:
			continue
		if current_group.size() == 0:
			current_group.append(line)
		elif abs(line.get_side_point(state).y - current_y_point) == Level.grid_size:
			current_group.append(line)
		else:
			if current_group.size() > 1:
				grouped_connected_lines.append(current_group)
			if line != sorted_connected_lines[-1]:
				current_group = [line]
				
		current_y_point = line.get_side_point(state).y

	if current_group.size() > 1:
		grouped_connected_lines.append(current_group)

	return grouped_connected_lines

func _get_connected_lone_particles() -> Array[GLOBALS.Particle]:
	var connected_lines := get_connected_lines()
	var lone_connected_particles : Array[GLOBALS.Particle] = []
	
	for connected_line in connected_lines:
		if !connected_line.particle in GLOBALS.QUARKS:
			lone_connected_particles.append(connected_line.particle)
			continue
		for hadron in hadrons:
			if connected_line in hadron.quark_lines:
				continue
		lone_connected_particles.append(connected_line.particle)
	
	return lone_connected_particles

