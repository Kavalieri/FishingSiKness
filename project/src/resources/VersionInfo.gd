class_name VersionInfo
extends RefCounted

# Sistema de versiones para desarrollo - NO se empaqueta con el ejecutable
# Solo funciona en desarrollo donde existe el directorio build/

static var _cached_version_data: Dictionary = {}
static var _cache_loaded := false

static func get_version_info() -> Dictionary:
	"""Obtener información de versión desde build/version.json (solo desarrollo)"""
	if _cache_loaded:
		return _cached_version_data

	# Ruta al archivo de versión (solo existe en desarrollo)
	var version_path = "res://../build/version.json"

	# Verificar si existe (solo en desarrollo)
	if not FileAccess.file_exists(version_path):
		print("⚠️ version.json no encontrado - usando datos por defecto (modo empaquetado)")
		return get_fallback_version_info()

	# Leer archivo de versión
	var file = FileAccess.open(version_path, FileAccess.READ)
	if not file:
		print("❌ Error al leer version.json")
		return get_fallback_version_info()

	var json_text = file.get_as_text()
	file.close()

	# Parsear JSON
	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		print("❌ Error al parsear version.json")
		return get_fallback_version_info()

	_cached_version_data = json.data
	_cache_loaded = true
	print("✅ Información de versión cargada desde build/version.json")
	return _cached_version_data

static func get_fallback_version_info() -> Dictionary:
	"""Información por defecto para el ejecutable empaquetado"""
	return {
		"game": {
			"name": "Fishing SiKness",
			"version": "0.1.0",
			"status": "release",
			"build_number": 1
		},
		"development": {
			"developer": "Kava",
			"studio": "SiK Studio",
			"year": 2025,
			"ai_powered": true,
			"ai_description": "Hecho 100% con Agentes IA"
		},
		"license": {
			"type": "GNU GPL v3.0",
			"url": "https://www.gnu.org/licenses/gpl-3.0.html",
			"open_source": true
		},
		"display": {
			"splash_footer": {
				"line1": "Fishing SiKness v0.1.0 release",
				"line2": "© 2025 Kava - SiK Studio",
				"line3": "Hecho 100% con Agentes IA",
				"line4": "GNU GPL v3.0 - Open Source"
			}
		}
	}

static func get_formatted_footer_lines() -> Array[String]:
	"""Obtener líneas formateadas para el footer de la splash screen"""
	var version_data = get_version_info()
	var display_data = version_data.get("display", {}).get("splash_footer", {})

	var lines: Array[String] = []

	# Procesar cada línea y reemplazar variables
	for i in range(1, 5):
		var line_key = "line" + str(i)
		var line_template = display_data.get(line_key, "")
		var formatted_line = format_template(line_template, version_data)
		if formatted_line.length() > 0:
			lines.append(formatted_line)

	return lines

static func format_template(template: String, data: Dictionary) -> String:
	"""Reemplazar variables en plantilla usando datos anidados"""
	var result = template

	# Reemplazar variables simples como {game.name}, {development.year}, etc.
	var game_data = data.get("game", {})
	var dev_data = data.get("development", {})
	var license_data = data.get("license", {})

	result = result.replace("{game.name}", str(game_data.get("name", "")))
	result = result.replace("{game.version}", str(game_data.get("version", "")))
	result = result.replace("{game.status}", str(game_data.get("status", "")))
	result = result.replace("{development.developer}", str(dev_data.get("developer", "")))
	result = result.replace("{development.studio}", str(dev_data.get("studio", "")))
	result = result.replace("{development.year}", str(dev_data.get("year", "")))
	result = result.replace("{development.ai_description}", str(dev_data.get("ai_description", "")))
	result = result.replace("{license.type}", str(license_data.get("type", "")))

	return result

# === MÉTODOS DE ACCESO ESTÁTICOS ===

static func get_game_title() -> String:
	"""Obtener título del juego"""
	var version_data = get_version_info()
	return version_data.get("game", {}).get("name", "Fishing SiKness")

static func get_version() -> String:
	"""Obtener versión del juego"""
	var version_data = get_version_info()
	return version_data.get("game", {}).get("version", "0.1.0")

static func get_company() -> String:
	"""Obtener nombre de la compañía/estudio"""
	var version_data = get_version_info()
	var dev_data = version_data.get("development", {})
	var developer = dev_data.get("developer", "Kava")
	var studio = dev_data.get("studio", "SiK Studio")
	return "%s - %s" % [developer, studio]

static func get_status() -> String:
	"""Obtener estado de desarrollo (alpha, beta, release)"""
	var version_data = get_version_info()
	return version_data.get("game", {}).get("status", "release")

static func get_build_number() -> int:
	"""Obtener número de build"""
	var version_data = get_version_info()
	return version_data.get("game", {}).get("build_number", 1)

static func is_ai_powered() -> bool:
	"""Verificar si el proyecto fue hecho con IA"""
	var version_data = get_version_info()
	return version_data.get("development", {}).get("ai_powered", true)
