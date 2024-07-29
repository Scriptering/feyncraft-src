shader_type canvas_item;

global uniform sampler2D colour_scheme: filter_nearest;
uniform vec4 line_color : source_color = vec4(1);
uniform float line_thickness : hint_range(0, 10) = 1.0;

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

void fragment()
{
	vec4 color = texture(TEXTURE, UV);
	color = add_outline(TEXTURE_PIXEL_SIZE, TEXTURE, UV);

	COLOR = vec4(texture(colour_scheme, vec2(color.r, color.g)).rgb, color.a);
}

