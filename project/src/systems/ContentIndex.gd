extends Node

# Escaneo y registro de data/**
class_name ContentIndex

func load_all():
	var catalogs = {
		"fish": [],
		"zones": [],
		"loot_tables": [],
		"equipment": [],
		"upgrades": [],
		"store": []
	}
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
		var dir = DirAccess.open(paths[key])
		if dir:
			dir.list_dir_begin()
			var file = dir.get_next()
			while file != "":
				if file.ends_with(".tres"):
					var res = ResourceLoader.load("%s/%s" % [paths[key], file])
					if res:
						catalogs[key].append(res)
						# Validación mínima por tipo
						if key == "fish":
							if not res.has_method("get_id") and res.get("id") == null:
								log_msgs.append("[WARN] FishDef sin id: %s" % file)
						if key == "zones":
							if res.get("id") == null or res.get("price_multiplier") == null:
								log_msgs.append("[WARN] ZoneDef incompleto: %s" % file)
						# Se pueden añadir más validaciones por tipo
					else:
						log_msgs.append("[ERROR] No se pudo cargar %s/%s" % [paths[key], file])
				file = dir.get_next()
			dir.list_dir_end()
	# Logging de avisos
	if log_msgs.size() > 0:
		var log_path = "user://logs/content.log"
		var f = FileAccess.open(log_path, FileAccess.WRITE)
		if f:
			for msg in log_msgs:
				f.store_line(msg)
			f.close()
	return catalogs
