shader_type canvas_item;

uniform vec4 line_color : source_color;
uniform float line_thickness : hint_range(0, 10) = 1;
global uniform bool interaction_strength_showing;
uniform float start_interaction_strength_alpha : hint_range(0.0, 1.0, 0.1);
uniform float end_interaction_strength_alpha : hint_range(0.0, 1.0, 0.1);
global uniform sampler2D colour_scheme: filter_nearest;
uniform sampler2D screen_texture : hint_screen_texture;

vec4 blend_transparency(vec4 color, vec2 uv)
{
	float alpha_difference = end_interaction_strength_alpha - start_interaction_strength_alpha;
	
	return vec4(color.xyz, start_interaction_strength_alpha + alpha_difference * uv.x);
}

void fragment() {
// Get the size of the pixels on screen, and create a variable for out outline
vec2 size = SCREEN_PIXEL_SIZE * line_thickness;

float outline = texture(screen_texture, SCREEN_UV + vec2(-size.x, 0)).a;
outline += texture(screen_texture, SCREEN_UV + vec2(0, size.y)).a;
outline += texture(screen_texture, SCREEN_UV + vec2(size.x, 0)).a;
outline += texture(screen_texture, SCREEN_UV + vec2(0, -size.y)).a;
outline = min(outline, 1.0);

// Get the texture from the screen
vec4 tex = texture(screen_texture, SCREEN_UV);
vec4 modulate = COLOR - vec4(1, 1, 1, 0);
tex = mix(tex, line_color + modulate, outline - tex.a);

if (tex.a > 0.0001 && interaction_strength_showing) {
	tex = blend_transparency(tex, SCREEN_UV);
}

COLOR = vec4(texture(colour_scheme, vec2(tex.r, tex.g)).rgb, tex.a);
}