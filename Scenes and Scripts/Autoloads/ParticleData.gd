extends Node

@onready var particle_textures : Dictionary = {}

func _ready() -> void:
	var is_on_editor := OS.has_feature("editor")
	sort_interactions()
	sort_hadrons()
	set_interaction_strength_limits()

	for folder_path : String in ['res://Textures/ParticlesAndLines/', 'res://Textures/ParticlesAndLines/Hadron/']:
		var dir := DirAccess.open(folder_path)
		dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547

		while true:
			var file := dir.get_next()
			if file == "":
				break
			
			if (!is_on_editor and file.ends_with('.import')) or (is_on_editor and file.ends_with('.png')):
				var file_name : String = file.trim_suffix('.import')
			
				if file_name.ends_with('.png'):
					particle_textures[file_name.trim_suffix('.png')] = ResourceLoader.load(folder_path + file_name)

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

const BASE_PARTICLES: Array[Particle] = [
	Particle.photon, Particle.gluon, Particle.Z, Particle.H, Particle.W, Particle.lepton, Particle.electron, Particle.muon, Particle.tau,
	Particle.lepton_neutrino, Particle.electron_neutrino, Particle.muon_neutrino, Particle.tau_neutrino,
	Particle.bright_quark, Particle.up, Particle.charm, Particle.top, Particle.dark_quark, Particle.down, Particle.strange, Particle.bottom
]

enum Hadron {Proton = 101, AntiProton, Neutron, AntiNeutron, DeltaPlusPlus, DeltaPlus, Delta0, DeltaMinus,
AntiDeltaPlusPlus, AntiDeltaPlus, AntiDelta0, AntiDeltaMinus, Epsilon0, EpsilonMinus, AntiEpsilon0, AntiEpsilonMinus,
Lambda0, AntiLambda0, SigmaPlus, SigmaMinus, AntiSigmaPlus, AntiSigmaMinus, OmegaMinus, AntiOmegaMinus,
DPlus, D0, AntiD0, DMinus, BPlus, B0, AntiB0, BMinus, JPsi, PionMinus, PionPlus, Pion0, KaonPlus, KaonMinus, Kaon0, Invalid}

enum QuantumNumber {charge, lepton, electron, muon, tau, quark, up, down, charm, strange, top, bottom, bright, dark}

enum INTERACTION_TYPE {electromagnetic, strong, weak, electroweak}

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

const LEPTONS : Array[ParticleData.Particle] = [
	Particle.lepton, Particle.electron, Particle.muon, Particle.tau,
	Particle.lepton_neutrino, Particle.electron_neutrino, Particle.muon_neutrino, Particle.tau_neutrino
]

const QUARKS : Array[ParticleData.Particle] = [
	Particle.bright_quark, Particle.dark_quark, Particle.up, Particle.down, Particle.charm, Particle.strange, Particle.top, Particle.bottom
]

const FERMIONS := LEPTONS + QUARKS

const BOSONS : Array[ParticleData.Particle] = [Particle.photon, Particle.gluon, Particle.H, Particle.W, Particle.Z]

const COLOUR_PARTICLES : Array[ParticleData.Particle] = [
	Particle.gluon,
	Particle.bright_quark, Particle.dark_quark, Particle.up, Particle.down, Particle.charm, Particle.strange, Particle.top, Particle.bottom
]

const UNSHADED_PARTICLES : Array[ParticleData.Particle] = [
	Particle.photon, Particle.gluon, Particle.Z, Particle.H
]

const SHADED_PARTICLES : Array[ParticleData.Particle] = [
	Particle.W,
	Particle.lepton, Particle.electron, Particle.muon, Particle.tau,
	Particle.lepton_neutrino, Particle.electron_neutrino, Particle.muon_neutrino, Particle.tau_neutrino,
	Particle.bright_quark, Particle.dark_quark, Particle.up, Particle.down, Particle.top, Particle.bottom, Particle.charm, Particle.strange
]

const BRIGHT_PARTICLES : Array[ParticleData.Particle] = [
	Particle.W,
	Particle.bright_quark, Particle.up, Particle.charm, Particle.top,
	Particle.lepton_neutrino, Particle.electron_neutrino, Particle.muon_neutrino, Particle.tau_neutrino
]

const DARK_PARTICLES : Array[ParticleData.Particle] = [
	Particle.W,
	Particle.dark_quark, Particle.down, Particle.strange, Particle.bottom,
	Particle.lepton, Particle.electron, Particle.muon, Particle.tau
]

const SHADE_PARTICLES : Array = [
	BRIGHT_PARTICLES,
	DARK_PARTICLES,
	SHADED_PARTICLES
]

const GENERAL_PARTICLES : Array[ParticleData.Particle] = [
	Particle.lepton, Particle.lepton_neutrino, Particle.bright_quark, Particle.dark_quark
]

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
		[Particle.up, Particle.dark_quark, Particle.W],
		[Particle.charm, Particle.dark_quark, Particle.W],
		[Particle.top, Particle.dark_quark, Particle.W],
		[Particle.down, Particle.bright_quark, Particle.W],
		[Particle.strange, Particle.bright_quark, Particle.W],
		[Particle.bottom, Particle.bright_quark, Particle.W],
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
		[Particle.W, Particle.W, Particle.H],
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
		[Particle.H, Particle.H, Particle.H],
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

const MIN_INTERACTION_STRENGTH: float = 1e-3
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

const BARYONS : Array[Hadron] = [
	Hadron.Proton, Hadron.AntiProton, Hadron.Neutron, Hadron.AntiNeutron, Hadron.DeltaPlusPlus, Hadron.DeltaPlus, Hadron.Delta0,
	Hadron.DeltaMinus, Hadron.AntiDeltaPlusPlus, Hadron.AntiDeltaPlus, Hadron.AntiDelta0, Hadron.AntiDeltaMinus, Hadron.Epsilon0,
	Hadron.EpsilonMinus, Hadron.AntiEpsilon0, Hadron.AntiEpsilonMinus, Hadron.Lambda0, Hadron.AntiLambda0, Hadron.SigmaPlus,
	Hadron.SigmaMinus, Hadron.AntiSigmaPlus, Hadron.AntiSigmaMinus, Hadron.OmegaMinus, Hadron.AntiOmegaMinus
]

const MESONS : Array[Hadron] = [
	Hadron.DPlus, Hadron.D0, Hadron.AntiD0, Hadron.DMinus, Hadron.BPlus, Hadron.B0, Hadron.AntiB0, Hadron.BMinus, Hadron.JPsi,
	Hadron.PionMinus, Hadron.PionPlus, Hadron.Pion0, Hadron.KaonPlus, Hadron.KaonMinus, Hadron.Kaon0
]
 
var HADRON_QUARK_CONTENT : Dictionary = {
	Hadron.Proton:[[Particle.down, Particle.up, Particle.up]],
	Hadron.AntiProton:[[Particle.anti_down, Particle.anti_up, Particle.anti_up]],
	Hadron.Neutron:[[Particle.down, Particle.down, Particle.up]],
	Hadron.AntiNeutron:[[Particle.anti_down, Particle.anti_down, Particle.anti_up]],
	Hadron.DeltaPlusPlus:[[Particle.up, Particle.up, Particle.up]],
	Hadron.DeltaPlus:[[Particle.down, Particle.up, Particle.up]],
	Hadron.Delta0:[[Particle.down,Particle.down,Particle.up]],
	Hadron.DeltaMinus:[[Particle.down,Particle.down,Particle.down]],
	Hadron.AntiDeltaPlusPlus:[[Particle.anti_up, Particle.anti_up, Particle.anti_up]],
	Hadron.AntiDeltaPlus:[[Particle.anti_down, Particle.anti_up, Particle.anti_up]],
	Hadron.AntiDelta0:[[Particle.anti_down,Particle.anti_down,Particle.anti_up]],
	Hadron.AntiDeltaMinus:[[Particle.anti_down,Particle.anti_down,Particle.anti_down]],
	Hadron.Epsilon0:[[Particle.strange, Particle.strange, Particle.up]],
	Hadron.EpsilonMinus:[[Particle.down, Particle.strange, Particle.strange]],
	Hadron.AntiEpsilon0:[[Particle.anti_strange, Particle.anti_strange, Particle.anti_up]],
	Hadron.AntiEpsilonMinus:[[Particle.anti_down, Particle.anti_strange, Particle.anti_strange]],
	Hadron.Lambda0:[[Particle.down, Particle.strange, Particle.up]],
	Hadron.AntiLambda0:[[Particle.anti_down, Particle.anti_strange, Particle.anti_up]],
	Hadron.SigmaPlus:[[Particle.strange, Particle.up, Particle.up]],
	Hadron.SigmaMinus:[[Particle.down, Particle.down, Particle.strange]],
	Hadron.AntiSigmaPlus:[[Particle.anti_strange, Particle.anti_up, Particle.anti_up]],
	Hadron.AntiSigmaMinus:[[Particle.anti_down, Particle.anti_down, Particle.anti_strange]],
	Hadron.OmegaMinus:[[Particle.strange,Particle.strange,Particle.strange]],
	Hadron.AntiOmegaMinus:[[Particle.anti_strange,Particle.anti_strange,Particle.anti_strange]],
	Hadron.DPlus:[[Particle.charm, Particle.anti_down]],
	Hadron.D0:[[Particle.anti_charm, Particle.up]],
	Hadron.AntiD0:[[Particle.charm, Particle.anti_up]],
	Hadron.DMinus:[[Particle.anti_charm, Particle.down]],
	Hadron.BPlus:[[Particle.anti_bottom, Particle.up]],
	Hadron.B0:[[Particle.anti_bottom, Particle.down]],
	Hadron.AntiB0:[[Particle.bottom, Particle.anti_down]],
	Hadron.BMinus:[[Particle.bottom, Particle.anti_up]],
	Hadron.JPsi:[[Particle.charm, Particle.anti_charm]],
	Hadron.PionMinus:[[Particle.down, Particle.anti_up]],
	Hadron.PionPlus:[[Particle.anti_down, Particle.up]],
	Hadron.Pion0:[[Particle.down,Particle.anti_down], [Particle.up, Particle.anti_up]],
	Hadron.KaonPlus:[[Particle.anti_strange, Particle.up]],
	Hadron.KaonMinus:[[Particle.strange, Particle.anti_up]],
	Hadron.Kaon0:[[Particle.down, Particle.anti_strange], [Particle.anti_down, Particle.strange]],
	Hadron.Invalid:[]
}

const HADRON_NAMES : Dictionary = {
	Hadron.Proton:"proton",
	Hadron.AntiProton:"proton_anti",
	Hadron.Neutron:"neutron",
	Hadron.AntiNeutron:"neutron_anti",
	Hadron.DeltaPlusPlus:"delta_plus_plus",
	Hadron.DeltaPlus:"delta_plus",
	Hadron.Delta0:"delta_0",
	Hadron.DeltaMinus:"delta_minus",
	Hadron.AntiDeltaPlusPlus:"delta_plus_plus_anti",
	Hadron.AntiDeltaPlus:"delta_plus_anti",
	Hadron.AntiDelta0:"delta_0_anti",
	Hadron.AntiDeltaMinus:"delta_minus_anti",
	Hadron.Epsilon0:"epsilon_0",
	Hadron.EpsilonMinus:"epsilon_minus",
	Hadron.AntiEpsilon0:"epsilon_0_anti",
	Hadron.AntiEpsilonMinus:"epsilon_minus_anti",
	Hadron.Lambda0:"lambda_0",
	Hadron.AntiLambda0:"lambda_0_anti",
	Hadron.SigmaPlus:"sigma_plus",
	Hadron.SigmaMinus:"sigma_minus",
	Hadron.AntiSigmaPlus:"sigma_plus_anti",
	Hadron.AntiSigmaMinus:"sigma_minus_anti",
	Hadron.OmegaMinus:"omega_minus",
	Hadron.AntiOmegaMinus:"omega_minus_anti",
	Hadron.DPlus:"D_plus",
	Hadron.D0:"D_0",
	Hadron.AntiD0:"D_0_anti",
	Hadron.DMinus:"D_minus",
	Hadron.BPlus:"B_plus",
	Hadron.B0:"B_0",
	Hadron.AntiB0:"B_0_anti",
	Hadron.BMinus:"B_minus",
	Hadron.JPsi:"J_psi",
	Hadron.PionMinus:"pion_minus",
	Hadron.PionPlus:"pion_plus",
	Hadron.Pion0:"pion_0",
	Hadron.KaonPlus:"kaon_plus",
	Hadron.KaonMinus:"kaon_minus",
	Hadron.Kaon0:"kaon_0",
	Hadron.Invalid:"Invalid"
}

func get_particle_name(particle: int) -> String:
	return Particle.keys()[Particle.values().find(particle)]

func get_particle_texture(particle: int) -> Texture2D:
	return particle_textures[Particle.keys()[Particle.values().find(particle)]]

func get_particle_icon(particle: int) -> Texture2D:
	return load("res://Textures/Buttons/icons/Particles/" + get_particle_name(particle) + ".png")

func get_hadron_texture(hadron: Hadron) -> Texture2D:
	return particle_textures[HADRON_NAMES[hadron]]

func find_hadron(interaction: Array) -> Hadron:
	var sorted_interaction: Array = interaction.duplicate()
	sorted_interaction.sort()
	
	for key:Hadron in HADRON_QUARK_CONTENT.keys():
		if sorted_interaction in HADRON_QUARK_CONTENT[key]:
			return key
	
	return Hadron.Invalid

func sort_interactions() -> void:
	for interaction_type:Array in INTERACTIONS:
		for interaction:Array in interaction_type:
			interaction.sort()
	
	for interaction_type:Array in GENERAL_INTERACTIONS:
		for interaction:Array in interaction_type:
			interaction.sort()
	
	for particle:Particle in BASE_PARTICLES:
		for interaction:Array in PARTICLE_INTERACTIONS[particle]:
			interaction.sort()

func sort_hadrons() -> void:
	for key:Hadron in HADRON_QUARK_CONTENT.keys():
		for hadron:Array in HADRON_QUARK_CONTENT[key]:
			hadron.sort()

func is_vec_equal_approx(vector1 : Vector2, vector2 : Vector2) -> bool:
	return is_equal_approx(vector1[0], vector2[0]) and is_equal_approx(vector1[1], vector2[1])

func set_interaction_strength_limits() -> void:
	var minimum_strength: float = 1
	var maximum_strength: float = 0
	
	for i:int in INTERACTION_STRENGTHS.size():
		for j:int in INTERACTION_STRENGTHS[i].size():
			INTERACTION_STRENGTHS[i][j][0] = max(INTERACTION_STRENGTHS[i][j][0], MIN_INTERACTION_STRENGTH)
			var interaction_strength: float = INTERACTION_STRENGTHS[i][j][0]
			
			if interaction_strength > maximum_strength:
				maximum_strength = interaction_strength
			elif interaction_strength < minimum_strength:
				minimum_strength = interaction_strength
	
	MAXIMUM_INTERACTION_STRENGTH = maximum_strength
	MINIMUM_INTERACTION_STRENGTH = minimum_strength


#0 photon, 1 gluon, 2 Z, 3 H, 4 W,
#5 lepton, 6 electron, 7 muon, 8 tau,
#9 lepton_neutrino, 10 electron_neutrino, 11 muon_neutrino, 12 tau_neutrino,
#13 bright_quark, 14 up, 15 charm, 16 top, 17 dark_quark, 18 down, 19 strange, 20 bottom,

var PARTICLE_INTERACTIONS : Dictionary = {
	Particle.photon : [
		[Particle.photon, Particle.bright_quark, Particle.bright_quark],
		[Particle.photon, Particle.dark_quark, Particle.dark_quark],
		[Particle.photon, Particle.lepton, Particle.lepton],
		[Particle.photon, Particle.W, Particle.W],
		[Particle.photon, Particle.W, Particle.W, Particle.photon],
		[Particle.photon, Particle.W, Particle.W, Particle.Z]
	],
	Particle.gluon : [
		[Particle.gluon, Particle.bright_quark, Particle.bright_quark],
		[Particle.gluon, Particle.dark_quark, Particle.dark_quark],
		[Particle.gluon, Particle.gluon, Particle.gluon],
		[Particle.gluon, Particle.gluon, Particle.gluon, Particle.gluon]
	],
	Particle.Z : [
		[Particle.Z, Particle.bright_quark, Particle.bright_quark],
		[Particle.Z, Particle.dark_quark, Particle.dark_quark],
		[Particle.Z, Particle.lepton, Particle.lepton],
		[Particle.Z, Particle.lepton_neutrino, Particle.lepton_neutrino],
		[Particle.Z, Particle.W, Particle.W],
		[Particle.Z, Particle.W, Particle.W, Particle.Z],
		[Particle.Z, Particle.W, Particle.W, Particle.photon],
		[Particle.Z, Particle.H, Particle.Z],
		[Particle.Z, Particle.H, Particle.H, Particle.Z],
	],
	Particle.H : [
		[Particle.H, Particle.bright_quark, Particle.bright_quark],
		[Particle.H, Particle.dark_quark, Particle.dark_quark],
		[Particle.H, Particle.lepton, Particle.lepton],
		[Particle.H, Particle.lepton_neutrino, Particle.lepton_neutrino],
		[Particle.H, Particle.Z, Particle.Z],
		[Particle.H, Particle.H, Particle.H, Particle.H],
		[Particle.H, Particle.H, Particle.Z, Particle.Z],
		[Particle.H, Particle.H, Particle.W, Particle.W]
	],
	Particle.W : [
		[Particle.W, Particle.lepton, Particle.lepton_neutrino],
		[Particle.W, Particle.bright_quark, Particle.dark_quark],
		[Particle.W, Particle.W, Particle.Z],
		[Particle.W, Particle.W, Particle.photon],
		[Particle.W, Particle.W, Particle.W, Particle.W],
		[Particle.W, Particle.W, Particle.Z, Particle.Z],
		[Particle.W, Particle.W, Particle.photon, Particle.photon],
		[Particle.W, Particle.W, Particle.Z, Particle.photon],
		[Particle.W, Particle.H, Particle.H, Particle.W]
	],
	Particle.lepton : [
		[Particle.lepton, Particle.lepton, Particle.photon],
		[Particle.lepton, Particle.lepton, Particle.Z],
		[Particle.lepton, Particle.lepton, Particle.H],
		[Particle.lepton, Particle.lepton_neutrino, Particle.W],
	],
	Particle.electron : [
		[Particle.electron, Particle.electron, Particle.photon],
		[Particle.electron, Particle.electron, Particle.Z],
		[Particle.electron, Particle.electron, Particle.H],
		[Particle.electron, Particle.electron_neutrino, Particle.W],
	],
	Particle.muon : [
		[Particle.muon, Particle.muon, Particle.photon],
		[Particle.muon, Particle.muon, Particle.Z],
		[Particle.muon, Particle.muon, Particle.H],
		[Particle.muon, Particle.muon_neutrino, Particle.W],
	],
	Particle.tau : [
		[Particle.tau, Particle.tau, Particle.photon],
		[Particle.tau, Particle.tau, Particle.Z],
		[Particle.tau, Particle.tau, Particle.H],
		[Particle.tau, Particle.tau_neutrino, Particle.W],
	],
	Particle.lepton_neutrino : [
		[Particle.lepton_neutrino, Particle.lepton_neutrino, Particle.Z],
		[Particle.lepton_neutrino, Particle.lepton_neutrino, Particle.H],
		[Particle.lepton_neutrino, Particle.lepton, -Particle.W],
	],
	Particle.electron_neutrino : [
		[Particle.electron_neutrino, Particle.electron_neutrino, Particle.Z],
		[Particle.electron_neutrino, Particle.electron_neutrino, Particle.H],
		[Particle.electron_neutrino, Particle.electron, -Particle.W],
	],
	Particle.muon_neutrino : [
		[Particle.muon_neutrino, Particle.muon_neutrino, Particle.Z],
		[Particle.muon_neutrino, Particle.muon_neutrino, Particle.H],
		[Particle.muon_neutrino, Particle.muon, -Particle.W],
	],
	Particle.tau_neutrino : [
		[Particle.tau_neutrino, Particle.tau_neutrino, Particle.Z],
		[Particle.tau_neutrino, Particle.tau_neutrino, Particle.H],
		[Particle.tau_neutrino, Particle.tau, -Particle.W],
	],
	Particle.bright_quark : [
		[Particle.bright_quark, Particle.bright_quark, Particle.photon],
		[Particle.bright_quark, Particle.bright_quark, Particle.gluon],
		[Particle.bright_quark, Particle.bright_quark, Particle.Z],
		[Particle.bright_quark, Particle.bright_quark, Particle.H],
		[Particle.bright_quark, Particle.dark_quark, -Particle.W],
	],
	Particle.up : [
		[Particle.up, Particle.up, Particle.photon],
		[Particle.up, Particle.up, Particle.gluon],
		[Particle.up, Particle.up, Particle.Z],
		[Particle.up, Particle.up, Particle.H],
		[Particle.up, Particle.dark_quark, -Particle.W],
	],
	Particle.charm : [
		[Particle.charm, Particle.charm, Particle.photon],
		[Particle.charm, Particle.charm, Particle.gluon],
		[Particle.charm, Particle.charm, Particle.Z],
		[Particle.charm, Particle.charm, Particle.H],
		[Particle.charm, Particle.dark_quark, -Particle.W],
	],
	Particle.top : [
		[Particle.top, Particle.top, Particle.photon],
		[Particle.top, Particle.top, Particle.gluon],
		[Particle.top, Particle.top, Particle.Z],
		[Particle.top, Particle.top, Particle.H],
		[Particle.top, Particle.dark_quark, -Particle.W],
	],
	Particle.dark_quark : [
		[Particle.dark_quark, Particle.dark_quark, Particle.photon],
		[Particle.dark_quark, Particle.dark_quark, Particle.gluon],
		[Particle.dark_quark, Particle.dark_quark, Particle.Z],
		[Particle.dark_quark, Particle.dark_quark, Particle.H],
		[Particle.dark_quark, Particle.bright_quark, Particle.W],
	],
	Particle.down : [
		[Particle.down, Particle.down, Particle.photon],
		[Particle.down, Particle.down, Particle.gluon],
		[Particle.down, Particle.down, Particle.Z],
		[Particle.down, Particle.down, Particle.H],
		[Particle.down, Particle.bright_quark, Particle.W],
	],
	Particle.strange : [
		[Particle.strange, Particle.strange, Particle.photon],
		[Particle.strange, Particle.strange, Particle.gluon],
		[Particle.strange, Particle.strange, Particle.Z],
		[Particle.strange, Particle.strange, Particle.H],
		[Particle.strange, Particle.bright_quark, Particle.W],
	],
	Particle.bottom : [
		[Particle.bottom, Particle.bottom, Particle.photon],
		[Particle.bottom, Particle.bottom, Particle.gluon],
		[Particle.bottom, Particle.bottom, Particle.Z],
		[Particle.bottom, Particle.bottom, Particle.H],
		[Particle.bottom, Particle.bright_quark, Particle.W],
	]
}

const export_particle_dict : Dictionary = {
	Particle.photon : "\\gamma",
	Particle.gluon : "g",
	Particle.Z : "Z",
	Particle.H : "H",
	Particle.W : "W",
	Particle.lepton : "l^{-}",
	Particle.electron : "e^{-}",
	Particle.muon : "\\mu^{-}",
	Particle.tau : "\\tau^{-}",
	Particle.lepton_neutrino : "\\nu_{l}",
	Particle.electron_neutrino : "\\nu_{e}",
	Particle.muon_neutrino : "\\nu_{\\mu}",
	Particle.tau_neutrino : "\\nu_{\\tau}",
	Particle.bright_quark : "q^{u}",
	Particle.up : "u",
	Particle.charm : "c",
	Particle.top : "t",
	Particle.dark_quark : "q^{d}",
	Particle.down : "d",
	Particle.strange : "s",
	Particle.bottom : "b",
	Particle.anti_bottom : "\\overline b",
	Particle.anti_strange : "\\overline s",
	Particle.anti_down : "\\overline d",
	Particle.anti_dark_quark : "\\overline q^{d}",
	Particle.anti_top : "\\overline t",
	Particle.anti_charm : "\\overline c",
	Particle.anti_up : "\\overline u",
	Particle.anti_bright_quark : "\\overline q^{u}",
	Particle.anti_tau_neutrino : "\\overline \\nu_{\\tau}",
	Particle.anti_muon_neutrino : "\\overline \\nu_{\\mu}",
	Particle.anti_electron_neutrino : "\\overline \\nu_{e}",
	Particle.anti_lepton_neutrino : "\\overline \\nu_{l}",
	Particle.anti_tau : "\\tau^{+}",
	Particle.anti_muon : "\\mu^{+}",
	Particle.anti_electron : "e^{+}",
	Particle.anti_lepton : "l^{+}",
	Particle.anti_W : "W^{+}",
}

const export_hadron_dict : Dictionary = {
	Hadron.Proton:"p",
	Hadron.AntiProton:"\\overline p",
	Hadron.Neutron:"n",
	Hadron.AntiNeutron:"\\overline n",
	Hadron.DeltaPlusPlus:"\\Delta^{++}",
	Hadron.DeltaPlus:"\\Delta^{+}",
	Hadron.Delta0:"\\Delta^{0}",
	Hadron.DeltaMinus:"\\Delta^{-}",
	Hadron.AntiDeltaPlusPlus:"\\overline \\Delta^{++}",
	Hadron.AntiDeltaPlus:"\\overline \\Delta^{+}",
	Hadron.AntiDelta0:"\\overline \\Delta^{0}",
	Hadron.AntiDeltaMinus:"\\overline \\Delta^{-}",
	Hadron.Epsilon0:"\\Epsilon^{0}",
	Hadron.EpsilonMinus:"\\Epsilon^{-}",
	Hadron.AntiEpsilon0:"\\overline \\Epsilon^{0}",
	Hadron.AntiEpsilonMinus:"\\overline \\Epsilon^{-}",
	Hadron.Lambda0:"\\Lambda^{0}",
	Hadron.AntiLambda0:"\\overline \\Lambda^{0}",
	Hadron.SigmaPlus:"\\Sigma^{+}",
	Hadron.SigmaMinus:"\\Sigma^{-}",
	Hadron.AntiSigmaPlus:"\\overline \\Sigma^{+}",
	Hadron.AntiSigmaMinus:"\\overline \\Sigma^{-}",
	Hadron.OmegaMinus:"\\Omega{-}",
	Hadron.AntiOmegaMinus:"\\overline \\Omega^{-}",
	Hadron.DPlus:"D^{+}",
	Hadron.D0:"D^{0}",
	Hadron.AntiD0:"\\overline D^{0}",
	Hadron.DMinus:"\\overline D^{-}",
	Hadron.BPlus:"B^{+}",
	Hadron.B0:"B^{0}",
	Hadron.AntiB0:"\\overline B^{0}",
	Hadron.BMinus:"\\overline B^{-}",
	Hadron.JPsi:"J//psi",
	Hadron.PionMinus:"\\pi^{-}",
	Hadron.PionPlus:"\\pi^{+}",
	Hadron.Pion0:"\\pi^{0}",
	Hadron.KaonPlus:"K^{+}",
	Hadron.KaonMinus:"K^{-}",
	Hadron.Kaon0:"K^{0}",
	Hadron.Invalid:"Invalid"
}

const export_line_dict : Dictionary = {
	Particle.photon : "photon",
	Particle.gluon : "gluon",
	Particle.Z : "boson",
	Particle.H : "scalar",
	Particle.W : "boson",
	Particle.lepton : "fermion",
	Particle.electron : "fermion",
	Particle.muon : "fermion",
	Particle.tau : "fermion",
	Particle.lepton_neutrino : "fermion",
	Particle.electron_neutrino : "fermion",
	Particle.muon_neutrino : "fermion",
	Particle.tau_neutrino : "fermion",
	Particle.bright_quark : "fermion",
	Particle.up : "fermion",
	Particle.charm : "fermion",
	Particle.top : "fermion",
	Particle.dark_quark : "fermion",
	Particle.down : "fermion",
	Particle.strange : "fermion",
	Particle.bottom : "fermion",
	Particle.anti_bottom : "anti fermion",
	Particle.anti_strange : "anti fermion",
	Particle.anti_down : "anti fermion",
	Particle.anti_dark_quark : "anti fermion",
	Particle.anti_top : "anti fermion",
	Particle.anti_charm : "anti fermion",
	Particle.anti_up : "anti fermion",
	Particle.anti_bright_quark : "anti fermion",
	Particle.anti_tau_neutrino : "anti fermion",
	Particle.anti_muon_neutrino : "anti fermion",
	Particle.anti_electron_neutrino : "anti fermion",
	Particle.anti_lepton_neutrino : "anti fermion",
	Particle.anti_tau : "anti fermion",
	Particle.anti_muon : "anti fermion",
	Particle.anti_electron : "anti fermion",
	Particle.anti_lepton : "anti fermion",
	Particle.anti_W : "boson",
}

func anti(particle: ParticleData.Particle) -> ParticleData.Particle:
	if particle in SHADED_PARTICLES:
		return -particle as ParticleData.Particle
	
	return particle
