class_name InteractionMatrix
extends ConnectionMatrix

enum {UNCONNECTED, CONNECTED}

var unconnected_matrix: Array = []
var interaction_matrix : Array = [unconnected_matrix, connection_matrix]

var unconnected_particle_count: PackedInt32Array = [0, 0, 0]

func add_interaction(
	interaction_state : StateLine.StateType = StateLine.StateType.None,
	id : int = calculate_new_interaction_id(interaction_state)
):
	super.add_interaction(interaction_state, id)
	
	unconnected_matrix.insert(id, [])

func add_unconnected_interaction(
	unconnected_particles: Array[GLOBALS.Particle] = [],
	interaction_state: StateLine.StateType = StateLine.StateType.None,
	id : int = calculate_new_interaction_id(interaction_state)
) -> void:
	super.add_interaction(interaction_state, id)
	
	unconnected_matrix.insert(id, unconnected_particles)
	unconnected_particle_count[interaction_state] += unconnected_particles.size()

func connect_interactions(
	connect_from_id: int, connect_to_id: int,
	particle: int = GLOBALS.PARTICLE.none, bidirectional: bool = false
) -> void:
	super.connect_interactions(connect_from_id, connect_to_id, particle, bidirectional)
	
	unconnected_matrix[connect_from_id].erase(particle)
	unconnected_particle_count[get_state_from_id(connect_from_id)] -= 1
	
	if bidirectional:
		unconnected_matrix[connect_to_id].erase(particle)
		unconnected_particle_count[get_state_from_id(connect_to_id)] -= 1

func insert_connection(connection: Array) -> void:
	connect_interactions(connection[Connection.from_id], connection[Connection.to_id], connection[Connection.particle])
	
func disconnect_interactions(
	disconnect_from_id: int, disconnect_to_id: int,
	particle: int = GLOBALS.PARTICLE.none, bidirectional: bool = false
) -> void:
	super.disconnect_interactions(disconnect_from_id, disconnect_to_id, particle, bidirectional)
	
	unconnected_matrix[disconnect_from_id].append(particle)
	unconnected_particle_count[get_state_from_id(disconnect_from_id)] += 1
	
	if bidirectional:
		unconnected_matrix[disconnect_to_id].append(particle)
		unconnected_particle_count[get_state_from_id(disconnect_to_id)] += 1

func remove_connection(connection: Array) -> void:
	disconnect_interactions(connection[Connection.from_id], connection[Connection.to_id], connection[Connection.particle])

func get_unconnected_particle_count(state: StateLine.StateType) -> int:
	if state == StateLine.StateType.Both:
		return unconnected_particle_count[StateLine.StateType.Initial] + unconnected_particle_count[StateLine.StateType.Final]
	
	return unconnected_particle_count[state]

func find_unconnected_particle(particle: GLOBALS.Particle) -> PackedInt32Array:
	var found_ids: PackedInt32Array = []
	for id in range(unconnected_matrix.size()):
		if particle in unconnected_matrix[id]:
			found_ids.append(id)
	
	return found_ids

func find_all_unconnected_state_particle(particle: GLOBALS.Particle, state: StateLine.StateType) -> PackedInt32Array:
	var found_ids: PackedInt32Array = []
	for id in range(get_starting_state_id(state), get_starting_state_id(state)+get_state_interaction_count(state)):
		for unconnected_particle in unconnected_matrix[id]:
			if unconnected_particle == particle:
				found_ids.append(id)
	return found_ids

func is_hadron(id: int) -> bool:
	return unconnected_matrix[id].size() > 1

func get_unconnected_particles() -> Array[GLOBALS.Particle]:
	var unconnected_particles : Array[GLOBALS.Particle] = []
	for interaction in unconnected_matrix:
		unconnected_particles += interaction
	return unconnected_particles

func get_unconnected_base_particles() -> Array:
	return get_unconnected_particles().map(func(particle): return abs(particle))
