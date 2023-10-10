extends Node

enum ColourScheme {TeaStain, SeaFoam, Professional}
enum COLOURS {primary, secondary, pencil, primary_highlight, invalid, invalid_highlight}

enum Vision {Colour, Shade, Strength, None}

var in_main_menu: bool = true
var load_mode: BaseMode.Mode = BaseMode.Mode.Sandbox
var creating_problem: Problem = Problem.new()
var creating_problem_set_file: String = ''
var load_problem_set: ProblemSet = ProblemSet.new()
var problem_selection_menu_position: Vector2
var problem_selection_menu_showing: bool

#0 photon, 1 gluon, 2 Z, 3 H, 4 W,
#5 lepton, 6 electron, 7 muon, 8 tau,
#9 lepton_neutrino, 10 electron_neutrino, 11 muon_neutrino, 12 tau_neutrino,
#13 bright_quark, 14 up, 15 charm, 16 top, 17 dark_quark, 18 down, 19 strange, 20 bottom,

enum Particle {
	photon, gluon, Z, H, W,
	lepton, electron, muon, tau,
	lepton_neutrino, electron_neutrino, muon_neutrino, tau_neutrino,
	bright_quark, up, charm, top, dark_quark, down, strange, bottom,
	anti_bottom = -20, anti_strange, anti_down, anti_dark_quark, anti_top, anti_charm, anti_up, anti_bright_quark,
	anti_tau_neutrino, anti_muon_neutrino, anti_electron_neutrino, anti_lepton_neutrino,
	anti_tau, anti_muon, anti_electron, anti_lepton,
	anti_W,
	none = 100}

enum Hadrons {Proton, AntiProton, Neutron, AntiNeutron, DeltaPlusPlus, DeltaPlus, Delta0, DeltaMinus,
AntiDeltaPlusPlus, AntiDeltaPlus, AntiDelta0, AntiDeltaMinus, Epsilon0, EpsilonMinus, AntiEpsilon0, AntiEpsilonMinus,
Lambda0, AntiLambda0, SigmaPlus, SigmaMinus, AntiSigmaPlus, AntiSigmaMinus, OmegaMinus, AntiOmegaMinus,
DPlus, D0, AntiD0, DMinus, BPlus, B0, AntiB0, BMinus, JPsi, PionMinus, PionPlus, Pion0, KaonPlus, KaonMinus, Kaon0, Invalid}

enum QuantumNumber {charge, lepton, electron, muon, tau, quark, up, down, charm, strange, top, bottom, bright, dark}

enum INTERACTION_TYPE {electromagnetic, strong, weak, electroweak}

enum STATE_LINE {INITIAL, FINAL}

enum CURSOR {default, point, hold, snip, snipped, middle, hover, press, disabled, sampler}

const REPLACEMENT_SHADER := preload('res://Resources/Shaders/replacement_material.tres')

const MISSING_COLOUR := Color('ff1bea')

const COLOUR_SCHEMES : Array = [
	[Color('e1cba0'), Color('d1bd97'), Color('383930'), Color('e3d3c0'), Color('df3e3e'), Color('e35959')],
	[Color('FFFFFF'), Color('FFFFFF'), Color('000000'), Color('e3d3c0'), Color('df3e3e'), Color('e35959')]]


const VISION_COLOURS : Array = [
	[Color('c13e3e'), Color('3ec13e'), Color('4057be')],
	[Color('ffffff'), Color('000000'), Color('727272')]
]

const QUANTUM_NUMBERS : Array[Array] = [
[0.0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
[0.0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
[0.0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
[0.0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
[-1.0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1],
[-1.0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
[-1.0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], 
[-1.0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
[-1.0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
[0.0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
[0.0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
[0.0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
[0.0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0],
[2.0/3, 0, 0, 0, 0, 1.0/3, 0, 0, 0, 0, 0, 0, 1, 0],
[2.0/3, 0, 0, 0, 0, 1.0/3, 1, 0, 0, 0, 0, 0, 1, 0],
[2.0/3, 0, 0, 0, 0, 1.0/3, 0, 0, 1, 0, 0, 0, 1, 0],
[2.0/3, 0, 0, 0, 0, 1.0/3, 0, 0, 0, 0, 1, 0, 1, 0],
[-1.0/3, 0, 0, 0, 0, 1.0/3, 0, 0, 0, 0, 0, 0, 0, 1],
[-1.0/3, 0, 0, 0, 0, 1.0/3, 0, 1, 0, 0, 0, 0, 0, 1],
[-1.0/3, 0, 0, 0, 0, 1.0/3, 0, 0, 0, 1, 0, 0, 0, 1],
[-1.0/3, 0, 0, 0, 0, 1.0/3, 0, 0, 0, 0, 0, 1, 0, 1]
]

const WEAK_QUANTUM_NUMBERS : Array[QuantumNumber] = [
	QuantumNumber.up, QuantumNumber.down, QuantumNumber.charm, QuantumNumber.strange, QuantumNumber.top, QuantumNumber.bottom
]

const FERMION_DIMENSIONALITY : float = 1.5
const BOSON_DIMENSIONALITY : float = 1.0

const LEPTONS : Array[GLOBALS.Particle] = [
	Particle.lepton, Particle.electron, Particle.muon, Particle.tau,
	Particle.lepton_neutrino, Particle.electron_neutrino, Particle.muon_neutrino, Particle.tau_neutrino
]

const QUARKS : Array[GLOBALS.Particle] = [
	Particle.bright_quark, Particle.dark_quark, Particle.up, Particle.down, Particle.charm, Particle.strange, Particle.top, Particle.bottom
]

const FERMIONS := LEPTONS + QUARKS

const BOSONS : Array[GLOBALS.Particle] = [Particle.photon, Particle.gluon, Particle.H, Particle.W, Particle.Z]

const COLOUR_PARTICLES : Array[GLOBALS.Particle] = [
	Particle.gluon,
	Particle.bright_quark, Particle.dark_quark, Particle.up, Particle.down, Particle.charm, Particle.strange, Particle.top, Particle.bottom
]

const SHADED_PARTICLES : Array[GLOBALS.Particle] = [
	Particle.W,
	Particle.lepton, Particle.electron, Particle.muon, Particle.tau,
	Particle.lepton_neutrino, Particle.electron_neutrino, Particle.muon_neutrino, Particle.tau_neutrino,
	Particle.bright_quark, Particle.dark_quark, Particle.up, Particle.down, Particle.top, Particle.bottom, Particle.charm, Particle.strange
]

const BRIGHT_PARTICLES : Array[GLOBALS.Particle] = [
	Particle.W,
	Particle.bright_quark, Particle.up, Particle.charm, Particle.top,
	Particle.lepton_neutrino, Particle.electron_neutrino, Particle.muon_neutrino, Particle.tau_neutrino
]

const DARK_PARTICLES : Array[GLOBALS.Particle] = [
	Particle.W,
	Particle.dark_quark, Particle.down, Particle.strange, Particle.bottom,
	Particle.lepton, Particle.electron, Particle.muon, Particle.tau
]

const SHADE_PARTICLES : Array = [
	BRIGHT_PARTICLES,
	DARK_PARTICLES,
	SHADED_PARTICLES
]

const GENERAL_PARTICLES : Array[GLOBALS.Particle] = [
	Particle.lepton, Particle.lepton_neutrino, Particle.bright_quark, Particle.dark_quark
]

const INVALID = -1

var MAXIMUM_INTERACTION_STRENGTH : float
var MINIMUM_INTERACTION_STRENGTH : float

const MINIMUM_INTERACTION_STRENGTH_ALPHA : float = 0.05

const GENERAL_CONVERSION : Dictionary = {
	Particle.photon: Particle.photon, Particle.H: Particle.H, Particle.W: Particle.W, Particle.Z: Particle.Z, Particle.gluon: Particle.gluon,
	Particle.lepton: [Particle.electron, Particle.muon, Particle.tau],
	Particle.lepton_neutrino: [Particle.electron_neutrino, Particle.muon_neutrino, Particle.tau_neutrino],
	Particle.bright_quark: [Particle.up, Particle.charm, Particle.top],
	Particle.dark_quark: [Particle.down, Particle.strange, Particle.bottom],
	Particle.electron: Particle.lepton,
	Particle.muon: Particle.lepton,
	Particle.tau: Particle.lepton,
	Particle.electron_neutrino: Particle.lepton_neutrino,
	Particle.muon_neutrino: Particle.lepton_neutrino,
	Particle.tau_neutrino: Particle.lepton_neutrino,
	Particle.up: Particle.bright_quark,
	Particle.charm: Particle.bright_quark,
	Particle.top: Particle.bright_quark,
	Particle.down: Particle.dark_quark,
	Particle.strange: Particle.dark_quark,
	Particle.bottom: Particle.dark_quark
}

var GENERAL_INTERACTIONS : Array = [
	[
		[Particle.lepton, Particle.lepton, Particle.photon],
		[Particle.bright_quark, Particle.bright_quark, Particle.photon],
		[Particle.dark_quark, Particle.dark_quark, Particle.photon]
	],
	[
		[Particle.bright_quark, Particle.bright_quark, Particle.gluon],
		[Particle.dark_quark, Particle.dark_quark, Particle.gluon]
	],
	[
		[Particle.lepton, Particle.lepton_neutrino, Particle.W],
		[Particle.bright_quark, Particle.dark_quark, Particle.W],
		[Particle.W, Particle.W, Particle.W, Particle.W]
	],
	[
		[Particle.lepton, Particle.lepton, Particle.Z],
		[Particle.bright_quark, Particle.bright_quark, Particle.Z],
		[Particle.dark_quark, Particle.dark_quark, Particle.Z],
		[Particle.lepton_neutrino, Particle.lepton_neutrino, Particle.Z],
		[Particle.W, Particle.W, Particle.Z],
		[Particle.W, Particle.W, Particle.photon],
		[Particle.W, Particle.W, Particle.Z, Particle.Z],
		[Particle.W, Particle.W, Particle.photon, Particle.photon],
		[Particle.W, Particle.W, Particle.Z, Particle.photon],
		[Particle.lepton, Particle.lepton, Particle.H],
		[Particle.bright_quark, Particle.bright_quark, Particle.H],
		[Particle.dark_quark, Particle.dark_quark, Particle.H],
		[Particle.lepton_neutrino, Particle.lepton_neutrino, Particle.H],
		[Particle.H, Particle.Z, Particle.Z],
		[Particle.H, Particle.H, Particle.H, Particle.H],
		[Particle.H, Particle.H, Particle.Z, Particle.Z],
		[Particle.H, Particle.H, Particle.W, Particle.W]
	]
]

var INTERACTIONS : Array = [
	[
		[Particle.up, Particle.up, Particle.photon],
		[Particle.down, Particle.down, Particle.photon],
		[Particle.charm, Particle.charm, Particle.photon],
		[Particle.strange, Particle.strange, Particle.photon],
		[Particle.top, Particle.top, Particle.photon],
		[Particle.bottom, Particle.bottom, Particle.photon],
		[Particle.electron, Particle.electron, Particle.photon],
		[Particle.muon, Particle.muon, Particle.photon],
		[Particle.tau, Particle.tau, Particle.photon],
	],
	[
		[Particle.up, Particle.up, Particle.gluon],
		[Particle.down, Particle.down, Particle.gluon],
		[Particle.charm, Particle.charm, Particle.gluon],
		[Particle.strange, Particle.strange, Particle.gluon],
		[Particle.top, Particle.top, Particle.gluon],
		[Particle.bottom, Particle.bottom, Particle.gluon],
		[Particle.gluon, Particle.gluon, Particle.gluon],
		[Particle.gluon, Particle.gluon, Particle.gluon, Particle.gluon]
	],
	[
		[Particle.electron, Particle.electron_neutrino, Particle.W],
		[Particle.muon, Particle.muon_neutrino, Particle.W],
		[Particle.tau, Particle.tau_neutrino, Particle.W],
		[Particle.up, Particle.down, Particle.W],
		[Particle.up, Particle.strange, Particle.W],
		[Particle.up, Particle.bottom, Particle.W],
		[Particle.charm, Particle.down, Particle.W],
		[Particle.charm, Particle.strange, Particle.W],
		[Particle.charm, Particle.bottom, Particle.W],
		[Particle.top, Particle.down, Particle.W],
		[Particle.top, Particle.strange, Particle.W],
		[Particle.top, Particle.bottom, Particle.W],
	],
	[
		[Particle.up, Particle.up, Particle.Z],
		[Particle.down, Particle.down, Particle.Z],
		[Particle.charm, Particle.charm, Particle.Z],
		[Particle.strange, Particle.strange, Particle.Z],
		[Particle.top, Particle.top, Particle.Z],
		[Particle.bottom, Particle.bottom, Particle.Z],
		[Particle.electron, Particle.electron, Particle.Z],
		[Particle.muon, Particle.muon, Particle.Z],
		[Particle.tau, Particle.tau, Particle.Z],
		[Particle.electron_neutrino, Particle.electron_neutrino, Particle.Z],
		[Particle.muon_neutrino, Particle.muon_neutrino, Particle.Z],
		[Particle.tau_neutrino, Particle.tau_neutrino, Particle.Z],
		[Particle.W, Particle.W, Particle.Z],
		[Particle.W, Particle.W, Particle.photon],
		[Particle.W, Particle.W, Particle.W, Particle.W],
		[Particle.W, Particle.W, Particle.Z, Particle.Z],
		[Particle.W, Particle.W, Particle.photon, Particle.photon],
		[Particle.W, Particle.W, Particle.Z, Particle.photon],
		[Particle.up, Particle.up, Particle.H],
		[Particle.down, Particle.down, Particle.H],
		[Particle.charm, Particle.charm, Particle.H],
		[Particle.strange, Particle.strange, Particle.H],
		[Particle.top, Particle.top, Particle.H],
		[Particle.bottom, Particle.bottom, Particle.H],
		[Particle.electron, Particle.electron, Particle.H],
		[Particle.muon, Particle.muon, Particle.H],
		[Particle.tau, Particle.tau, Particle.H],
		[Particle.electron_neutrino, Particle.electron_neutrino, Particle.H],
		[Particle.muon_neutrino, Particle.muon_neutrino, Particle.H],
		[Particle.tau_neutrino, Particle.tau_neutrino, Particle.H],
		[Particle.H, Particle.Z, Particle.Z],
		[Particle.H, Particle.H, Particle.H, Particle.H],
		[Particle.H, Particle.H, Particle.Z, Particle.Z],
		[Particle.H, Particle.H, Particle.W, Particle.W]
	]
]

const ALPHA_EM := 1.0/137.0
const ALPHA_S := 0.1181
const ALPHA_W := 1.0/30.0
enum CKM {UP, CHARM, TOP, DOWN=0, STRANGE=1, BOTTOM=2}
const CKM_MATRIX := [
	[0.97370, 0.2245, 0.00382],
	[0.221, 0.987, 0.041],
	[0.008, 0.0388, 1.013]
]

var PARTICLE_MASSES: Dictionary = {
	Particle.W: 80.36e3,
	Particle.Z: 91.19e3,
	Particle.H: 125e3,
	Particle.gluon: 0.0,
	Particle.photon: 0.0,
	Particle.lepton: 0.551,
	Particle.lepton_neutrino: 0.001,
	Particle.bright_quark: 2.2,
	Particle.dark_quark: 4.7,
	Particle.electron: 0.551,
	Particle.muon: 105.66,
	Particle.tau: 1.7768e3,
	Particle.electron_neutrino: 0.001,
	Particle.muon_neutrino: 0.001,
	Particle.tau_neutrino: 0.001,
	Particle.up: 2.2, 
	Particle.charm: 1.28e3,
	Particle.top: 173.1e3,
	Particle.down: 4.7,
	Particle.strange: 96,
	Particle.bottom: 4.18e3
}

var INTERACTION_STRENGTHS: Array = [
	[
		[abs(QUANTUM_NUMBERS[Particle.up][QuantumNumber.charge]*ALPHA_EM)],
		[abs(QUANTUM_NUMBERS[Particle.down][QuantumNumber.charge]*ALPHA_EM)],
		[abs(QUANTUM_NUMBERS[Particle.charm][QuantumNumber.charge]*ALPHA_EM)],
		[abs(QUANTUM_NUMBERS[Particle.strange][QuantumNumber.charge]*ALPHA_EM)],
		[abs(QUANTUM_NUMBERS[Particle.top][QuantumNumber.charge]*ALPHA_EM)],
		[abs(QUANTUM_NUMBERS[Particle.bottom][QuantumNumber.charge]*ALPHA_EM)],
		[abs(QUANTUM_NUMBERS[Particle.electron][QuantumNumber.charge]*ALPHA_EM)],
		[abs(QUANTUM_NUMBERS[Particle.muon][QuantumNumber.charge]*ALPHA_EM)],
		[abs(QUANTUM_NUMBERS[Particle.tau][QuantumNumber.charge]*ALPHA_EM)]
	],
	[
		[ALPHA_S],
		[ALPHA_S],
		[ALPHA_S],
		[ALPHA_S],
		[ALPHA_S],
		[ALPHA_S],
		[ALPHA_S],
		[ALPHA_S**2],
	],
	[
		[ALPHA_W],
		[ALPHA_W],
		[ALPHA_W],
		[ALPHA_W*CKM_MATRIX[CKM.UP][CKM.DOWN]],
		[ALPHA_W*CKM_MATRIX[CKM.UP][CKM.STRANGE]],
		[ALPHA_W*CKM_MATRIX[CKM.UP][CKM.BOTTOM]],
		[ALPHA_W*CKM_MATRIX[CKM.CHARM][CKM.DOWN]],
		[ALPHA_W*CKM_MATRIX[CKM.CHARM][CKM.STRANGE]],
		[ALPHA_W*CKM_MATRIX[CKM.CHARM][CKM.BOTTOM]],
		[ALPHA_W*CKM_MATRIX[CKM.TOP][CKM.DOWN]],
		[ALPHA_W*CKM_MATRIX[CKM.TOP][CKM.STRANGE]],
		[ALPHA_W*CKM_MATRIX[CKM.TOP][CKM.BOTTOM]],
	],
	[
		[ALPHA_W],
		[ALPHA_W],
		[ALPHA_W],
		[ALPHA_W],
		[ALPHA_W],
		[ALPHA_W],
		[ALPHA_W],
		[ALPHA_W],
		[ALPHA_W],
		[ALPHA_W],
		[ALPHA_W],
		[ALPHA_W],
		[ALPHA_W],
		[ALPHA_W],
		[ALPHA_W*ALPHA_W],
		[ALPHA_W*ALPHA_W],
		[ALPHA_W*ALPHA_W],
		[ALPHA_W*ALPHA_W],
		[ALPHA_W*PARTICLE_MASSES[Particle.up]/PARTICLE_MASSES[Particle.H]],
		[ALPHA_W*PARTICLE_MASSES[Particle.down]/PARTICLE_MASSES[Particle.H]],
		[ALPHA_W*PARTICLE_MASSES[Particle.charm]/PARTICLE_MASSES[Particle.H]],
		[ALPHA_W*PARTICLE_MASSES[Particle.strange]/PARTICLE_MASSES[Particle.H]],
		[ALPHA_W*PARTICLE_MASSES[Particle.top]/PARTICLE_MASSES[Particle.H]],
		[ALPHA_W*PARTICLE_MASSES[Particle.bottom]/PARTICLE_MASSES[Particle.H]],
		[ALPHA_W*PARTICLE_MASSES[Particle.electron]/PARTICLE_MASSES[Particle.H]],
		[ALPHA_W*PARTICLE_MASSES[Particle.muon]/PARTICLE_MASSES[Particle.H]],
		[ALPHA_W*PARTICLE_MASSES[Particle.tau]/PARTICLE_MASSES[Particle.H]],
		[ALPHA_W*PARTICLE_MASSES[Particle.electron_neutrino]/PARTICLE_MASSES[Particle.H]],
		[ALPHA_W*PARTICLE_MASSES[Particle.muon_neutrino]/PARTICLE_MASSES[Particle.H]],
		[ALPHA_W*PARTICLE_MASSES[Particle.tau_neutrino]/PARTICLE_MASSES[Particle.H]],
		[ALPHA_W*PARTICLE_MASSES[Particle.Z]/PARTICLE_MASSES[Particle.H]],
		[(ALPHA_W * PARTICLE_MASSES[Particle.Z]/PARTICLE_MASSES[Particle.H])**2],
		[(ALPHA_W * PARTICLE_MASSES[Particle.W]/PARTICLE_MASSES[Particle.H])**2],
		[ALPHA_W**2]
	]
]

const BARYONS : Array[Hadrons] = [
	Hadrons.Proton, Hadrons.AntiProton, Hadrons.Neutron, Hadrons.AntiNeutron, Hadrons.DeltaPlusPlus, Hadrons.DeltaPlus, Hadrons.Delta0,
	Hadrons.DeltaMinus, Hadrons.AntiDeltaPlusPlus, Hadrons.AntiDeltaPlus, Hadrons.AntiDelta0, Hadrons.AntiDeltaMinus, Hadrons.Epsilon0,
	Hadrons.EpsilonMinus, Hadrons.AntiEpsilon0, Hadrons.AntiEpsilonMinus, Hadrons.Lambda0, Hadrons.AntiLambda0, Hadrons.SigmaPlus,
	Hadrons.SigmaMinus, Hadrons.AntiSigmaPlus, Hadrons.AntiSigmaMinus, Hadrons.OmegaMinus, Hadrons.AntiOmegaMinus
]

const MESONS : Array[Hadrons] = [
	Hadrons.DPlus, Hadrons.D0, Hadrons.AntiD0, Hadrons.DMinus, Hadrons.BPlus, Hadrons.B0, Hadrons.AntiB0, Hadrons.BMinus, Hadrons.JPsi,
	Hadrons.PionMinus, Hadrons.PionPlus, Hadrons.Pion0, Hadrons.KaonPlus, Hadrons.KaonMinus, Hadrons.Kaon0
]
 
var HADRON_QUARK_CONTENT : Dictionary = {
	Hadrons.Proton:[[Particle.down, Particle.up, Particle.up]],
	Hadrons.AntiProton:[[Particle.anti_down, Particle.anti_up, Particle.anti_up]],
	Hadrons.Neutron:[[Particle.down, Particle.down, Particle.up]],
	Hadrons.AntiNeutron:[[Particle.anti_down, Particle.anti_down, Particle.anti_up]],
	Hadrons.DeltaPlusPlus:[[Particle.up, Particle.up, Particle.up]],
	Hadrons.DeltaPlus:[[Particle.down, Particle.up, Particle.up]],
	Hadrons.Delta0:[[Particle.down,Particle.down,Particle.up]],
	Hadrons.DeltaMinus:[[Particle.down,Particle.down,Particle.down]],
	Hadrons.AntiDeltaPlusPlus:[[Particle.anti_up, Particle.anti_up, Particle.anti_up]],
	Hadrons.AntiDeltaPlus:[[Particle.anti_down, Particle.anti_up, Particle.anti_up]],
	Hadrons.AntiDelta0:[[Particle.anti_down,Particle.anti_down,Particle.anti_up]],
	Hadrons.AntiDeltaMinus:[[Particle.anti_down,Particle.anti_down,Particle.anti_down]],
	Hadrons.Epsilon0:[[Particle.strange, Particle.strange, Particle.up]],
	Hadrons.EpsilonMinus:[[Particle.down, Particle.strange, Particle.strange]],
	Hadrons.AntiEpsilon0:[[Particle.anti_strange, Particle.anti_strange, Particle.anti_up]],
	Hadrons.AntiEpsilonMinus:[[Particle.anti_down, Particle.anti_strange, Particle.anti_strange]],
	Hadrons.Lambda0:[[Particle.down, Particle.strange, Particle.up]],
	Hadrons.AntiLambda0:[[Particle.anti_down, Particle.anti_strange, Particle.anti_up]],
	Hadrons.SigmaPlus:[[Particle.strange, Particle.up, Particle.up]],
	Hadrons.SigmaMinus:[[Particle.down, Particle.down, Particle.strange]],
	Hadrons.AntiSigmaPlus:[[Particle.anti_strange, Particle.anti_up, Particle.anti_up]],
	Hadrons.AntiSigmaMinus:[[Particle.anti_down, Particle.anti_down, Particle.anti_strange]],
	Hadrons.OmegaMinus:[[Particle.strange,Particle.strange,Particle.strange]],
	Hadrons.AntiOmegaMinus:[[Particle.anti_strange,Particle.anti_strange,Particle.anti_strange]],
	Hadrons.DPlus:[[Particle.charm, Particle.anti_down]],
	Hadrons.D0:[[Particle.anti_charm, Particle.up]],
	Hadrons.AntiD0:[[Particle.charm, Particle.anti_up]],
	Hadrons.DMinus:[[Particle.anti_charm, Particle.down]],
	Hadrons.BPlus:[[Particle.anti_bottom, Particle.up]],
	Hadrons.B0:[[Particle.anti_bottom, Particle.down]],
	Hadrons.AntiB0:[[Particle.bottom, Particle.anti_down]],
	Hadrons.BMinus:[[Particle.bottom, Particle.anti_up]],
	Hadrons.JPsi:[[Particle.charm, Particle.anti_charm]],
	Hadrons.PionMinus:[[Particle.down, Particle.anti_up]],
	Hadrons.PionPlus:[[Particle.anti_down, Particle.up]],
	Hadrons.Pion0:[[Particle.down,Particle.anti_down], [Particle.up, Particle.anti_up]],
	Hadrons.KaonPlus:[[Particle.anti_strange, Particle.up]],
	Hadrons.KaonMinus:[[Particle.strange, Particle.anti_up]],
	Hadrons.Kaon0:[[Particle.down, Particle.anti_strange], [Particle.anti_down, Particle.strange]],
	Hadrons.Invalid:[]
}

const HADRON_NAMES : Dictionary = {
	Hadrons.Proton:"proton",
	Hadrons.AntiProton:"proton_anti",
	Hadrons.Neutron:"neutron",
	Hadrons.AntiNeutron:"neutron_anti",
	Hadrons.DeltaPlusPlus:"delta_plus_plus",
	Hadrons.DeltaPlus:"delta_plus",
	Hadrons.Delta0:"delta_0",
	Hadrons.DeltaMinus:"delta_minus",
	Hadrons.AntiDeltaPlusPlus:"delta_plus_plus_anti",
	Hadrons.AntiDeltaPlus:"delta_plus_anti",
	Hadrons.AntiDelta0:"delta_0_anti",
	Hadrons.AntiDeltaMinus:"delta_minus_anti",
	Hadrons.Epsilon0:"epsilon_0",
	Hadrons.EpsilonMinus:"epsilon_minus",
	Hadrons.AntiEpsilon0:"epsilon_0_anti",
	Hadrons.AntiEpsilonMinus:"epsilon_minus_anti",
	Hadrons.Lambda0:"lambda_0",
	Hadrons.AntiLambda0:"lambda_0_anti",
	Hadrons.SigmaPlus:"sigma_plus",
	Hadrons.SigmaMinus:"sigma_minus",
	Hadrons.AntiSigmaPlus:"sigma_plus_anti",
	Hadrons.AntiSigmaMinus:"sigma_minus_anti",
	Hadrons.OmegaMinus:"omega_minus",
	Hadrons.AntiOmegaMinus:"omega_minus_anti",
	Hadrons.DPlus:"D_plus",
	Hadrons.D0:"D_0",
	Hadrons.AntiD0:"D_0_anti",
	Hadrons.DMinus:"D_minus",
	Hadrons.BPlus:"B_plus",
	Hadrons.B0:"B_0",
	Hadrons.AntiB0:"B_0_anti",
	Hadrons.BMinus:"B_minus",
	Hadrons.JPsi:"J_psi",
	Hadrons.PionMinus:"pion_minus",
	Hadrons.PionPlus:"pion_plus",
	Hadrons.Pion0:"pion_0",
	Hadrons.KaonPlus:"kaon_plus",
	Hadrons.KaonMinus:"kaon_minus",
	Hadrons.Kaon0:"kaon_0",
	Hadrons.Invalid:"Invalid"
}

@onready var PARTICLE_TEXTURES = {}

var isOnBuild := false

func _ready():
	load_problem_set.problems.push_back(creating_problem)
	
	sort_interactions()
	sort_hadrons()
	set_interaction_strength_limits()
	
	if OS.has_feature("standalone"):
		print("Running an exported build.")
		isOnBuild = true
	else:
		print("Running from the editor.")
	
	print('started')
	
	for folder_path in ['res://Textures/ParticlesAndLines/', 'res://Textures/ParticlesAndLines/Hadrons/', 'res://Textures/Cursors/']:
		var dir = DirAccess.open(folder_path)
		dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547

		while true:
			var file = dir.get_next()
			if file == "":
				break
			
			if (isOnBuild and file.ends_with('.import')) or (!isOnBuild and file.ends_with('.png')):
				var file_name : String = file.trim_suffix('.import')
			
				if file_name.ends_with('.png'):
					PARTICLE_TEXTURES[file_name.trim_suffix('.png')] = ResourceLoader.load(folder_path + file_name)

func get_unique_file_name(folder_path: String, suffix: String = '.txt') -> String:
	var random_hex : String = "%x" % (randi() % 4095)
	
	var files: Array[String] = get_files_in_folder(folder_path)
	
	while folder_path + random_hex + suffix in files:
		random_hex = "%x" % (randi() % 4095)
	
	return folder_path + random_hex + suffix

func create_file(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("")
	file = null

func create_text_file(data: String, path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		return
	
	create_file(path)
	
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_var(data)
	file.close()

func get_resource_save_data(resource: Resource) -> String:
	return var_to_str(resource)

func save_data(data: Resource, path: String = "res://saves/") -> Error:
	return ResourceSaver.save(data, path)

func load_data(path: String) -> Resource:
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path)
	
	return null

func save(p_obj: Resource, p_path: String) -> void:
	var file = FileAccess.open(p_path, FileAccess.WRITE)
	
	if !file: return
	
	file.store_var(var_to_str(p_obj))
	file.close()

func load(p_path: String) -> Resource:
	var file = FileAccess.open(p_path, FileAccess.READ)
	var obj: Resource = str_to_var(file.get_var())
	file.close()
	return obj

func delete_file(path: String) -> Error:
	return DirAccess.remove_absolute(path)

func get_files_in_folder(folder_path: String) -> Array[String]:
	var files : Array[String] = []
	var dir := DirAccess.open(folder_path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(folder_path + file)

	return files

func get_particle_name(particle: int):
	return Particle.keys()[Particle.values().find(particle)]

func get_particle_texture(particle: int):
	return PARTICLE_TEXTURES[Particle.keys()[Particle.values().find(particle)]]

func get_hadron_texture(hadron: Hadrons):
	return PARTICLE_TEXTURES[HADRON_NAMES[hadron]]

func sort_interactions() -> void:
	for interaction_type in INTERACTIONS:
		for interaction in interaction_type:
			interaction.sort()
	
	for interaction_type in GENERAL_INTERACTIONS:
		for interaction in interaction_type:
			interaction.sort()

func sort_hadrons() -> void:
	for key in HADRON_QUARK_CONTENT.keys():
		for hadron in HADRON_QUARK_CONTENT[key]:
			hadron.sort()

func is_vec_equal_approx(vector1 : Vector2, vector2 : Vector2) -> bool:
	return is_equal_approx(vector1[0], vector2[0]) and is_equal_approx(vector1[1], vector2[1])

func set_interaction_strength_limits() -> void:
	var minimum_strength: float = 1
	var maximum_strength: float = 0
	
	for interaction_type in INTERACTION_STRENGTHS:
		for interaction_strength in interaction_type:
			if interaction_strength[0] > maximum_strength:
				maximum_strength = interaction_strength[0]
			elif interaction_strength[0] < minimum_strength:
				minimum_strength = interaction_strength[0]
	
	MAXIMUM_INTERACTION_STRENGTH = maximum_strength
	MINIMUM_INTERACTION_STRENGTH = minimum_strength

func flatten(array: Array) -> Array:
	var flat_array: Array = []
	
	for element in array:
		flat_array.append_array(element)
	
	return flat_array

func filter(array: Array, test_func: Callable) -> Array:
	var filtered_array : Array = []
	
	for element in array:
		if test_func.call(element):
			filtered_array.push_back(element)
	
	return filtered_array

func any(array: Array, test_func: Callable) -> bool:
	return array.any(test_func)

func find_var(array: Array, test_func: Callable, start_index: int = 0) -> int:
	for i in range(start_index, array.size()):
		if test_func.call(array[i]):
			return i
	
	return array.size()

func find_all_var(array: Array, test_func: Callable, start_index: int = 0) -> PackedInt32Array:
	var found_ids: PackedInt32Array = []
	
	for i in range(start_index, array.size()):
		if test_func.call(array[i]):
			found_ids.push_back(i)

	return found_ids
