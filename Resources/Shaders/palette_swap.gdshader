shader_type canvas_item;

global uniform sampler2D colour_scheme: filter_nearest;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	COLOR = vec4(texture(colour_scheme, vec2(color.r, color.g)).rgb, color.a);
}
