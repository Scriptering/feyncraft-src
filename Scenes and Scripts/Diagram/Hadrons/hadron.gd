extends Node2D
class_name Hadron

var quark_lines: Array
var quarks: Array[GLOBALS.Particle] = []
var hadron: int

func init(new_quark_lines: Array, new_hadron: GLOBALS.Hadrons) -> void:
	quark_lines = new_quark_lines
	hadron = new_hadron

	for quark_line in quark_lines:
		quarks.append(quark_line.particle)
