extends PullOutTab

signal export_pressed(
	join_paths: bool,
	draw_internal_labels: bool,
	draw_external_labels: bool,
	as_matrix: bool
)

signal download_pressed

func _on_export_pressed() -> void:
	export_pressed.emit(
		%JoinPaths.button_pressed,
		%InternalLabels.button_pressed,
		%ExternalLabels.button_pressed,
		%ExportMatrix.button_pressed
	)

func _on_download_pressed() -> void:
	download_pressed.emit()
