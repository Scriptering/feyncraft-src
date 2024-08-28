extends Node

func _ready() -> void:
	EventBus.change_palette.connect(_on_palette_changed)

func change_shaders(palette: ImageTexture) -> void:
	RenderingServer.global_shader_parameter_set("colour_scheme", palette)

func _on_palette_changed(palette: ImageTexture) -> void:
	change_shaders(palette)

func toggle_interaction_strength(toggle: bool) -> void:
	RenderingServer.global_shader_parameter_set("interaction_strength_showing", toggle)
