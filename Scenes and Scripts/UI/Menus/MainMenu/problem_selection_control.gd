extends GrabbableControl

signal closed

func _ready() -> void:
	super()
	
	$ProblemSelection.closed.connect(func(): closed.emit())

func reload() -> void:
	$ProblemSelection/ProblemSetList.load_problem_sets()
	$ProblemSelection/ProblemList.reload()
