extends InfoPanel

signal toggle_all(toggle: bool)

var hide_unavailable_particles: bool = false

func _on_toggle_on_pressed() -> void:
	toggle_all.emit(true)

func _on_toggle_off_pressed() -> void:
	toggle_all.emit(false)

func _on_hide_unavailable_particles_toggled(toggled_on: bool) -> void:
	hide_unavailable_particles = toggled_on

func enter(problem: Problem) -> void:
	%HideUnavailableParticles.button_pressed = problem.hide_unavailable_particles
