extends InfoPanel

var has_particles: bool = false
var quantum_numbers_matching: bool = true

func toggle_invalid_quantum_numbers(valid: bool) -> void:
	quantum_numbers_matching = valid
	
	$VBoxContainer/VBoxContainer/InvalidQuantumNumbers.visible = !quantum_numbers_matching
	
	$VBoxContainer/Buttons/NextStep.disabled = !(quantum_numbers_matching and has_particles)

func toggle_no_particles(_has_particles: bool) -> void:
	has_particles = _has_particles
	
	$VBoxContainer/VBoxContainer/NoParticles.visible = !has_particles
	$VBoxContainer/Buttons/NextStep.disabled = !(quantum_numbers_matching and has_particles)
