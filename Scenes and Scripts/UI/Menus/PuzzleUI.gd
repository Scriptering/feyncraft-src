extends PullOutTab

enum HadronFrequency {Always, Allowed, Never}

@export var MINIMUM_PARTICLE_COUNT: int = 3
@export var MAXIMUM_PARTICLE_COUNT: int = 8
@export var STARTING_MAX_PARTICLE_COUNT: int = 6

@export var EMCheck: CheckButton
@export var StrongCheck: CheckButton
@export var WeakCheck: CheckButton
@export var ElectroweakCheck: CheckButton
@export var HadronFrequencySlider: HSlider
@export var MinParticleCount: SpinBox
@export var MaxParticleCount: SpinBox

func _ready() -> void:
	super()
	
	MinParticleCount.min_value = MINIMUM_PARTICLE_COUNT
	MaxParticleCount.value = STARTING_MAX_PARTICLE_COUNT
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
	MaxParticleCount.min_value = value
	
func _on_max_particle_count_value_changed(value: float) -> void:
	MinParticleCount.max_value = value

func get_checks() -> Array[bool]:
	return [
		EMCheck.button_pressed,
		StrongCheck.button_pressed,
		WeakCheck.button_pressed,
		ElectroweakCheck.button_pressed
	]
