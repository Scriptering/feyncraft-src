shader_type canvas_item;

global uniform sampler2D colour_scheme: filter_nearest;
uniform float alpha: hint_range(0.0, 1.0);

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	COLOR = vec4(texture(colour_scheme, vec2(color.r, color.g)).rgb, color.a * alpha);
}
