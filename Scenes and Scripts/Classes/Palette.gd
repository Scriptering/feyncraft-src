class_name Palette
extends Node

enum ColourIndex {
	Primary, GridShadow, Grid, Shadow1, Shadow2, Secondary, Disabled, White, Active,
	Red, Green, Blue, Error, Text
}

enum Index {
	A, ab, B, bc, C, ca
}

const palette_size: int = 5

var colours: PackedColorArray = []

var title: String = ''
var is_custom: bool = true

var cas : float
var bcs : float
var brad : float
var crad : float
var contrastedB : bool = true
var contrastedC : bool = true
var indieB : bool = false
var exactSecondary : bool = false
var min_lumin: float = 0.5
var max_lumin: float = 0.65
var min_saturation: float = 0.5
var max_saturation: float = 0.7
var rand_saturation_offset: float = 0.05

func _init() -> void:
	colours.resize(ColourIndex.size())

func get_palette_index(colour: ColourIndex) -> Vector2:
	return Vector2(colour % palette_size, int(floor(colour / palette_size)))

func set_colour(colour_index: ColourIndex, colour: Color) -> void:
	colours[colour_index] = colour

func get_colour(colour_index: ColourIndex) -> Color:
	return colours[colour_index]

func generate_palette_texture() -> ImageTexture:
	var img := Image.create(palette_size, palette_size, false, Image.Format.FORMAT_RGBA8)
	img.fill(Color.BLACK)
	
	for i in range(ColourIndex.size()):
		img.set_pixelv(get_palette_index(i), colours[i])
	
	img.set_pixel(palette_size-1, palette_size-1, colours[ColourIndex.Text])
	
	return ImageTexture.create_from_image(img)

func contrast(colour: Color) -> Color:
	var r: float = fmod(colour.r + 0.5, 1.0)
	var g: float = fmod(colour.g + 0.5, 1.0)
	var b: float = fmod(colour.b + 0.5, 1.0)
	
	return Color(r, g, b, colour.a)

func get_random_colours() -> PackedColorArray:
	var random_start_colour: Color = Color(randf_range(0.0, 1.0), randf_range(0.0, 1.0), randf_range(0.0, 1.0))
	var random_saturation: float = randf_range(min_saturation, max_saturation)
	var lumin: float = random_start_colour.get_luminance()
	
	random_start_colour.s = random_saturation
	
	if lumin > max_lumin:
		random_start_colour = random_start_colour.darkened(randf_range(lumin - max_lumin, lumin - min_lumin))
	elif lumin < min_lumin:
		random_start_colour = random_start_colour.lightened(randf_range(min_lumin - lumin, max_lumin - lumin))
	
	print(random_start_colour.get_luminance())
	var new_colours: PackedColorArray = make_palette(random_start_colour)
	
	print("Random")
	for i in range(new_colours.size()):
		new_colours[i].s = random_saturation + randf_range(-rand_saturation_offset, rand_saturation_offset)
		
		print("\n Random Saturation: ", new_colours[i].s)
		print("Random Lumin: ", new_colours[i].get_luminance())
	
	return get_custom_colours(new_colours[Index.A], new_colours[Index.B], new_colours[Index.C])

func get_custom_colours(
	primary: Color = colours[ColourIndex.Primary], secondary: Color = colours[ColourIndex.Secondary],
	grid: Color = colours[ColourIndex.Grid]
) -> PackedColorArray:
	var custom_colours: PackedColorArray = colours.duplicate()
	var mixed_colours: PackedColorArray = make_palette(primary, grid, secondary)
	
	custom_colours[ColourIndex.Primary] = primary
	custom_colours[ColourIndex.Secondary] = secondary
	custom_colours[ColourIndex.White] = primary.lightened(0.3)
	custom_colours[ColourIndex.Grid] = grid
	custom_colours[ColourIndex.Shadow1] = mixed_colours[Index.ca]
	custom_colours[ColourIndex.Shadow2] = mixed_colours[Index.bc]
	custom_colours[ColourIndex.GridShadow] = mixed_colours[Index.ab]
	
	var active_colour: Color = primary
	active_colour.s += 0.4
	custom_colours[ColourIndex.Active] = active_colour
	
	custom_colours[ColourIndex.Disabled] = Color.from_hsv(primary.h, primary.s - 0.25, primary.v)
	
	return custom_colours

func make_palette(A : Color, B: Color = Color.FUCHSIA, C: Color = Color.FUCHSIA) -> PackedColorArray:
	randomizeSettings()
	
	if C == Color.FUCHSIA:
		C = getC(A)
	
	if B == Color.FUCHSIA:
		B = getB(A, C)
	
	var ab = get_secondary(A, B)
	var bc = get_secondary(B, C)
	var ca = get_secondary(C, A)
	
	return PackedColorArray([A, ab, B, bc, C, ca])

func getC(A) -> Color:
	
	var ch = fposmod(A.h + crad, 1.0)
	var cs = A.s * cas
	var cv = A.v
	
	if contrastedC:
		return contrast(Color.from_hsv(ch, cs, cv))

	return Color.from_hsv(ch, cs, cv)

func getB(A : Color, C : Color):
	var bh
	var bs
	var bv
	if indieB:
		bh = fposmod(A.h + brad, 1.0)
		bs = A.s * bcs
		bv = A.v# + (A.v - cv) / 2
	else:
		bh = lerp(A.h, C.h, brad) if C.h > A.h else lerp(A.h, 1.0 + C.h, brad)
		bs = C.s * bcs
		bv = A.v + (A.v - C.v) / 2
	
	if contrastedB:
		return contrast(Color.from_hsv(bh, bs, bv))
	return Color.from_hsv(bh, bs, bv)

func get_secondary(c1: Color, c2 : Color):
	if exactSecondary:
		var c1r = Vector2(c1.s, 0).rotated(c1.h * TAU)
		var c2r = Vector2(c2.s, 0).rotated(c2.h * TAU)
		var secV = c1r + c1r.direction_to(c2r) * c1r.distance_to(c2r)/2
		
		var sec = Color.from_hsv(secV.angle() / TAU, secV.length(), lerp(c1.v, c2.v, 0.5))
		
		return sec
		
	else:
		return lerp(c1, c2, 0.5)

func randomizeSettings():
	cas = randf_range(0.8, 1.0)
	bcs = randf_range(0.8, 1.0)
	brad = randf_range(0.4, 0.8)
	crad = randf_range(0.4, 0.8)
