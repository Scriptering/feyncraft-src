extends PanelContainer

signal sampling_escaped
signal sample_submitted(submitted_colour: Color)

var sampling: bool = false

@export var sampler_hint: ColorRect

var screen_image: Image

func _process(_delta: float) -> void:
	if !sampling:
		return
	
	var mouse_position: Vector2 = get_global_mouse_position()
	sampler_hint.color = screen_image.get_pixel(
		abs(mouse_position.x), abs(mouse_position.y)
	)

	if Input.is_action_just_pressed("escape"):
		sampling_escaped.emit()
		end_sampling()

	if Input.is_action_just_pressed("submit") or Input.is_action_just_pressed("click"):
		sample_submitted.emit(sampler_hint.color)
		end_sampling()

func _on_sampler_toggled(button_pressed: bool) -> void:
	if button_pressed:
		start_sampling()
	else:
		sampling = false

func start_sampling() -> void:
	await RenderingServer.frame_post_draw
	screen_image = get_viewport().get_texture().get_image()
	screen_image.resize(int(get_viewport_rect().size.x), int(get_viewport_rect().size.y))
	
	$SampleScreen.show()
	sampling = true

func end_sampling() -> void:
	sampling = false
	$SamplerContainer/Sampler.button_pressed = false
	$SampleScreen.hide()
