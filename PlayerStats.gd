extends Resource
class_name PlayerStats

@export var daily_streak: int = 0:
	set(new_value) :
		daily_streak = new_value
		emit_changed()
@export var palette: Palette = null:
	set(new_value) :
		palette = new_value
		emit_changed()
@export var last_daily_completed_date: Dictionary:
	set(new_value) :
		last_daily_completed_date = new_value
		emit_changed()
@export var muted: bool = false:
	set(new_value) :
		muted = new_value
		emit_changed()
@export var hide_labels: bool = false:
	set(new_value) :
		hide_labels = new_value
		emit_changed()
