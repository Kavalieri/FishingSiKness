extends Node

# Sistema de guardado y migración
var save_path := "user://save.json"
var backup_path := "user://save.bak"
var schema := 2
var current_save_slot := 1

# Datos del juego en memoria
var game_data := {
	"schema": 2,
	"coins": 1000,
	"gems": 25,
	"zone": "orilla",
	"current_zone": "lake",
	"unlocked_zones": ["lake"],
	"max_inventory": 12,
	"upgrades": {},
	"equipment": {},
	"inventory": [],
	"purchases": [],
	"owned_cosmetics": [],
	"ad_cooldowns": {},
	"last_played": 0,
	# Nuevo sistema de experiencia
	"experience": 0,
	"level": 1,
	"milestone_bonuses": {
		"inventory_capacity": 0,
		"coins_multiplier": 0.0,
		"qte_time_bonus": 0.0,
		"rare_fish_chance": 0.0
	},
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
	load_game()

func get_coins() -> int:
	return game_data.get("coins", 0)

func get_gems() -> int:
	return game_data.get("gems", 0)

func get_inventory() -> Array:
	return game_data.get("inventory", [])

func add_fish(fish_instance: FishInstance):
	var inventory = get_inventory()
	inventory.append({
		"id": fish_instance.fish_def.id,
		"name": fish_instance.fish_def.name,
		"size": fish_instance.size,
		"value": fish_instance.value,
		"timestamp": fish_instance.timestamp
	})
	game_data.inventory = inventory
	save_game()
	print("Added fish to inventory: ", fish_instance.get_display_name())

func remove_fish(index: int) -> bool:
	var inventory = get_inventory()
	if index >= 0 and index < inventory.size():
		inventory.remove_at(index)
		game_data.inventory = inventory
		save_game()
		return true
	return false

func sell_fish(index: int) -> int:
	var inventory = get_inventory()
	if index >= 0 and index < inventory.size():
		var fish_data = inventory[index]
		var value = fish_data.get("value", 0)
		inventory.remove_at(index)
		game_data.inventory = inventory
		add_coins(value)
		return value
	return 0

func sell_fish_by_index(index: int) -> int:
	return sell_fish(index)

func sell_all_fish() -> int:
	var inventory = get_inventory()
	var total_value = 0

	for fish_data in inventory:
		total_value += fish_data.get("value", 0)

	game_data.inventory = []
	add_coins(total_value)
	return total_value

# Funciones de descarte (sin ganar dinero, solo para liberar espacio)
func discard_fish_by_index(index: int) -> bool:
	"""Descartar un pez por índice sin ganar dinero"""
	var inventory = get_inventory()
	if index >= 0 and index < inventory.size():
		inventory.remove_at(index)
		game_data.inventory = inventory
		save_game()
		return true
	return false

func discard_all_fish() -> int:
	"""Descartar todos los peces sin ganar dinero, retorna cantidad descartada"""
	var inventory = get_inventory()
	var discarded_count = inventory.size()

	game_data.inventory = []
	save_game()
	return discarded_count

func get_inventory_count() -> int:
	return get_inventory().size()

func get_max_inventory() -> int:
	return game_data.get("max_inventory", 12)

func add_coins(amount: int):
	game_data.coins += amount
	save_game()

func add_gems(amount: int):
	game_data.gems += amount
	save_game()

func spend_coins(amount: int) -> bool:
	if game_data.coins >= amount:
		game_data.coins -= amount
		save_game()
		return true
	return false

func spend_gems(amount: int) -> bool:
	if game_data.gems >= amount:
		game_data.gems -= amount
		save_game()
		return true
	return false

func save_game():
	save(game_data)

func load_game():
	var loaded_data = load_data()
	if loaded_data.size() > 0:
		game_data = loaded_data
		# Migrar datos si es necesario
		migrate_game_data()
	print("Game loaded: ", game_data.coins, " coins, ", game_data.gems, " gems")

func migrate_game_data():
	# Asegurar que existen todas las propiedades nuevas
	if not game_data.has("current_zone"):
		game_data.current_zone = "lake"
	if not game_data.has("unlocked_zones"):
		game_data.unlocked_zones = ["lake"]
	if not game_data.has("upgrades"):
		game_data.upgrades = {}
	if not game_data.has("max_inventory"):
		game_data.max_inventory = 12

func save(data: Dictionary):
	var tmp_path = save_path + ".tmp"
	var file = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.flush()
		file.close()
		# Renombrar a save.json
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove(save_path)
			dir.rename(tmp_path, save_path)
			# Copia de seguridad
			dir.remove(backup_path)
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

func migrate(data: Dictionary) -> Dictionary:
	var current_schema = data.get("schema", 1)

	# Migración de schema 1 a 2 (experiencia y prestigio)
	if current_schema == 1:
		data["experience"] = 0
		data["level"] = 1
		data["milestone_bonuses"] = {
			"inventory_capacity": 0,
			"coins_multiplier": 0.0,
			"qte_time_bonus": 0.0,
			"rare_fish_chance": 0.0
		}
		data["prestige_unlocked"] = false
		data["prestige_level"] = 0
		data["prestige_points"] = 0

	data.schema = schema
	return data

# Funciones de experiencia y milestone
func get_experience() -> int:
	return game_data.get("experience", 0)

func set_experience(xp: int, level: int):
	game_data.experience = xp
	game_data.level = level
	save_game()

func add_milestone_inventory(bonus: int):
	game_data.milestone_bonuses.inventory_capacity += bonus
	save_game()

func add_milestone_coins_multiplier(bonus: float):
	game_data.milestone_bonuses.coins_multiplier += bonus
	save_game()

func add_milestone_qte_time(bonus: float):
	game_data.milestone_bonuses.qte_time_bonus += bonus
	save_game()

func add_milestone_rare_chance(bonus: float):
	game_data.milestone_bonuses.rare_fish_chance += bonus
	save_game()

func unlock_prestige():
	game_data.prestige_unlocked = true
	save_game()

func get_total_inventory_capacity() -> int:
	return game_data.get("max_inventory", 12) + game_data.milestone_bonuses.inventory_capacity

func get_coins_multiplier() -> float:
	return 1.0 + game_data.milestone_bonuses.coins_multiplier

# Sistema de guardado múltiple
func get_save_slot_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot

func save_to_slot(slot: int):
	current_save_slot = slot
	save_path = get_save_slot_path(slot)
	backup_path = "user://save_slot_%d.bak" % slot
	save_game()

func load_from_slot(slot: int):
	current_save_slot = slot
	save_path = get_save_slot_path(slot)
	backup_path = "user://save_slot_%d.bak" % slot
	load_game()

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

	return {
		"exists": true,
		"empty": false,
		"coins": data.get("coins", 0),
		"gems": data.get("gems", 0),
		"level": data.get("level", 1),
		"zone": data.get("current_zone", "lake"),
		"last_played": data.get("last_played", 0),
		"playtime": _format_playtime(data.get("last_played", 0))
	}

func delete_save_slot(slot: int):
	var slot_path = get_save_slot_path(slot)
	var backup_slot_path = "user://save_slot_%d.bak" % slot

	var dir = DirAccess.open("user://")
	if dir:
		dir.remove(slot_path)
		dir.remove(backup_slot_path)

func _format_playtime(timestamp: int) -> String:
	if timestamp == 0:
		return "Nueva partida"

	var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
	return "%02d/%02d/%d %02d:%02d" % [
		datetime.day, datetime.month, datetime.year,
		datetime.hour, datetime.minute
	]

func reset_to_default():
	"""Resetear datos del juego a valores por defecto"""
	game_data = {
		"schema": 2,
		"coins": 1000,
		"gems": 25,
		"zone": "orilla",
		"current_zone": "lake",
		"unlocked_zones": ["lake"],
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
		"prestige_unlocked": false,
		"prestige_level": 0,
		"prestige_points": 0,
		"settings": {
			"vibration": true,
			"sfx": 0.8,
			"music": 0.4
		}
	}
