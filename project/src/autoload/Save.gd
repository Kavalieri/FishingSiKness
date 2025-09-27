extends Node

# Señales para notificar cambios importantes
signal data_loaded(slot: int)
signal data_saved(slot: int)
signal coins_changed(new_amount: int)
signal gems_changed(new_amount: int)
signal game_data_changed() # Nueva señal para actualización completa de UI
signal inventory_changed() # Nueva señal para actualización de inventario

# Sistema de guardado y migración - UNIFICADO con slots
var schema := 2
var current_save_slot := 1
var max_save_slots := 5

# Rutas unificadas
func get_save_path(slot: int) -> String:
	return "user://savegame/save_slot_%d.json" % slot

func get_current_save_path() -> String:
	return get_save_path(current_save_slot)

func get_backup_path(slot: int) -> String:
	return "user://savegame/save_slot_%d.bak" % slot

func _ensure_save_directory():
	"""Crear directorio de guardado si no existe"""
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("savegame"):
		var result = dir.make_dir("savegame")
		if result == OK:
			print("📁 Directorio savegame/ creado exitosamente")
		else:
			print("ERROR Error creando directorio savegame/: %d" % result)
	else:
		print("📁 Directorio savegame/ ya existe")

func has_valid_game_data() -> bool:
	"""Verifica si hay datos válidos de juego en memoria para guardar"""
	return game_data != null and game_data.has("schema") and game_data.schema > 0

# Datos del juego en memoria
var game_data := {
	"schema": 2,
	"coins": 1000,
	"gems": 25,
	"zone": "lago_montana_alpes",
	"current_zone": "lago_montana_alpes",
	"unlocked_zones": ["lago_montana_alpes"],
	"max_inventory": 12,
	"upgrades": {},
	"equipment": {},
	"inventory": [],
	"purchases": [],
	"owned_cosmetics": [],
	"ad_cooldowns": {},
	"last_played": 0,
	"experience": 0,
	"level": 1,
	"milestone_bonuses": {
		"inventory_capacity": 0,
		"coins_multiplier": 0.0,
		"qte_time_bonus": 0.0,
		"rare_fish_chance": 0.0
	},
	"unlocked_skills": {},
	"prestige_unlocked": false,
	"prestige_level": 0,
	"prestige_points": 0,
	"settings": {
		"vibration": true,
		"sfx": 0.8,
		"music": 0.4
	},
	"catches_database": [] # Base de datos unificada de todas las capturas
}

func _ready():
	# Crear directorio de guardado
	_ensure_save_directory()

	# Verificar si existe algún save, si no, crear slot 1
	_ensure_initial_save()

	# Cargar último slot usado
	load_last_used_slot()
	load_game()
	# ELIMINADO: _ensure_initial_data() que creaba peces automáticamente

	# Guardar automáticamente cuando se cierre el juego
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false

	# Timer para guardado automático cada 30 segundos
	var auto_save_timer = Timer.new()
	auto_save_timer.wait_time = 30.0
	auto_save_timer.autostart = true
	auto_save_timer.timeout.connect(_auto_save)
	add_child(auto_save_timer)

func _ensure_initial_save():
	"""Crear el slot 1 si no existe ningún save"""
	var has_any_save = false

	for slot in range(1, max_save_slots + 1):
		var slot_path = get_save_path(slot)
		if FileAccess.file_exists(slot_path):
			has_any_save = true
			break

	if not has_any_save:
		print("📝 No se encontraron saves existentes, creando slot 1 inicial...")
		current_save_slot = 1
		save_to_slot(1)
		save_last_used_slot()
		print("OK Slot 1 inicial creado exitosamente")

func load_last_used_slot():
	"""Cargar el último slot usado desde settings"""
	var settings_file = FileAccess.open("user://savegame/last_slot.cfg", FileAccess.READ)
	if settings_file:
		var last_slot = settings_file.get_var()
		settings_file.close()
		if typeof(last_slot) == TYPE_INT and last_slot >= 1 and last_slot <= max_save_slots:
			current_save_slot = last_slot
			print("TARGET Cargando último slot usado: %d" % current_save_slot)
		else:
			print("⚠️ Slot inválido en last_slot.cfg, usando slot 1")
	else:
		print("📁 No hay last_slot.cfg, usando slot 1 por defecto")

func save_last_used_slot():
	"""Guardar el slot actual como último usado"""
	var settings_file = FileAccess.open("user://savegame/last_slot.cfg", FileAccess.WRITE)
	if settings_file:
		settings_file.store_var(current_save_slot)
		settings_file.close()
		print("💾 Guardado último slot usado: %d" % current_save_slot)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("Auto-saving before quit...")
		save_game()
		get_tree().quit()

func _auto_save():
	"""Guardado automático periódico"""
	print("[Save] Auto-save triggered")
	if has_valid_game_data():
		save_game()
		print("[Save] Auto-save completed")
	else:
		print("[Save] Auto-save skipped - no valid data")

# ELIMINADO: _ensure_initial_data() - ya no creamos peces automáticamente

# --- Funciones de Moneda ---

func get_coins() -> int:
	return game_data.get("coins", 0)

func get_gems() -> int:
	return game_data.get("gems", 0)

func add_coins(amount: int, do_save: bool = true):
	game_data.coins += amount
	coins_changed.emit(game_data.coins)
	if do_save:
		save_game()

func add_gems(amount: int, do_save: bool = true):
	game_data.gems += amount
	gems_changed.emit(game_data.gems)
	if do_save:
		save_game()

func spend_coins(amount: int, do_save: bool = true) -> bool:
	if game_data.coins >= amount:
		game_data.coins -= amount
		coins_changed.emit(game_data.coins)
		if do_save:
			save_game()
		return true
	return false

func spend_gems(amount: int, do_save: bool = true) -> bool:
	if game_data.gems >= amount:
		game_data.gems -= amount
		gems_changed.emit(game_data.gems)
		if do_save:
			save_game()
		return true
	return false

# --- Experiencia y Nivel ---

func get_experience() -> int:
	return game_data.get("experience", 0)

func set_experience(xp: int, level: int, do_save: bool = true):
	game_data.experience = xp
	game_data.level = level
	if do_save:
		save_game()

# --- Sistema de Guardado y Carga ---

func save_game():
	# Antes de guardar, sincronizar el inventario desde UnifiedInventorySystem
	if UnifiedInventorySystem:
		game_data.inventory = UnifiedInventorySystem.get_inventory_for_saving()

	# Actualizar timestamp
	game_data.last_played = Time.get_unix_time_from_system()
	print("[Save] Guardando en slot %d, timestamp: %s" % [current_save_slot, Time.get_datetime_string_from_system()])

	save(game_data)
	print("[Save] Guardado completado")

func load_game():
	var loaded_data = load_data()
	if loaded_data.size() > 0:
		game_data = loaded_data
		migrate_game_data()

	# Cargar inventario de manera diferida para asegurar que UnifiedInventorySystem esté listo
	call_deferred("_load_inventory_deferred")

	print("Game loaded: ", game_data.coins, " coins, ", game_data.gems, " gems")

func _load_inventory_deferred():
	"""Cargar inventario de manera diferida para evitar problemas de timing"""
	print("[Save] Cargando inventario de manera diferida...")
	if UnifiedInventorySystem and UnifiedInventorySystem.has_method("load_from_save"):
		UnifiedInventorySystem.load_from_save(game_data.get("inventory", []))
	else:
		print("[Save] ERROR: UnifiedInventorySystem no está disponible para carga diferida")

func save(data: Dictionary):
	var current_save_path = get_current_save_path()
	var current_backup_path = get_backup_path(current_save_slot)
	var tmp_path = current_save_path + ".tmp"

	var file = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.flush()
		file.close()
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove(current_save_path)
			dir.rename(tmp_path, current_save_path)
			dir.copy(current_save_path, current_backup_path)

func load_data() -> Dictionary:
	var current_save_path = get_current_save_path()
	var file = FileAccess.open(current_save_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var data = JSON.parse_string(content)
		if typeof(data) == TYPE_DICTIONARY:
			return migrate(data)
	return {}

func migrate_game_data():
	# Asegurar que existen todas las propiedades nuevas
	if not game_data.has("current_zone"):
		game_data.current_zone = "lago_montana_alpes"
	# ... (otras migraciones)

func migrate(data: Dictionary) -> Dictionary:
	var current_schema = data.get("schema", 1)
	if current_schema == 1:
		data["experience"] = 0
		data["level"] = 1
		# ... (otras migraciones de schema)
	data.schema = schema
	return data

# --- Otras Funciones de Datos ---

func get_total_inventory_capacity() -> int:
	var base_inventory = game_data.get("max_inventory", 12)
	var milestone_bonus = game_data.get("milestone_bonuses", {}).get("inventory_capacity", 0)
	var skill_bonus = 0
	if SkillTree:
		skill_bonus = SkillTree.get_max_inventory_with_bonus() - base_inventory
	return base_inventory + milestone_bonus + skill_bonus

# ... (otras funciones de acceso a datos como multipliers, etc.)

# --- Sistema de guardado múltiple ---

func get_save_slot_path(slot: int) -> String:
	return get_save_path(slot)  # Usar la función unificada

func save_to_slot(slot: int):
	current_save_slot = slot
	save_last_used_slot() # Recordar slot actual
	save_game()
	# Emitir señal para notificar guardado
	data_saved.emit(slot)

func load_from_slot(slot: int):
	current_save_slot = slot
	save_last_used_slot() # Recordar slot actual
	load_game()

	# Forzar actualización de Experience
	if Experience:
		Experience.load_experience()

	# Emitir múltiples señales para actualización completa de UI
	data_loaded.emit(slot)
	game_data_changed.emit()
	inventory_changed.emit()
	coins_changed.emit(get_coins())
	gems_changed.emit(get_gems())

	print("REFRESH Datos cargados completamente desde Slot %d" % slot)

func get_save_slot_info(slot: int) -> Dictionary:
	var slot_path = get_save_path(slot) # Usar función correcta
	var file = FileAccess.open(slot_path, FileAccess.READ)
	if not file:
		return {"exists": false, "empty": true}
	var content = file.get_as_text()
	file.close()
	var data = JSON.parse_string(content)
	if typeof(data) != TYPE_DICTIONARY:
		return {"exists": false, "empty": true}

	# Calcular nivel real basado en experiencia o upgrades
	var level = data.get("level", 1)
	var experience = data.get("experience", 0)
	
	# DEBUG: Mostrar datos del slot
	print("[Save] Slot %d - Level guardado: %s, XP: %s" % [slot, level, experience])
	
	# Si no hay experiencia pero hay upgrades, calcular nivel basado en upgrades
	if experience == 0 and data.has("upgrades"):
		var upgrades_data = data.upgrades
		var total_upgrade_levels = 0
		for upgrade_id in upgrades_data:
			total_upgrade_levels += upgrades_data[upgrade_id]
			print("[Save] Upgrade %s: nivel %s" % [upgrade_id, upgrades_data[upgrade_id]])
		
		if total_upgrade_levels > 0:
			experience = total_upgrade_levels * 10  # 10 XP por nivel de upgrade
			# Calcular nivel desde XP: nivel = sqrt(xp / 100) + 1
			level = max(1, int(sqrt(experience / 100.0)) + 1)
			print("[Save] Slot %d calculado: %d upgrades = %d XP = nivel %d" % [slot, total_upgrade_levels, experience, level])
	else:
		print("[Save] Slot %d usando nivel guardado: %d" % [slot, level])
	var estimated_playtime = _calculate_playtime(level, experience)

	# Calcular valor total de peces en inventario
	var inventory_data = data.get("inventory", [])
	var total_fish_value = 0
	var fish_count = 0
	for fish in inventory_data:
		if fish.has("value"):
			total_fish_value += fish.value
			fish_count += 1

	# Formatear fecha de último guardado
	var last_played_timestamp = data.get("last_played", 0)
	var last_played_str = "Nunca"
	if last_played_timestamp > 0:
		var datetime = Time.get_datetime_dict_from_unix_time(last_played_timestamp)
		last_played_str = "%02d/%02d/%d %02d:%02d" % [datetime.day, datetime.month, datetime.year, datetime.hour, datetime.minute]

	return {
		"exists": true,
		"empty": false,
		"coins": data.get("coins", 0),
		"gems": data.get("gems", 0),
		"level": level,
		"experience": experience,
		"zone": _get_zone_display_name(data.get("current_zone", "lago_montana_alpes")),
		"playtime": estimated_playtime,
		"last_played": last_played_timestamp,
		"last_played_str": last_played_str,
		"fish_count": fish_count,
		"fish_value": total_fish_value
	}

func _calculate_playtime(level: int, experience: int) -> String:
	# Estimación muy básica del tiempo de juego basada en progreso
	var total_minutes = (level - 1) * 15 + (experience / 100) * 5
	if total_minutes < 60:
		return "%d min" % total_minutes
	else:
		var hours = total_minutes / 60
		var minutes = int(total_minutes) % 60
		return "%dh %dm" % [hours, minutes]

func _get_zone_display_name(zone_id: String) -> String:
	var zone_names = {
		"lago_montana_alpes": "Lagos de Montaña - Alpes",
		"grandes_lagos_norteamerica": "Grandes Lagos de Norteamérica",
		"costas_atlanticas": "Costas Atlánticas",
		"rios_amazonicos": "Ríos Amazónicos",
		"oceanos_profundos": "Océanos Profundos",
		"orilla": "Orilla",
		"lago": "Lago",
		"rio": "Río",
		"costa": "Costa",
		"mar": "Mar",
		"glaciar": "Glaciar",
		"industrial": "Industrial",
		"abismo": "Abismo",
		"infernal": "Infernal"
	}
	return zone_names.get(zone_id, zone_id.capitalize())

func delete_save_slot(slot: int):
	var slot_path = get_save_path(slot)
	var backup_path = get_backup_path(slot)
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove(slot_path)
		dir.remove(backup_path)
	print("[Save] Slot %d eliminado: %s" % [slot, slot_path])

func reset_to_default():
	"""Resetear game_data a valores por defecto para nueva partida"""
	game_data = {
		"schema": 2,
		"coins": 1000,
		"gems": 25,
		"zone": "lago_montana_alpes",
		"current_zone": "lago_montana_alpes",
		"unlocked_zones": ["lago_montana_alpes"],
		"max_inventory": 12,
		"upgrades": {},
		"equipment": {},
		"inventory": [],
		"purchases": [],
		"owned_cosmetics": [],
		"ad_cooldowns": {},
		"last_played": Time.get_unix_time_from_system(),
		"experience": 0,
		"level": 1,
		"milestone_bonuses": {
			"inventory_capacity": 0,
			"coins_multiplier": 0.0,
			"qte_time_bonus": 0.0,
			"rare_fish_chance": 0.0
		},
		"unlocked_skills": {},
		"prestige_unlocked": false,
		"prestige_level": 0,
		"prestige_points": 0,
		"settings": {
			"vibration": true,
			"sfx": 0.8,
			"music": 0.4
		},
		"catches_database": []
	}

	# Limpiar también el inventario del sistema
	if UnifiedInventorySystem:
		UnifiedInventorySystem.clear_all_containers()

	# ELIMINADO: _ensure_initial_data() - ya no creamos peces automáticamente

	# Emitir señal de datos cargados
	data_loaded.emit(current_save_slot)


# ========== BASE DE DATOS DE CAPTURAS ==========

func add_catch_to_database(fish_data: Dictionary) -> String:
	"""Agregar captura a la base de datos y retornar ID único"""
	print("[Save] === AGREGANDO CAPTURA A BD ===")
	print("[Save] Fish data recibido: %s" % str(fish_data))
	
	if not game_data.has("catches_database"):
		game_data["catches_database"] = []
		print("[Save] Inicializando catches_database")

	# Generar ID único para la captura
	var catch_id = "catch_%d_%d" % [Time.get_unix_time_from_system(), randi()]

	# Crear entrada completa en la base de datos
	var catch_entry = {
		"id": catch_id,
		"fish_name": fish_data.get("name", "Pez Desconocido"),
		"fish_id": fish_data.get("id", "unknown"),
		"size": fish_data.get("size", 0.0),
		"weight": fish_data.get("weight", 0.0),
		"value": fish_data.get("value", 0),
		"rarity": fish_data.get("rarity", "común"),
		"zone_caught": fish_data.get("zone_caught", "desconocido"),
		"timestamp": Time.get_unix_time_from_system(),
		"date_caught": Time.get_datetime_dict_from_system(),
		"is_sold": false,
		"sold_timestamp": 0,
		"sold_price": 0,
		"in_inventory": true
	}

	print("[Save] Entrada creada: %s" % str(catch_entry))

	# Agregar al principio del array (más reciente primero)
	game_data["catches_database"].push_front(catch_entry)
	print("[Save] Total capturas en BD: %d" % game_data["catches_database"].size())

	# Emitir señal de cambio
	inventory_changed.emit()

	print("[Save] Captura agregada exitosamente: %s (ID: %s)" % [fish_data.get("name", "Unknown"), catch_id])
	return catch_id

func mark_catch_as_sold(catch_id: String, sold_price: int) -> bool:
	"""Marcar captura como vendida"""
	if not game_data.has("catches_database"):
		return false

	for catch_entry in game_data["catches_database"]:
		if catch_entry.get("id") == catch_id:
			catch_entry["is_sold"] = true
			catch_entry["sold_timestamp"] = Time.get_unix_time_from_system()
			catch_entry["sold_price"] = sold_price
			catch_entry["in_inventory"] = false
			print("📊 [Save] Captura marcada como vendida: %s por %d" % [catch_entry.get("fish_name"), sold_price])
			return true

	return false

func get_catches_in_inventory() -> Array[Dictionary]:
	"""Obtener solo capturas que están en inventario (no vendidas)"""
	print("[Save] === OBTENIENDO CAPTURAS EN INVENTARIO ===")
	
	if not game_data.has("catches_database"):
		print("[Save] No existe catches_database")
		return []

	print("[Save] Total capturas en BD: %d" % game_data["catches_database"].size())
	
	var inventory_catches = []
	for catch_entry in game_data["catches_database"]:
		var is_sold = catch_entry.get("is_sold", false)
		var in_inventory = catch_entry.get("in_inventory", true)
		print("[Save] Captura: %s | Vendido: %s | En inventario: %s" % [catch_entry.get("fish_name"), is_sold, in_inventory])
		
		if in_inventory and not is_sold:
			inventory_catches.append(catch_entry)
			print("[Save] -> Añadida al inventario")
		else:
			print("[Save] -> Excluida del inventario")

	print("[Save] Capturas en inventario: %d" % inventory_catches.size())
	return inventory_catches

func get_recent_catches(max_entries: int = 20) -> Array[Dictionary]:
	"""Obtener capturas recientes (todas, vendidas o no)"""
	if not game_data.has("catches_database"):
		return []

	var database = game_data["catches_database"]
	if max_entries > 0 and database.size() > max_entries:
		return database.slice(0, max_entries)

	return database

func get_catch_by_id(catch_id: String) -> Dictionary:
	"""Obtener captura específica por ID"""
	if not game_data.has("catches_database"):
		return {}

	for catch_entry in game_data["catches_database"]:
		if catch_entry.get("id") == catch_id:
			return catch_entry

	return {}

func get_catch_stats() -> Dictionary:
	"""Obtener estadísticas completas de capturas"""
	if not game_data.has("catches_database"):
		return {"total_catches": 0, "total_value_caught": 0, "total_value_sold": 0, "most_common_fish": ""}

	var database = game_data["catches_database"]
	var stats = {
		"total_catches": database.size(),
		"total_value_caught": 0,
		"total_value_sold": 0,
		"catches_sold": 0,
		"catches_in_inventory": 0,
		"fish_counts": {},
		"most_common_fish": "",
		"rarity_counts": {},
		"zone_counts": {}
	}

	for catch_entry in database:
		# Sumar valor capturado
		stats["total_value_caught"] += catch_entry.get("value", 0)

		# Estadísticas de venta
		if catch_entry.get("is_sold", false):
			stats["catches_sold"] += 1
			stats["total_value_sold"] += catch_entry.get("sold_price", 0)
		else:
			stats["catches_in_inventory"] += 1

		# Contar peces por nombre
		var fish_name = catch_entry.get("fish_name", "Desconocido")
		stats["fish_counts"][fish_name] = stats["fish_counts"].get(fish_name, 0) + 1

		# Contar por rareza
		var rarity = catch_entry.get("rarity", "común")
		stats["rarity_counts"][rarity] = stats["rarity_counts"].get(rarity, 0) + 1

		# Contar por zona
		var zone = catch_entry.get("zone_caught", "desconocido")
		stats["zone_counts"][zone] = stats["zone_counts"].get(zone, 0) + 1

	# Encontrar pez más común
	var max_count = 0
	for fish_name in stats["fish_counts"]:
		if stats["fish_counts"][fish_name] > max_count:
			max_count = stats["fish_counts"][fish_name]
			stats["most_common_fish"] = fish_name

	return stats

# Método de compatibilidad
func add_catch_to_history(fish_data: Dictionary) -> void:
	"""Método de compatibilidad - redirige a add_catch_to_database"""
	add_catch_to_database(fish_data)

func get_catch_history(max_entries: int = 20) -> Array[Dictionary]:
	"""Método de compatibilidad - redirige a get_recent_catches"""
	return get_recent_catches(max_entries)

# ========== FUNCIONES DE MILESTONE ==========

func add_milestone_inventory(bonus: int) -> void:
	"""Añadir bonus de inventario por milestone"""
	game_data["milestone_bonuses"]["inventory_capacity"] += bonus
	print("[Save] Milestone: +%d inventario (total: %d)" % [bonus, game_data["milestone_bonuses"]["inventory_capacity"]])

func add_milestone_coins_multiplier(bonus: float) -> void:
	"""Añadir multiplicador de monedas por milestone"""
	game_data["milestone_bonuses"]["coins_multiplier"] += bonus
	print("[Save] Milestone: +%.1f%% monedas (total: %.1f%%)" % [bonus * 100, game_data["milestone_bonuses"]["coins_multiplier"] * 100])

func add_milestone_qte_time(bonus: float) -> void:
	"""Añadir tiempo extra de QTE por milestone"""
	game_data["milestone_bonuses"]["qte_time_bonus"] += bonus
	print("[Save] Milestone: +%.1fs QTE (total: %.1fs)" % [bonus, game_data["milestone_bonuses"]["qte_time_bonus"]])

func add_milestone_rare_chance(bonus: float) -> void:
	"""Añadir probabilidad de peces raros por milestone"""
	game_data["milestone_bonuses"]["rare_fish_chance"] += bonus
	print("[Save] Milestone: +%.1f%% peces raros (total: %.1f%%)" % [bonus * 100, game_data["milestone_bonuses"]["rare_fish_chance"] * 100])

func unlock_prestige() -> void:
	"""Desbloquear sistema de prestigio"""
	game_data["prestige_unlocked"] = true
	print("[Save] Milestone: Prestigio desbloqueado")
