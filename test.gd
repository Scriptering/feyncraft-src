extends Node

func _ready() -> void:
	var arr: Array = [1, 2, 3, 4, 5, 6]
	
	print(arr.reduce(
		func(acc:int, i:int) -> int:
			return acc + int(i % 2 == 0)
	))
	
	print(ArrayFuncs.count_var(
		arr,
		func(i:int) -> bool:
			return i % 2 == 0
	))
