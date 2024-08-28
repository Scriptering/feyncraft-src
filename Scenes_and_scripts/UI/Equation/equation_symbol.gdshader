shader_type canvas_item;

uniform vec4 line_color : source_color;
uniform float line_thickness : hint_range(0, 10) = 1;
global uniform sampler2D colour_scheme: filter_nearest;

void fragment() {
// Get the size of the pixels on screen, and create a variable for out outline
vec2 size = SCREEN_PIXEL_SIZE * line_thickness;

float outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
outline = min(outline, 1.0);

// Get the texture from the screen
vec4 tex = texture(TEXTURE, UV);
vec4 modulate = COLOR - vec4(1, 1, 1, 0);
tex = mix(tex, line_color + modulate, outline - tex.a);


COLOR = vec4(texture(colour_scheme, vec2(tex.r, tex.g)).rgb, tex.a);
}