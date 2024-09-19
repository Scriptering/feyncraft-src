extends PullOutTab

enum HadronFrequency {Always, Allowed, Never}

@export var MINIMUM_PARTICLE_COUNT: int = 2
@export var MAXIMUM_PARTICLE_COUNT: int = 8
@export var STARTING_MAX_PARTICLE_COUNT: int = 6

@export var HadronFrequencySlider: HSlider
@export var MinParticleCount: SpinBox
@export var MaxParticleCount: SpinBox

func _ready() -> void:
	super()
	
	MinParticleCount.min_value = MINIMUM_PARTICLE_COUNT
	MinParticleCount.max_value = MAXIMUM_PARTICLE_COUNT
	
	MaxParticleCount.value = STARTING_MAX_PARTICLE_COUNT
	
	MaxParticleCount.min_value = MINIMUM_PARTICLE_COUNT
	MaxParticleCount.max_value = MAXIMUM_PARTICLE_COUNT

var min_particle_count: int:
	get:
		return int(MinParticleCount.value)
var max_particle_count: int:
	get:
		return int(MaxParticleCount.value)
var hadron_frequency: HadronFrequency:
	get:
		return int(HadronFrequencySlider.value) as HadronFrequency

func reset() -> void:
	MinParticleCount.value = MINIMUM_PARTICLE_COUNT
	MaxParticleCount.value = STARTING_MAX_PARTICLE_COUNT
	HadronFrequencySlider.value = HadronFrequency.Allowed

func _on_min_particle_count_value_changed(value: float) -> void:
	MaxParticleCount.value = max(value, MaxParticleCount.value)
	
func _on_max_particle_count_value_changed(value: float) -> void:
	MinParticleCount.value = min(value, MinParticleCount.value)

func get_checks() -> Array[bool]:
	return [
		%electromagnetic_check.button_pressed,
		%strong_check.button_pressed,
		%weak_check.button_pressed,
		%electroweak_check.button_pressed
	]

func _on_electromagnetic_toggled(button_pressed: bool) -> void:
	if !button_pressed:
		%electroweak_check.button_pressed = false
	
func _on_weak_toggled(button_pressed: bool) -> void:
	if !button_pressed:
		%electroweak_check.button_pressed = false

func _on_electro_weak_toggled(button_pressed: bool) -> void:
	if button_pressed:
		%electromagnetic_check.button_pressed = true
		%weak_check.button_pressed = true
