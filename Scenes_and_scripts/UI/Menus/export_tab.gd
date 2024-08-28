extends PullOutTab

signal export_pressed(
	join_paths: bool,
	draw_internal_labels: bool,
	draw_external_labels: bool
)

func _on_export_pressed() -> void:
	export_pressed.emit(
		$MovingContainer/ContentContainer/VBoxContainer/JoinPaths.button_pressed,
		$MovingContainer/ContentContainer/VBoxContainer/InternalLabels.button_pressed,
		$MovingContainer/ContentContainer/VBoxContainer/ExternalLabels.button_pressed
	)
