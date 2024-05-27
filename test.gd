extends Node

var test : Dictionary = {
	"ball":"a",
	"rall":"b",
	"tall":"c",
	"mall":"d",
	"pall":"e",
	"fall":"f",
	"call":"g"
}

func _ready() -> void:
	for i:int in test:
		print(i)
