@tool
extends GrabbableControl
class_name Decoration

enum Decor {
	none, blob, crossed_dot, dot
}

@export var texture: Texture2D : set = _set_texture
@export var decor: Decor = Decor.none

var follow_crosshair : bool = false
var crosshair_pos: Vector2i = Vector2.ZERO

func _ready() -> void:
	super._ready()
	
	EventBus.crosshair_area_mouse_entered.connect(_crosshair_area_mouse_entered)
	EventBus.crosshair_area_mouse_exited.connect(_crosshair_area_mouse_entered)
	EventBus.crosshair_area_finger_entered.connect(_crosshair_area_finger_entered)
	EventBus.crosshair_area_finger_exited.connect(_crosshair_area_finger_exited)
	EventBus.crosshair_moved.connect(_crosshair_moved)
	texture = texture

func _set_texture(new_texture: Texture2D) -> void:
	texture = new_texture
	custom_minimum_size = texture.get_size()
	
	if is_inside_tree() || Engine.is_editor_hint():
		$TextureRect.texture = texture

func _crosshair_moved(new_position: Vector2i, _old_position: Vector2i) -> void:
	if !grabbed:
		return
	
	crosshair_pos = new_position
	
	if follow_crosshair:
		set_global_position(Vector2(crosshair_pos) - $TextureRect.size / 2)

func start_follow_crosshair() -> void:
	set_global_position(Vector2(crosshair_pos) - $TextureRect.size / 2)
	follow_cursor = false
	follow_crosshair = true

func end_follow_crosshair() -> void:
	follow_cursor = true
	follow_crosshair = false

func _crosshair_area_mouse_entered() -> void:
	if grabbed:
		start_follow_crosshair()

func _crosshair_area_mouse_exited() -> void:
	if grabbed:
		end_follow_crosshair()

func _crosshair_area_finger_entered(index:int) -> void:
	if grabbed:
		start_follow_crosshair()

func _crosshair_area_finger_exited(index:int) -> void:
	if grabbed:
		end_follow_crosshair()

func pick_up() -> void:
	super.pick_up()
	
	$TextureRect.mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE

func drop() -> void:
	super.drop()
	
	$TextureRect.mouse_filter = MouseFilter.MOUSE_FILTER_PASS
	
	position = start_position
	follow_cursor = true
	follow_crosshair = false

static func get_decor_name(dec: Decoration.Decor) -> String:
	match dec:
		Decor.none:
			return "normal"
		Decor.dot:
			return "dot"
		Decor.crossed_dot:
			return "crossed_dot"
		Decor.blob:
			return "blob"
	
	return ""

static func get_export_name(dec: Decoration.Decor) -> String:
	match dec:
		Decor.none:
			return "normal"
		Decor.dot:
			return "dot"
		Decor.crossed_dot:
			return "crossed dot"
		Decor.blob:
			return "blob"
	
	return ""
	
	
