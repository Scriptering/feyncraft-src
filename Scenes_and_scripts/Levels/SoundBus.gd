extends Node

func _ready() -> void:
	await StatsManager.ready
	
	if StatsManager.stats.muted:
		mute(true)

func snip() -> void:
	$UI/Snip.play()

func button_down() -> void:
	$UI/ButtonDown.play()

func button_up() -> void:
	$UI/ButtonUp.play()

func pull_out_tab() -> void:
	$UI/PullOutTab.play()

func push_in_tab() -> void:
	$UI/PushInTab.play()

func mute(toggle: bool) -> void:
	if StatsManager.is_node_ready():
		StatsManager.stats.muted = toggle
	AudioServer.set_bus_mute(0, toggle)
