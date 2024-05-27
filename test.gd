extends Node

enum test {
	ball,
	rall,
	tall,
	mall,
	pall,
	fall,
	call
}

func _ready() -> void:
	for i:int in test.values():
		print(i)
