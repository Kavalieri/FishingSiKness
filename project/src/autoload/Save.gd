extends Node

# Señales para notificar cambios importantes
signal data_loaded(slot: int)
signal data_saved(slot: int)
signal coins_changed(new_amount: int)
signal gems_changed(new_amount: int)

# Sistema de guardado y migración
var save_path: String
var backup_path: String
var schema := 2
var current_save_slot := 1

# Datos del juego en memoria
var game_data := {
	"schema": 2,
	"coins": 1000,
	"gems": 25,
	"zone": "orilla",
	"current_zone": "orilla",
	"unlocked_zones": ["orilla"],
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
	}
}

func _ready():
	print("[Save] Inicializando sistema de guardado...")
	
	# Esperar a que GamePaths esté listo
	if not GamePaths:
		await get_tree().process_frame
	
	# Configurar rutas usando GamePaths
	save_path = GamePaths.get_save_file()
	backup_path = GamePaths.get_save_backup()
	
	print("[Save] Rutas configuradas:")
	print("  - Save: %s" % save_path)
	print("  - Backup: %s" % backup_path)
	
	load_current_save_slot()
	load_game_data()

	# Guardar automáticamente cuando se cierre el juego
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false

	# Timer para guardado automático cada 30 segundos
	var auto_save_timer = Timer.new()
	auto_save_timer.wait_time = 30.0
	auto_save_timer.autostart = true
	auto_save_timer.timeout.connect(_auto_save)
	add_child(auto_save_timer)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("Auto-saving before quit...")
		save_game()
		get_tree().quit()

func _auto_save():
	"""Guardado automático periódico"""
	print("Auto-save triggered")
	save_game()

func _ensure_initial_data():
	# Asegurar que tenemos algunos peces de prueba si el inventario está vacío
	if InventorySystem.get_inventory_count() == 0 and Content:
		print("Save: Generando peces de prueba...")
		var sardina_def = Content.get_fish_by_id("sardina")
		if sardina_def:
			# Crear una instancia básica
			var fish_data = {
				"id": sardina_def.id,
				"name": sardina_def.name,
				"size": 12.0,
				"value": sardina_def.base_market_value,
				"capture_zone_id": "orilla",
				"zone_multiplier": 1.0,
				"capture_timestamp": Time.get_datetime_string_from_system(),
				"weight": 1.2,
				"rarity": sardina_def.rarity,
				"rarity_color": "#FFFFFF",
				"species_category": sardina_def.species_category,
				"description": sardina_def.description,
				"timestamp": Time.get_unix_time_from_system()
			}
			InventorySystem._inventory.append(fish_data)
			print("✅ Pez de prueba añadido al inventario")

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
	# Antes de guardar, sincronizar el inventario desde InventorySystem
	if InventorySystem:
		game_data.inventory = InventorySystem.get_inventory_for_saving()

	# Actualizar timestamp
	game_data.last_played = Time.get_unix_time_from_system()

	save(game_data)

func load_game():
	var loaded_data = load_data()
	if loaded_data.size() > 0:
		game_data = loaded_data
		migrate_game_data()

	# Después de cargar, poblar el inventario en InventorySystem
	if InventorySystem:
		InventorySystem.load_from_save(game_data.get("inventory", []))

	print("Game loaded: ", game_data.coins, " coins, ", game_data.gems, " gems")

func save(data: Dictionary):
	var tmp_path = save_path + ".tmp"
	var file = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.flush()
		file.close()
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove(save_path)
			dir.rename(tmp_path, save_path)
			dir.copy(save_path, backup_path)

func load_data() -> Dictionary:
	var file = FileAccess.open(save_path, FileAccess.READ)
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
		game_data.current_zone = "orilla"
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
	return "user://save_slot_%d.json" % slot

func save_to_slot(slot: int):
	current_save_slot = slot
	save_path = get_save_slot_path(slot)
	backup_path = "user://save_slot_%d.bak" % slot
	save_game()
	# Emitir señal para notificar guardado
	data_saved.emit(slot)

func load_from_slot(slot: int):
	current_save_slot = slot
	save_path = get_save_slot_path(slot)
	backup_path = "user://save_slot_%d.bak" % slot
	load_game()
	# Emitir señal para que otros sistemas se actualicen
	data_loaded.emit(slot)

func get_save_slot_info(slot: int) -> Dictionary:
	var slot_path = get_save_slot_path(slot)
	var file = FileAccess.open(slot_path, FileAccess.READ)
	if not file:
		return {"exists": false, "empty": true}
	var content = file.get_as_text()
	file.close()
	var data = JSON.parse_string(content)
	if typeof(data) != TYPE_DICTIONARY:
		return {"exists": false, "empty": true}

	# Calcular tiempo de juego aproximado basado en nivel y experiencia
	var level = data.get("level", 1)
	var experience = data.get("experience", 0)
	var estimated_playtime = _calculate_playtime(level, experience)

	return {
		"exists": true,
		"empty": false,
		"coins": data.get("coins", 0),
		"gems": data.get("gems", 0),
		"level": level,
		"experience": experience,
		"zone": _get_zone_display_name(data.get("current_zone", "orilla")),
		"playtime": estimated_playtime,
		"last_played": data.get("last_played", 0)
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
	var slot_path = get_save_slot_path(slot)
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove(slot_path)

func reset_to_default():
	"""Resetear game_data a valores por defecto para nueva partida"""
	game_data = {
		"schema": 2,
		"coins": 1000,
		"gems": 25,
		"zone": "orilla",
		"current_zone": "orilla",
		"unlocked_zones": ["orilla"],
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
		}
	}

	# Limpiar también el inventario del sistema
	if InventorySystem:
		InventorySystem._inventory.clear()

	# Asegurar datos iniciales
	_ensure_initial_data()
