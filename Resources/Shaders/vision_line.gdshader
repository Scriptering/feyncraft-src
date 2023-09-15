shader_type canvas_item;

global uniform sampler2D colour_scheme: filter_nearest;
uniform vec4 line_color : source_color = vec4(1);
uniform vec4 outline_color : source_color = vec4(1);
uniform float line_thickness : hint_range(0, 10) = 1.0;
varying vec2 clamped_UV;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;


void vertex()
{
	if (UV.x > 1.0 || UV.y > 1.0) {
		clamped_UV = vec2(1.0, 1.0);
	} else {
		clamped_UV = UV;
	}
}

vec4 add_outline(vec4 color, vec2 pixel_size, sampler2D Texture, vec2 uv)
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
	
	vec4 palette_outline_color = vec4(texture(colour_scheme, vec2(outline_color.r, outline_color.g)).rgb, outline_color.a);
	
	return mix(color, palette_outline_color, outline - color.a);
}


void fragment()
{
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	color = vec4(line_color.rgb, texture(TEXTURE, UV).a);
	color = add_outline(color, TEXTURE_PIXEL_SIZE, TEXTURE, UV);

	COLOR = color;
}
