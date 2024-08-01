extends Node
class_name DrawingMatrixExporter

const xscale:float = .25
const yscale:float = .25

const particle_dict : Dictionary = {
	ParticleData.Particle.photon : "\\(\\gamma\\)",
	ParticleData.Particle.gluon : "\\(W^{-}\\)",
	ParticleData.Particle.Z : "\\(Z\\)",
	ParticleData.Particle.H : "\\(H\\)",
	ParticleData.Particle.W : "\\(W\\)",
	ParticleData.Particle.lepton : "\\(l^{-}\\)",
	ParticleData.Particle.electron : "\\(e^{-}\\)",
	ParticleData.Particle.muon : "\\(\\mu^{-}\\)",
	ParticleData.Particle.tau : "\\(\\tau^{-}\\)",
	ParticleData.Particle.lepton_neutrino : "\\(\\nu_{l}\\)",
	ParticleData.Particle.electron_neutrino : "\\(\\nu_{e}\\)",
	ParticleData.Particle.muon_neutrino : "\\(\\nu_{\\mu}\\)",
	ParticleData.Particle.tau_neutrino : "\\(\\nu_{\\tau}\\)",
	ParticleData.Particle.bright_quark : "\\(q^{u}\\)",
	ParticleData.Particle.up : "\\(u\\)",
	ParticleData.Particle.charm : "\\(c\\)",
	ParticleData.Particle.top : "\\(t\\)",
	ParticleData.Particle.dark_quark : "\\(q^{d}\\)",
	ParticleData.Particle.down : "\\(d\\)",
	ParticleData.Particle.strange : "\\(s\\)",
	ParticleData.Particle.bottom : "\\(b\\)",
	ParticleData.Particle.anti_bottom : "\\(\\overline b\\)",
	ParticleData.Particle.anti_strange : "\\(\\overline s\\)",
	ParticleData.Particle.anti_down : "\\(\\overline d\\)",
	ParticleData.Particle.anti_dark_quark : "\\(\\overline q^{d}\\)",
	ParticleData.Particle.anti_top : "\\(\\overline t\\)",
	ParticleData.Particle.anti_charm : "\\(\\overline c\\)",
	ParticleData.Particle.anti_up : "\\(\\overline u\\)",
	ParticleData.Particle.anti_bright_quark : "\\(\\overline q^{u}\\)",
	ParticleData.Particle.anti_tau_neutrino : "\\(\\overline \\nu_{\\tau}\\)",
	ParticleData.Particle.anti_muon_neutrino : "\\(\\overline \\nu_{\\mu}\\)",
	ParticleData.Particle.anti_electron_neutrino : "\\(\\overline \\nu_{e}\\)",
	ParticleData.Particle.anti_lepton_neutrino : "\\(\\overline \\nu_{l}\\)",
	ParticleData.Particle.anti_tau : "\\(\\tau^{+}\\)",
	ParticleData.Particle.anti_muon : "\\(\\mu^{+}\\)",
	ParticleData.Particle.anti_electron : "\\(e^{+}\\)",
	ParticleData.Particle.anti_lepton : "\\(l^{+}\\)",
	ParticleData.Particle.anti_W : "\\(W^{+}\\)",
}

const line_dict : Dictionary = {
	ParticleData.Particle.photon : "photon",
	ParticleData.Particle.gluon : "gluon",
	ParticleData.Particle.Z : "boson",
	ParticleData.Particle.H : "scalar",
	ParticleData.Particle.W : "boson",
	ParticleData.Particle.lepton : "fermion",
	ParticleData.Particle.electron : "fermion",
	ParticleData.Particle.muon : "fermion",
	ParticleData.Particle.tau : "fermion",
	ParticleData.Particle.lepton_neutrino : "fermion",
	ParticleData.Particle.electron_neutrino : "fermion",
	ParticleData.Particle.muon_neutrino : "fermion",
	ParticleData.Particle.tau_neutrino : "fermion",
	ParticleData.Particle.bright_quark : "fermion",
	ParticleData.Particle.up : "fermion",
	ParticleData.Particle.charm : "fermion",
	ParticleData.Particle.top : "fermion",
	ParticleData.Particle.dark_quark : "fermion",
	ParticleData.Particle.down : "fermion",
	ParticleData.Particle.strange : "fermion",
	ParticleData.Particle.bottom : "fermion",
	ParticleData.Particle.anti_bottom : "anti fermion",
	ParticleData.Particle.anti_strange : "anti fermion",
	ParticleData.Particle.anti_down : "anti fermion",
	ParticleData.Particle.anti_dark_quark : "anti fermion",
	ParticleData.Particle.anti_top : "anti fermion",
	ParticleData.Particle.anti_charm : "anti fermion",
	ParticleData.Particle.anti_up : "anti fermion",
	ParticleData.Particle.anti_bright_quark : "anti fermion",
	ParticleData.Particle.anti_tau_neutrino : "anti fermion",
	ParticleData.Particle.anti_muon_neutrino : "anti fermion",
	ParticleData.Particle.anti_electron_neutrino : "anti fermion",
	ParticleData.Particle.anti_lepton_neutrino : "anti fermion",
	ParticleData.Particle.anti_tau : "anti fermion",
	ParticleData.Particle.anti_muon : "anti fermion",
	ParticleData.Particle.anti_electron : "anti fermion",
	ParticleData.Particle.anti_lepton : "anti fermion",
	ParticleData.Particle.anti_W : "boson",
}

static func get_lowest_x(positions: Array[Vector2i]) -> int:
	var lowest_x: int = positions[0].x
	
	for position: Vector2i in positions:
		if position.x < lowest_x:
			lowest_x = position.x

	return lowest_x

static func get_highest_y(positions: Array[Vector2i]) -> int:
	var highest_y: int = positions[0].y
	
	for position: Vector2i in positions:
		if position.y > highest_y:
			highest_y = position.y

	return highest_y

static func get_string(drawing_matrix: DrawingMatrix) -> String:
	var exporting_matrix: DrawingMatrix = drawing_matrix.duplicate(true)
	exporting_matrix.rejoin_double_connections()
	
	var interaction_positions := exporting_matrix.normalised_interaction_positions
	
	var lowest_x : int = get_lowest_x(interaction_positions)
	var highest_y : int = get_highest_y(interaction_positions)
	
	for i:int in interaction_positions.size():
		interaction_positions[i] *= Vector2i(+1, -1)
		interaction_positions[i] -= Vector2i(lowest_x, -highest_y)
	
	var export_string : String = "\\begin{tikzpicture}\n\\begin{feynman}\n"
	export_string += "\\def\\xscale{%s}\n\\def\\yscale{%s}\n" % [
		xscale, yscale
	]
	
	for i:int in exporting_matrix.matrix_size:
		export_string += "\\vertex (i%s) at (%s*\\xscale, %s*\\yscale)%s;\n" % [
			i,
			exporting_matrix.normalised_interaction_positions[i].x,
			exporting_matrix.normalised_interaction_positions[i].y,
			" {%s}" if exporting_matrix.is_extreme_point(i) else ""
		]

	export_string += "\\diagram* {\n"

	for i:int in exporting_matrix.matrix_size:
		for c:Array in exporting_matrix.get_connections(i):
			var particle : ParticleData.Particle = c[ConnectionMatrix.Connection.particle]
			var to_id : int = c[ConnectionMatrix.Connection.to_id]
			
			var is_right : bool = interaction_positions[to_id].x > interaction_positions[i].x
			
			if particle in ParticleData.SHADED_PARTICLES:
				if !is_right:
					particle = -particle
			
			var left_id: int = i if is_right else to_id
			var right_id: int = to_id if is_right else i
			
			export_string += "(i%s) -- [%s, edge label = %s] (i%s),\n" % [
				left_id,
				line_dict[particle],
				particle_dict[particle],
				right_id
			]

	export_string += "};\n\\end{feynman}\n\\end{tikzpicture}\n"

	return export_string
