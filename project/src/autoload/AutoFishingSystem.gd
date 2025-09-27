extends Node

signal auto_fishing_toggled(enabled: bool)
signal auto_catch_made(fish_data: Dictionary)

var is_auto_fishing: bool = false
var auto_fishing_unlocked: bool = false
var auto_timer: Timer
var current_zone: String = ""

# Configuración de filtros
var filters: Dictionary = {
	"min_rarity": "común",
	"min_value": 0,
	"min_size": 0.0,
	"auto_sell": false
}

const RARITY_VALUES = {"común": 1, "rara": 2, "épica": 3, "legendaria": 4}
const AUTO_FISHING_INTERVAL = 8.0  # 8 segundos por auto-pesca

func _ready() -> void:
	_setup_auto_timer()
	_load_auto_fishing_data()

func _setup_auto_timer() -> void:
	auto_timer = Timer.new()
	auto_timer.wait_time = AUTO_FISHING_INTERVAL
	auto_timer.timeout.connect(_perform_auto_cast)
	add_child(auto_timer)

func _load_auto_fishing_data() -> void:
	if not Save:
		return
	
	auto_fishing_unlocked = Save.game_data.get("auto_fishing_unlocked", false)
	filters = Save.game_data.get("auto_fishing_filters", filters)
	
	# Verificar desbloqueo por nivel
	if Experience and Experience.current_level >= 10:
		auto_fishing_unlocked = true
		Save.game_data.auto_fishing_unlocked = true

func is_unlocked() -> bool:
	return auto_fishing_unlocked

func unlock_auto_fishing() -> void:
	auto_fishing_unlocked = true
	if Save:
		Save.game_data.auto_fishing_unlocked = true
	print("[AutoFishing] Auto-pesca desbloqueada!")

func toggle_auto_fishing() -> void:
	if not auto_fishing_unlocked:
		print("[AutoFishing] Auto-pesca no desbloqueada")
		return
	
	is_auto_fishing = !is_auto_fishing
	
	if is_auto_fishing:
		_start_auto_fishing()
	else:
		_stop_auto_fishing()
	
	auto_fishing_toggled.emit(is_auto_fishing)

func _start_auto_fishing() -> void:
	if not EnergySystem or not EnergySystem.can_cast():
		is_auto_fishing = false
		auto_fishing_toggled.emit(false)
		return
	
	auto_timer.start()
	print("[AutoFishing] Auto-pesca iniciada")

func _stop_auto_fishing() -> void:
	auto_timer.stop()
	print("[AutoFishing] Auto-pesca detenida")

func _perform_auto_cast() -> void:
	if not is_auto_fishing:
		return
	
	# Verificar energía
	if not EnergySystem or not EnergySystem.can_cast():
		_stop_auto_fishing()
		is_auto_fishing = false
		auto_fishing_toggled.emit(false)
		return
	
	# Consumir energía
	if not EnergySystem.consume_energy():
		return
	
	# Registrar lanzamiento
	if StatsTracker:
		StatsTracker.record_cast()
	
	# Simular pesca (70% éxito en auto-pesca)
	var success_chance = 0.7
	if randf() <= success_chance:
		_auto_catch_fish()
	else:
		if StatsTracker:
			StatsTracker.record_fish_escaped()

func _auto_catch_fish() -> void:
	# Generar pez usando el sistema existente
	var fish_data = _generate_auto_fish()
	
	if not fish_data.is_empty():
		# Aplicar filtros
		if _passes_filters(fish_data):
			_process_auto_catch(fish_data)
		else:
			print("[AutoFishing] Pez descartado por filtros: %s" % fish_data.get("name", "Unknown"))

func _generate_auto_fish() -> Dictionary:
	# Usar Content system si está disponible
	if Content and Content.has_method("get_random_fish_for_zone"):
		var zone_id = Save.game_data.get("current_zone", "lago_montana_alpes")
		var fish_data = Content.get_random_fish_for_zone(zone_id)
		if fish_data:
			return fish_data
	
	# Fallback: sistema básico
	var fish_names = ["sardina", "trucha", "salmon", "lubina"]
	var rarities = ["común", "rara", "épica", "legendaria"]
	var weights = [70.0, 20.0, 8.0, 2.0]
	
	var rand = randf() * 100.0
	var accumulated = 0.0
	var selected_rarity = "común"
	
	for i in range(weights.size()):
		accumulated += weights[i]
		if rand <= accumulated:
			selected_rarity = rarities[i]
			break
	
	var fish_name = fish_names[randi() % fish_names.size()]
	var base_value = randi_range(10, 100)
	var rarity_multiplier = 1.0
	
	match selected_rarity:
		"común": rarity_multiplier = 1.0
		"rara": rarity_multiplier = 1.5
		"épica": rarity_multiplier = 2.5
		"legendaria": rarity_multiplier = 5.0
	
	return {
		"id": fish_name,
		"name": fish_name.capitalize(),
		"rarity": selected_rarity,
		"value": int(base_value * rarity_multiplier),
		"size": randf_range(10.0, 50.0),
		"zone_caught": Save.game_data.get("current_zone", "lago_montana_alpes")
	}

func _passes_filters(fish_data: Dictionary) -> bool:
	# Filtro de rareza
	var fish_rarity = fish_data.get("rarity", "común")
	var min_rarity = filters.get("min_rarity", "común")
	if RARITY_VALUES.get(fish_rarity, 1) < RARITY_VALUES.get(min_rarity, 1):
		return false
	
	# Filtro de valor
	var fish_value = fish_data.get("value", 0)
	if fish_value < filters.get("min_value", 0):
		return false
	
	# Filtro de tamaño
	var fish_size = fish_data.get("size", 0.0)
	if fish_size < filters.get("min_size", 0.0):
		return false
	
	return true

func _process_auto_catch(fish_data: Dictionary) -> void:
	# Registrar captura
	if StatsTracker:
		StatsTracker.record_fish_caught(fish_data)
	
	# Auto-vender si está habilitado
	if filters.get("auto_sell", false):
		var value = fish_data.get("value", 0)
		if Save:
			Save.add_coins(value)
		print("[AutoFishing] Auto-vendido: %s por %d monedas" % [fish_data.get("name", "Pez"), value])
	else:
		# Añadir al inventario
		var item_instance = ItemInstance.new()
		item_instance.from_fish_data(fish_data)
		
		if UnifiedInventorySystem.add_item(item_instance, "fishing"):
			print("[AutoFishing] Capturado: %s" % fish_data.get("name", "Pez"))
		else:
			# Si inventario lleno, auto-vender
			var value = fish_data.get("value", 0)
			if Save:
				Save.add_coins(value)
			print("[AutoFishing] Inventario lleno, auto-vendido: %s" % fish_data.get("name", "Pez"))
	
	# Añadir al historial
	if Save and Save.has_method("add_catch_to_history"):
		Save.add_catch_to_history(fish_data)
	
	auto_catch_made.emit(fish_data)

func set_filter(filter_name: String, value) -> void:
	filters[filter_name] = value
	_save_filters()

func get_filter(filter_name: String):
	return filters.get(filter_name)

func _save_filters() -> void:
	if Save:
		Save.game_data.auto_fishing_filters = filters