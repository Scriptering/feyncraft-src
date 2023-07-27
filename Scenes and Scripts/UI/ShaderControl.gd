extends Node

func init(palette_buttons: Node) -> void:
	palette_buttons.connect("palette_changed", Callable(self, "change_shaders"))

func change_shaders(palette: CompressedTexture2D):
	RenderingServer.global_shader_parameter_set("colour_scheme", palette)


