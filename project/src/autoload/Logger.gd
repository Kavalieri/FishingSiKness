extends Node
class_name Logger

enum Level {DEBUG, INFO, WARN}
var log_file := "user://logs/game.log"

func log(msg: String, level: int = Level.INFO):
	var file = FileAccess.open(log_file, FileAccess.WRITE_APPEND)
	if file:
		var prefix = ["DEBUG", "INFO", "WARN"][level]
		file.store_line("[%s] %s" % [prefix, msg])
		file.close()

func debug(msg: String):
	log(msg, Level.DEBUG)

func info(msg: String):
	log(msg, Level.INFO)

func warn(msg: String):
	log(msg, Level.WARN)
