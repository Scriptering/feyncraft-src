extends Node
class_name Mode

enum {
	ParticleSelection,
	ProblemCreation,
	SolutionCreation,
	Sandbox,
	ProblemSolving,
	Tutorial,
	Null
}

const particle_selection_visibility : Dictionary = {
	"controls": true,
	"vision": false,
	"problem_options": false,
	"generation": false,
	"particles": true,
	"problem": false,
	"menu": true,
	"health": false,
	"export": false
}

const problem_creation_visibility : Dictionary = {
	"controls": true,
	"vision": true,
	"problem_options": false,
	"generation": false,
	"particles": true,
	"problem": false,
	"menu": true,
	"health": false,
	"export": false
}

const solution_creation_visibility : Dictionary = {
	"controls": true,
	"vision": true,
	"problem_options": false,
	"generation": false,
	"particles": true,
	"problem": true,
	"menu": true,
	"health": true,
	"export": false
}

const sandbox_visibility : Dictionary = {
	"controls": true,
	"vision": true,
	"problem_options": true,
	"generation": true,
	"particles": true,
	"problem": true,
	"menu": true,
	"health": true,
	"export": true
}

const problem_solving_visibility : Dictionary = {
	"controls": true,
	"vision": true,
	"problem_options": false,
	"generation": false,
	"particles": true,
	"problem": true,
	"menu": true,
	"health": true,
	"export": false
}

const tutorial_visibility : Dictionary = {
	"controls": true,
	"vision": false,
	"problem_options": false,
	"generation": false,
	"particles": true,
	"problem": true,
	"menu": true,
	"health": true,
	"export": false
}

const tab_visibility: Dictionary = {
	ParticleSelection: particle_selection_visibility,
	ProblemCreation: problem_creation_visibility,
	SolutionCreation: solution_creation_visibility,
	Sandbox: sandbox_visibility,
	ProblemSolving: problem_solving_visibility,
	Tutorial: tutorial_visibility
}
