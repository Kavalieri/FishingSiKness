class_name MapScreen
extends Control

# Pantalla del mapa con sistema completo de zonas bloqueadas

signal zone_selected(zone_id: String)
signal zone_unlock_requested(zone_id: String, cost: int)

var available_zones: Array[Dictionary]
var current_zone: Dictionary = {}

const ZONE_CARD_SCENE = preload("res://scenes/ui_new/components/Card.tscn")

# Costos de desbloqueo de zonas (solo zonas realistas basadas en CSV)
const ZONE_UNLOCK_COSTS = {
	# Orden por price_multiplier: 1.0 → 1.2 → 1.5 → 1.8 → 3.0
	# Progresión suavizada para permitir más zonas futuras
	"lago_montana_alpes": 0, # x1.0 - Zona inicial gratuita
	"grandes_lagos_norteamerica": 1500, # x1.2 - Progresión suave
	"costas_atlanticas": 5000, # x1.5 - Costo medio
	"rios_amazonicos": 15000, # x1.8 - Costo medio-alto
	"oceanos_profundos": 35000, # x3.0 - Costo alto (era 100K, ahora más suave)
}

@onready var zones_list: VBoxContainer = $VBoxContainer/MapContainer/ZonesScroll/ZonesList

func _ready() -> void:
	pass # Ya no necesitamos conectar señales del panel eliminado

func setup_map(zones: Array, current_zone_id: String = "") -> void:
	"""Configurar mapa con zonas disponibles y estado de desbloqueo"""
	print("[MapScreen] DEBUG: Recibiendo %d zonas" % zones.size())
	available_zones = []

	# Procesar zonas ZoneDef directamente
	for i in range(zones.size()):
		var zone_def = zones[i]
		print("[MapScreen] DEBUG: Procesando zona %d: %s" % [i, zone_def.id if zone_def else "NULL"])
		if zone_def and zone_def.id:
			var zone_info = _enrich_zone_data_from_def(zone_def)
			print("[MapScreen] DEBUG: Zona procesada - ID: %s, Desbloqueada: %s" % [zone_info.get("id", "?"), zone_info.get("unlocked", false)])
			available_zones.append(zone_info)

	print("[MapScreen] DEBUG: Total zonas procesadas: %d" % available_zones.size())
	print("[MapScreen] DEBUG: Current zone ID: '%s'" % current_zone_id)

	# Encontrar zona actual
	if current_zone_id != "":
		for zone in available_zones:
			if zone.get("id", "") == current_zone_id:
				current_zone = zone
				print("[MapScreen] DEBUG: Zona actual encontrada: %s" % zone.get("name", "?"))
				break

	if current_zone.is_empty() and available_zones.size() > 0:
		print("[MapScreen] DEBUG: No hay zona actual, buscando primera desbloqueada...")
		# Seleccionar primera zona desbloqueada
		for zone in available_zones:
			if zone.get("unlocked", false):
				current_zone = zone
				print("[MapScreen] DEBUG: Zona inicial seleccionada: %s (desbloqueada: %s)" % [zone.get("name", "?"), zone.get("unlocked", false)])
				break

	_refresh_zones_list()

func _enrich_zone_data_from_def(zone_def) -> Dictionary:
	"""Enriquecer datos de zona directamente desde ZoneDef"""
	var zone_id = zone_def.id
	var enriched = {
		"id": zone_def.id,
		"name": zone_def.name,
		"description": zone_def.description,
		"difficulty": zone_def.difficulty,
		"unlock_cost": zone_def.unlock_cost,
		"price_multiplier": zone_def.price_multiplier,
		"background_path": zone_def.background,
		"unlocked": _is_zone_unlocked(zone_id),
		"fish_species": _get_zone_fish_list(zone_def)
	}

	return enriched

func _enrich_zone_data(zone_data: Dictionary, zone_id: String) -> Dictionary:
	"""Enriquecer datos de zona con información de desbloqueo y contenido"""
	var enriched = zone_data.duplicate()

	# Verificar si está desbloqueada
	enriched["unlocked"] = _is_zone_unlocked(zone_id)
	enriched["unlock_cost"] = ZONE_UNLOCK_COSTS.get(zone_id, 0)

	# Información de pesca (usar Content system)
	if Content:
		var zone_def = Content.get_zone_by_id(zone_id)
		if zone_def:
			enriched["price_multiplier"] = zone_def.price_multiplier
			enriched["fish_species"] = _get_zone_fish_list(zone_def)
			enriched["description"] = _generate_zone_description(zone_def)

	return enriched

func _is_zone_unlocked(zone_id: String) -> bool:
	"""Verificar si una zona está desbloqueada"""
	# Solo la primera zona realista está desbloqueada por defecto
	if zone_id == "lago_montana_alpes":
		print("[MapScreen] DEBUG: Zona inicial desbloqueada: %s" % zone_id)
		return true

	if not Save:
		print("[MapScreen] DEBUG: No hay Save, zona bloqueada: %s" % zone_id)
		return false

	var unlocked_zones = Save.game_data.get("unlocked_zones", ["lago_montana_alpes"])
	var is_unlocked = unlocked_zones.has(zone_id)
	print("[MapScreen] DEBUG: Verificando zona %s - Desbloqueada: %s (Lista: %s)" % [zone_id, is_unlocked, str(unlocked_zones)])
	return is_unlocked

func _get_zone_fish_list(zone_def) -> Array:
	"""Obtener lista de especies de una zona"""
	var fish_list = []
	if zone_def and zone_def.entries:
		for entry in zone_def.entries:
			if entry and entry.fish:
				fish_list.append({
					"name": entry.fish.name,
					"rarity": entry.fish.rarity,
					"weight": entry.weight
				})
	return fish_list

func _generate_zone_description(zone_def) -> String:
	"""Generar descripción rica de zona con estadísticas"""
	var description = ""

	if zone_def:
		# Añadir información de rareza sin duplicar especies ni multiplicador
		var rarity_info = _analyze_zone_rarities(zone_def)
		if rarity_info.size() > 0:
			description += "✨ Rarezas: %s" % " ".join(rarity_info)

	return description

func _analyze_zone_rarities(zone_def) -> Array:
	"""Analizar rarezas disponibles en la zona"""
	var rarities = {}
	if zone_def and zone_def.entries:
		for entry in zone_def.entries:
			if entry and entry.fish:
				var rarity = entry.fish.rarity
				rarities[rarity] = true

	var rarity_names = []
	for rarity in rarities.keys():
		match rarity:
			0: rarity_names.append("Común")
			1: rarity_names.append("Poco común")
			2: rarity_names.append("Raro")
			3: rarity_names.append("Épico")
			4: rarity_names.append("Legendario")

	return rarity_names

func _refresh_zones_list() -> void:
	"""Actualizar lista de zonas ordenada por dificultad"""
	print("[MapScreen] DEBUG: Refrescando lista con %d zonas" % available_zones.size())

	# Limpiar zonas existentes
	for child in zones_list.get_children():
		child.queue_free()

	# Ordenar zonas por unlock_cost (dificultad)
	var sorted_zones = available_zones.duplicate()
	sorted_zones.sort_custom(_compare_zones_by_difficulty)

	# Crear tarjetas para cada zona ordenada
	for i in range(sorted_zones.size()):
		var zone = sorted_zones[i]
		print("[MapScreen] DEBUG: Creando tarjeta %d para zona: %s (costo: %s)" % [i, zone.get("name", "?"), zone.get("unlock_cost", 0)])
		_create_zone_card(zone)

	print("[MapScreen] DEBUG: Lista actualizada con %d tarjetas" % zones_list.get_child_count())

func _compare_zones_by_difficulty(a: Dictionary, b: Dictionary) -> bool:
	"""Comparar zonas por unlock_cost. Zonas desbloqueadas primero, luego por costo de desbloqueo"""
	var unlock_cost_a = a.get("unlock_cost", 0)
	var unlock_cost_b = b.get("unlock_cost", 0)
	var unlocked_a = a.get("unlocked", false)
	var unlocked_b = b.get("unlocked", false)

	# Zonas desbloqueadas van primero
	if unlocked_a and not unlocked_b:
		return true
	if unlocked_b and not unlocked_a:
		return false

	# Si ambas tienen el mismo estado de desbloqueo, ordenar por unlock_cost (menor a mayor)
	return unlock_cost_a < unlock_cost_b

func _create_zone_card(zone_data: Dictionary) -> Control:
	"""Crear tarjeta de zona con información completa de desbloqueo"""
	var card = ZONE_CARD_SCENE.instantiate()

	# Añadir al árbol primero para que los nodos @onready funcionen
	zones_list.add_child(card)

	# Información básica
	var name = zone_data.get("name", "")
	var description = zone_data.get("description", "")
	var icon = zone_data.get("icon", null)
	var is_unlocked = zone_data.get("unlocked", false)
	var is_current = zone_data.get("id", "") == current_zone.get("id", "")
	var unlock_cost = zone_data.get("unlock_cost", 0)
	var multiplier = zone_data.get("price_multiplier", 1.0)
	var difficulty = zone_data.get("difficulty", 1)

	# Texto de acción basado en estado
	var action_text = ""
	if is_current:
		action_text = "✅ Zona Actual"
	elif is_unlocked:
		action_text = "🎣 Seleccionar"
	else:
		var can_afford = Save and Save.get_coins() >= unlock_cost
		if can_afford:
			action_text = "🔓 Desbloquear (%s)" % _format_number(unlock_cost)
		else:
			action_text = "🔒 Bloqueada (%s)" % _format_number(unlock_cost)

	# Contar especies de peces disponibles en la zona
	var fish_count = Content.get_fish_for_zone(zone_data.get("id", "")).size()

	# Para las tarjetas, mostrar SOLO información básica
	var card_description = "💎 Multiplicador: x%.1f valor\n🐟 %d especies disponibles" % [multiplier, fish_count]

	# Preparar información de dificultad usando el campo difficulty del recurso
	var difficulty_text = ""
	match difficulty:
		1:
			difficulty_text = "⭐ Muy Fácil"
		2:
			difficulty_text = "⭐⭐ Fácil"
		3:
			difficulty_text = "⭐⭐⭐ Medio"
		4:
			difficulty_text = "⭐⭐⭐⭐ Difícil"
		5:
			difficulty_text = "⭐⭐⭐⭐⭐ Muy Difícil"
		_:
			difficulty_text = "⭐ Muy Fácil"

	# Configurar tarjeta con información básica
	var card_data = {
		"title": name,
		"description": card_description,
		"icon_path": icon,
		"action_text": action_text,
		"difficulty": difficulty_text
	}
	card.setup_card(card_data)

	# Configurar estado visual
	var action_button = card.get_node("MarginContainer/HBoxContainer/ButtonsContainer/ActionButton")
	var info_button = card.get_node("MarginContainer/HBoxContainer/ButtonsContainer/InfoButton")
	if is_current:
		action_button.disabled = true
		card.modulate = Color(1.2, 1.2, 1.0, 1.0) # Resaltado dorado
	elif not is_unlocked:
		if Save and Save.get_coins() >= unlock_cost:
			action_button.modulate = Color.YELLOW # Puede desbloquear
		else:
			action_button.disabled = true
			card.modulate = Color(0.7, 0.7, 0.7, 1.0) # Gris oscuro

	# Añadir indicadores visuales específicos
	_add_zone_indicators(card, zone_data)

	# Conectar señales según estado
	if is_unlocked and not is_current:
		card.action_pressed.connect(_on_zone_card_selected_wrapper.bind(zone_data))
	elif not is_unlocked and Save and Save.get_coins() >= unlock_cost:
		card.action_pressed.connect(_on_zone_unlock_pressed_wrapper.bind(zone_data))

	# Conectar siempre el botón de información
	card.info_pressed.connect(_on_zone_info_pressed_wrapper.bind(zone_data))

	return card

func _on_zone_dialog_closed(dialog: Node) -> void:
	"""Limpiar popup de zona cuando se cierra"""
	if dialog:
		dialog.queue_free()

func _format_number(number: int) -> String:
	"""Formatear números grandes de forma legible"""
	if number >= 1000000:
		return "%.1fM" % (number / 1000000.0)
	elif number >= 1000:
		return "%.1fK" % (number / 1000.0)
	else:
		return str(number)

func _add_zone_indicators(card: Control, zone_data: Dictionary) -> void:
	"""Añadir indicadores visuales profesionales a la tarjeta"""
	# Este método ya no añade indicadores duplicados
	# La información se muestra únicamente en la descripción de la tarjeta
	pass

func _on_zone_info_pressed_wrapper(_card_data: Dictionary, zone_data: Dictionary) -> void:
	"""Wrapper para manejar información de zona - ignora card_data y usa zone_data"""
	_on_zone_info_pressed(zone_data)

func _on_zone_info_pressed(zone_data: Dictionary) -> void:
	"""Mostrar información detallada de la zona"""
	print("[MapScreen] Mostrando información detallada de zona: %s" % zone_data.get("name", "?"))

	# Crear y mostrar popup de información de zona
	var zone_info_dialog = preload("res://scenes/ui/ZoneInfoDialog.tscn").instantiate()
	get_tree().current_scene.add_child(zone_info_dialog)
	zone_info_dialog.show_zone_info(zone_data)

	# Conectar señal de cierre para limpieza
	zone_info_dialog.close_requested.connect(_on_zone_dialog_closed.bind(zone_info_dialog))

func _on_zone_card_selected_wrapper(_card_data: Dictionary, zone_data: Dictionary) -> void:
	"""Wrapper para manejar selección de zona - ignora card_data y usa zone_data"""
	_on_zone_card_selected(zone_data)

func _on_zone_unlock_pressed_wrapper(_card_data: Dictionary, zone_data: Dictionary) -> void:
	"""Wrapper para manejar desbloqueo de zona - ignora card_data y usa zone_data"""
	_on_zone_unlock_pressed(zone_data)

func _on_zone_card_selected(zone_data: Dictionary) -> void:
	"""Manejar selección de zona desbloqueada"""
	current_zone = zone_data
	_refresh_zones_list() # Refrescar para actualizar indicadores

	var zone_id = zone_data.get("id", "")
	if zone_id != "":
		# Actualizar zona actual en Save
		if Save:
			Save.game_data.current_zone = zone_id

		zone_selected.emit(zone_id)

		# Reproducir sonido de selección
		if SFX and SFX.has_method("play_event"):
			SFX.play_event("ui_select")

func _on_zone_unlock_pressed(zone_data: Dictionary) -> void:
	"""Manejar intento de desbloqueo de zona"""
	var zone_id = zone_data.get("id", "")
	var unlock_cost = zone_data.get("unlock_cost", 0)

	if Save and Save.get_coins() >= unlock_cost:
		zone_unlock_requested.emit(zone_id, unlock_cost)
	else:
		# No hay suficientes monedas - mostrar mensaje
		if SFX and SFX.has_method("play_event"):
			SFX.play_event("ui_error")

		print("Fondos insuficientes para desbloquear zona: %s (costo: %d)" % [zone_id, unlock_cost])

func unlock_zone_success(zone_id: String) -> void:
	"""Llamado cuando se desbloquea exitosamente una zona"""
	# Refrescar datos para mostrar zona como desbloqueada
	if Content:
		var zones = Content.get_all_zones()
		var current_zone_id = Save.game_data.get("current_zone", "lago_montana_alpes") if Save else "lago_montana_alpes"
		setup_map(zones, current_zone_id)

	# Reproducir sonido de éxito
	if SFX and SFX.has_method("play_event"):
		SFX.play_event("unlock_success")

	print("Zona desbloqueada exitosamente: %s" % zone_id)
