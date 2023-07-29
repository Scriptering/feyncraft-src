class_name InteractionMatrix
extends ConnectionMatrix

enum {UNCONNECTED, CONNECTED}

var unconnected_matrix: Array = []
var interaction_matrix : Array = [unconnected_matrix, connection_matrix]

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

func connect_interactions(
	connect_from_id: int, connect_to_id: int,
	particle: int = GLOBALS.PARTICLE.none, bidirectional: bool = false
) -> void:
	super.connect_interactions(connect_from_id, connect_to_id, particle, bidirectional)
	
	unconnected_matrix[connect_from_id].erase(particle)
	
	if bidirectional:
		unconnected_matrix[connect_to_id].erase(particle)
	
func disconnect_interactions(
	disconnect_from_id: int, disconnect_to_id: int,
	particle: int = GLOBALS.PARTICLE.none, bidirectional: bool = false
) -> void:
	super.disconnect_interactions(disconnect_from_id, disconnect_to_id, particle, bidirectional)
	
	unconnected_matrix[disconnect_from_id].append(particle)
	
	if bidirectional:
		unconnected_matrix[disconnect_to_id].append(particle)
