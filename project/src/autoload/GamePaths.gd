extends Node

# Sistema centralizado de rutas para Fishing SiKness
# Mantiene estructura profesional de directorios

const COMPANY_NAME = "SiKStudio"
const GAME_NAME = "FishingSiKness"

# Rutas base
const BASE_PATH = "user://%s/%s/" % [COMPANY_NAME, GAME_NAME]
const LOGS_PATH = BASE_PATH + "logs/"
const CACHE_PATH = BASE_PATH + "cache/"
const SAVEGAME_PATH = BASE_PATH + "savegame/"
const CONFIG_PATH = BASE_PATH + "config/"

# Archivos específicos
const SAVE_FILE = SAVEGAME_PATH + "save.json"
const SAVE_BACKUP = SAVEGAME_PATH + "save.bak"
const CONTENT_LOG = LOGS_PATH + "content.log"
const GAME_LOG = LOGS_PATH + "game.log"
const ERROR_LOG = LOGS_PATH + "error.log"
const SETTINGS_FILE = CONFIG_PATH + "settings.json"

func _ready():
	print("[GamePaths] Inicializando sistema de rutas...")
	create_directory_structure()

func create_directory_structure():
	"""Crear estructura de directorios si no existe"""
	var directories = [BASE_PATH, LOGS_PATH, CACHE_PATH, SAVEGAME_PATH, CONFIG_PATH]
	
	for dir_path in directories:
		if not DirAccess.dir_exists_absolute(dir_path):
			var result = DirAccess.open("user://").make_dir_recursive(dir_path.replace("user://", ""))
			if result == OK:
				print("[GamePaths] ✅ Directorio creado: %s" % dir_path)
			else:
				print("[GamePaths] ❌ Error creando directorio: %s (Error: %d)" % [dir_path, result])
		else:
			print("[GamePaths] 📁 Directorio existente: %s" % dir_path)

func get_save_file() -> String:
	return SAVE_FILE

func get_save_backup() -> String:
	return SAVE_BACKUP

func get_content_log() -> String:
	return CONTENT_LOG

func get_game_log() -> String:
	return GAME_LOG

func get_error_log() -> String:
	return ERROR_LOG

func get_settings_file() -> String:
	return SETTINGS_FILE

func get_logs_path() -> String:
	return LOGS_PATH

func get_cache_path() -> String:
	return CACHE_PATH

func get_savegame_path() -> String:
	return SAVEGAME_PATH

func get_config_path() -> String:
	return CONFIG_PATH

func clean_cache():
	"""Limpiar archivos de cache"""
	print("[GamePaths] 🧹 Limpiando cache...")
	var dir = DirAccess.open(CACHE_PATH)
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if not file.begins_with("."):
				dir.remove(file)
				print("[GamePaths] 🗑️ Eliminado: %s" % file)
			file = dir.get_next()
		dir.list_dir_end()

func log_debug_info():
	"""Log información de debug sobre las rutas"""
	print("[GamePaths] 📊 Información de rutas:")
	print("  - BASE_PATH: %s" % BASE_PATH)
	print("  - Ruta física base: %s" % ProjectSettings.globalize_path(BASE_PATH))
	print("  - SAVE_FILE: %s" % SAVE_FILE)
	print("  - Ruta física save: %s" % ProjectSettings.globalize_path(SAVE_FILE))
	print("  - LOGS_PATH: %s" % LOGS_PATH)
	print("  - Ruta física logs: %s" % ProjectSettings.globalize_path(LOGS_PATH))
