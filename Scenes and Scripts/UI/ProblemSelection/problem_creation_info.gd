extends InfoPanel

func toggle_invalid_quantum_numbers(toggle: bool) -> void:
	$VBoxContainer/VBoxContainer/InvalidQuantumNumbers.visible = toggle
