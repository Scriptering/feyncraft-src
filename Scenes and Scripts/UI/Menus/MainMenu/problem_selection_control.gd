extends GrabbableControl

signal closed

func _ready() -> void:
	super()
	
	$ProblemSelection.closed.connect(func(): closed.emit())

func reload() -> void:
	$ProblemSelection/ProblemList.reload()
	$ProblemSelection/ProblemSetList.reload()
