extends Node

enum Level {DEBUG, INFO, WARN}
var log_file := "user://logs/game.log"

func _ready():
	# Crear directorio de logs si no existe
	DirAccess.open("user://").make_dir_recursive("logs")

func log_message(msg: String, level: int = Level.INFO):
	var file = FileAccess.open(log_file, FileAccess.WRITE)
	if file:
		var prefix = ["DEBUG", "INFO", "WARN"][level]
		file.store_line("[%s] %s" % [prefix, msg])
		file.close()

func debug(msg: String):
	log_message(msg, Level.DEBUG)

func info(msg: String):
	log_message(msg, Level.INFO)

func warn(msg: String):
	log_message(msg, Level.WARN)
