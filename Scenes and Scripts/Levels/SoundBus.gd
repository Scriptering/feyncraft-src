extends Node

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
