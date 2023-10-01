extends GrabbableControl

signal closed

func _ready() -> void:
	super._ready()
	
	$ProblemSelection.closed.connect(func(): closed.emit())
	
