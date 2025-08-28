extends Node

# Escaneo y registro de data/** - Compatible con exports empaquetados
class_name ContentIndex

func load_all():
	print("[ContentIndex] 🚀 Iniciando carga de recursos...")

	var catalogs = {
		"fish": [],
		"zones": [],
		"loot_tables": [],
		"equipment": [],
		"upgrades": [],
		"store": []
	}

	# Lista pre-definida de recursos para empaquetado
	# Se actualiza automáticamente en desarrollo, se usa como fallback en producción
	var predefined_resources = {
		"fish": [
			"fish_sardina.tres", "fish_trucha.tres", "fish_lubina.tres",
			"fish_calamar.tres", "fish_cangrejo.tres", "fish_langosta.tres",
			"fish_mantaraya.tres", "fish_pezglobo.tres", "fish_pulpo.tres",
			"fish_salmon.tres", "fish_pulpo_dorado.tres"
		],
		"zones": [
			"zone_orilla.tres", "zone_costa.tres", "zone_rio.tres", "zone_lago.tres",
			"zone_mar.tres", "zone_abismo.tres", "zone_glaciar.tres",
			"zone_industrial.tres", "zone_infernal.tres"
		],
		"loot_tables": [
			"entry_sardina.tres", "entry_trucha.tres", "entry_lubina.tres",
			"entry_calamar.tres", "entry_cangrejo.tres", "entry_langosta.tres",
			"entry_mantaraya.tres", "entry_pezglobo.tres", "entry_pulpo.tres",
			"entry_salmon.tres", "entry_pulpo_dorado.tres", "zone_orilla_table.tres"
		],
		"equipment": [
			"rod_basic.tres"
		],
		"upgrades": [],
		"store": []
	}

	print("[ContentIndex] 📋 Lista predefinida tiene %d categorías" % predefined_resources.size())

	var paths = {
		"fish": "res://data/fish",
		"zones": "res://data/zones",
		"loot_tables": "res://data/loot_tables",
		"equipment": "res://data/equipment",
		"upgrades": "res://data/upgrades",
		"store": "res://data/store"
	}
	var log_msgs = []

	for key in paths.keys():
		print("[ContentIndex] 🎯 Procesando categoría: %s" % key)

		# Determinar si estamos en desarrollo (directorio accesible) o empaquetado
		var dir = DirAccess.open(paths[key])
		var files_to_load = []
		var is_packaged = not dir

		print("[ContentIndex] DirAccess disponible: %s" % str(dir != null))

		if not is_packaged:
			# Intentar escanear directorio
			print("[ContentIndex] � Intentando escaneo de directorio...")
			dir.list_dir_begin()
			var file = dir.get_next()
			while file != "":
				if file.ends_with(".tres"):
					files_to_load.append(file)
				file = dir.get_next()
			dir.list_dir_end()
			print("[ContentIndex] Archivos encontrados en directorio: %d" % files_to_load.size())

			# Si no encontramos archivos, probablemente estamos empaquetados
			if files_to_load.size() == 0:
				print("[ContentIndex] 📦 No se encontraron archivos - forzando modo empaquetado")
				is_packaged = true

		if is_packaged:
			# Modo empaquetado: usar lista predefinida directamente
			print("[ContentIndex] � Modo empaquetado - usando lista predefinida")
			if predefined_resources.has(key):
				files_to_load = predefined_resources[key].duplicate()
				print("[ContentIndex] Lista predefinida para %s: %d archivos" % [key, files_to_load.size()])
				for f in files_to_load:
					print("[ContentIndex]   - %s" % f)
			else:
				print("[ContentIndex] ⚠️ No hay lista predefinida para: %s" % key)

		# Cargar archivos encontrados
		print("[ContentIndex] 🔄 Cargando %d archivos de %s..." % [files_to_load.size(), key])
		for i in range(files_to_load.size()):
			var file = files_to_load[i]
			var resource_path = "%s/%s" % [paths[key], file]
			print("[ContentIndex] Intentando cargar [%d/%d]: %s" % [i + 1, files_to_load.size(), resource_path])

			var res = ResourceLoader.load(resource_path)
			if res:
				catalogs[key].append(res)
				print("[ContentIndex] ✅ [%d/%d] Cargado: %s" % [i + 1, files_to_load.size(), file])

				# Validación específica para zonas
				if key == "zones" and res.get("id"):
					print("[ContentIndex]     └─ Zona ID: %s" % res.get("id"))

				# Validación mínima por tipo
				if key == "fish":
					if not res.has_method("get_id") and res.get("id") == null:
						log_msgs.append("[WARN] FishDef sin id: %s" % file)
				if key == "zones":
					if res.get("id") == null or res.get("price_multiplier") == null:
						log_msgs.append("[WARN] ZoneDef incompleto: %s" % file)

			else:
				print("[ContentIndex] ❌ [%d/%d] Error cargando: %s" % [i + 1, files_to_load.size(), resource_path])
				log_msgs.append("[ERROR] No se pudo cargar %s" % resource_path)

		print("[ContentIndex] ✅ Total cargado en %s: %d recursos" % [key, catalogs[key].size()])
	
	# Logging de avisos
	if log_msgs.size() > 0:
		var log_path = GamePaths.get_content_log() if GamePaths else "user://logs/content.log"
		var f = FileAccess.open(log_path, FileAccess.WRITE)
		if f:
			for msg in log_msgs:
				f.store_line(msg)
			f.close()
			print("[ContentIndex] 📝 Log guardado en: %s" % log_path)

	# Debug final
	print("[ContentIndex] 🎯 Resumen de carga:")
	for key in catalogs.keys():
		print("  - %s: %d recursos" % [key, catalogs[key].size()])
		if key == "zones" and catalogs[key].size() > 0:
			print("    Zonas encontradas:")
			for zone in catalogs[key]:
				if zone and zone.get("id"):
					print("      ✅ %s (%s)" % [zone.id, zone.name if zone.has_method("get") and zone.get("name") else "Sin nombre"])
				else:
					print("      ❌ Zona inválida")

	return catalogs
