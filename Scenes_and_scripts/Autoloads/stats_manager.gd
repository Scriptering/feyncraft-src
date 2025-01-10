extends Node

const stats_version : int = 1
var stats: PlayerStats
@onready var save_path: String = FileManager.get_file_prefix() + "saves/stats.tres"

func _ready() -> void:
	if !Globals.is_on_editor and !DirAccess.dir_exists_absolute("User://saves/"):
		FileManager.create_save_folders()

	if !FileAccess.file_exists(save_path):
		create_player_stats()
	
	stats = load(save_path)
	stats.changed.connect(save_stats)

func create_player_stats() -> void:
	ResourceSaver.save(PlayerStats.new(), save_path)

func save_stats() -> void:
	ResourceSaver.save(stats, save_path)
