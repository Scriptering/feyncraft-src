shader_type canvas_item;

global uniform bool interaction_strength_showing;
global uniform sampler2D colour_scheme: filter_nearest;
uniform float start_interaction_strength_alpha : hint_range(0.0, 1.0, 0.1);
uniform float end_interaction_strength_alpha : hint_range(0.0, 1.0, 0.1);
uniform vec4 line_color : source_color = vec4(1);
uniform float line_thickness : hint_range(0, 10) = 1.0;
varying vec2 clamped_UV;

void vertex()
{
	if (UV.x > 1.0 || UV.y > 1.0) {
		clamped_UV = vec2(1.0, 1.0);
	} else {
		clamped_UV = UV;
	}
}

vec4 add_outline(vec2 pixel_size, sampler2D Texture, vec2 uv)
{
	vec2 size = pixel_size * line_thickness;
	float outline = texture(Texture, uv + vec2(-size.x, 0)).a;
	outline += texture(Texture, uv + vec2(0, size.y)).a;
	outline += texture(Texture, uv + vec2(size.x, 0)).a;
	outline += texture(Texture, uv + vec2(0, -size.y)).a;
	outline += texture(Texture, uv + vec2(-size.x, size.y)).a;
	outline += texture(Texture, uv + vec2(size.x, size.y)).a;
	outline += texture(Texture, uv + vec2(-size.x, -size.y)).a;
	outline += texture(Texture, uv + vec2(size.x, -size.y)).a;
	outline = min(outline, 1.0);
	
	vec4 color = texture(Texture, uv);
	return mix(color, line_color, outline - color.a);
}

vec4 blend_transparency(vec4 color, vec2 uv)
{
	float alpha_difference = end_interaction_strength_alpha - start_interaction_strength_alpha;
	
	return vec4(color.xyz, start_interaction_strength_alpha + alpha_difference * uv.x);
}

void fragment()
{
	vec4 color = texture(TEXTURE, UV);
	
	color = add_outline(TEXTURE_PIXEL_SIZE, TEXTURE, UV);
	
	if (color.a > 0.0001 && interaction_strength_showing) {
		color = blend_transparency(color, clamped_UV);
	}
	
	COLOR = vec4(texture(colour_scheme, vec2(color.r, color.g)).rgb, color.a);
}
