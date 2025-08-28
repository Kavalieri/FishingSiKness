extends Node

enum Level {DEBUG, INFO, WARN}
var log_file: String

func _ready():
	print("[Logger] Inicializando sistema de logging...")
	
	# Esperar a que GamePaths esté listo
	if not GamePaths:
		await get_tree().process_frame
	
	# Configurar ruta de log
	log_file = GamePaths.get_game_log()
	print("[Logger] Archivo de log configurado: %s" % log_file)

func log_message(msg: String, level: int = Level.INFO):
	if not log_file:
		return
		
	var file = FileAccess.open(log_file, FileAccess.WRITE)
	if file:
		var prefix = ["DEBUG", "INFO", "WARN"][level]
		var timestamp = Time.get_datetime_string_from_system()
		file.store_line("[%s] %s - %s" % [timestamp, prefix, msg])
		file.close()

func debug(msg: String):
	log_message(msg, Level.DEBUG)

func info(msg: String):
	log_message(msg, Level.INFO)

func warn(msg: String):
	log_message(msg, Level.WARN)
