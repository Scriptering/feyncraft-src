extends Label

func _ready() -> void:
	text = "v%s"%[ProjectSettings.get_setting("application/config/version")]
