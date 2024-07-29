shader_type canvas_item;

global uniform bool interaction_strength_showing;
global uniform sampler2D colour_scheme : filter_nearest;
uniform float interaction_strength_alpha : hint_range(0.0, 1.0, 0.1);

vec4 swap_color(vec4 color)
{
	return texture(colour_scheme, vec2(color.r, color.g));
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	color = vec4(swap_color(color).rgb, color.a);

	if (color.a > 0.0001 && interaction_strength_showing) {
		color = vec4(color.rgb, interaction_strength_alpha);
	}

	COLOR = color;
}
