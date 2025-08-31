class_name MapScreen
extends Control

# Pantalla del mapa con sistema completo de zonas bloqueadas

signal zone_selected(zone_id: String)
signal fishing_requested(zone_id: String)
signal zone_preview_requested(zone_id: String)
signal zone_unlock_requested(zone_id: String, cost: int)

var available_zones: Array[Dictionary] = []
var current_zone: Dictionary = {}

const ZONE_CARD_SCENE = preload("res://scenes/ui_new/components/Card.tscn")

# Costos de desbloqueo de zonas (progresivos por dificultad)
const ZONE_UNLOCK_COSTS = {
	"orilla": 0,
	"lago": 1000,
	"rio": 5000,
	"costa": 25000,
	"mar": 100000,
	"glaciar": 500000,
	"industrial": 2000000,
	"abismo": 10000000,
	"infernal": 50000000
}

@onready var zones_grid: GridContainer = $VBoxContainer/MapContainer/ZonesScroll/ZonesGrid
@onready var zone_icon: TextureRect = $VBoxContainer/CurrentZoneInfo/ZoneInfoContainer/ZoneIcon
@onready var zone_name: Label = $VBoxContainer/CurrentZoneInfo/ZoneInfoContainer / \
	ZoneDetails / ZoneName
@onready var zone_description: Label = $VBoxContainer/CurrentZoneInfo/ZoneInfoContainer / \
	ZoneDetails / ZoneDescription
@onready var difficulty_label: Label = $VBoxContainer/CurrentZoneInfo/ZoneInfoContainer / \
	ZoneDetails / ZoneStats / DifficultyLabel
@onready var fish_count_label: Label = $VBoxContainer/CurrentZoneInfo/ZoneInfoContainer / \
	ZoneDetails / ZoneStats / FishCountLabel
@onready var fishing_button: Button = $VBoxContainer/CurrentZoneInfo/ZoneInfoContainer / \
	ActionButtons / FishingButton
@onready var preview_button: Button = $VBoxContainer/CurrentZoneInfo/ZoneInfoContainer / \
	ActionButtons / PreviewButton

func _ready() -> void:
	_connect_signals()

func _connect_signals() -> void:
	fishing_button.pressed.connect(_on_fishing_button_pressed)
	preview_button.pressed.connect(_on_preview_button_pressed)

func setup_map(zones: Array[Dictionary], current_zone_id: String = "") -> void:
	"""Configurar mapa con zonas disponibles y estado de desbloqueo"""
	available_zones = []

	# Procesar zonas con información completa
	for zone_data in zones:
		var zone_id = zone_data.get("id", "")
		var zone_info = _enrich_zone_data(zone_data, zone_id)
		available_zones.append(zone_info)

	# Encontrar zona actual
	if current_zone_id != "":
		for zone in available_zones:
			if zone.get("id", "") == current_zone_id:
				current_zone = zone
				break

	if current_zone.is_empty() and available_zones.size() > 0:
		# Seleccionar primera zona desbloqueada
		for zone in available_zones:
			if zone.get("unlocked", false):
				current_zone = zone
				break

	_refresh_zones_grid()
	_update_current_zone_display()

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
	if zone_id == "orilla":
		return true # Zona inicial siempre desbloqueada

	if not Save:
		return false

	var unlocked_zones = Save.game_data.get("unlocked_zones", ["orilla"])
	return unlocked_zones.has(zone_id)

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
		var fish_count = zone_def.entries.size() if zone_def.entries else 0
		var multiplier = zone_def.price_multiplier

		description = "🐟 %d especies disponibles\n" % fish_count
		description += "💰 Multiplicador de precio: x%.1f\n" % multiplier

		# Añadir información de rareza
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

func _refresh_zones_grid() -> void:
	"""Actualizar grilla de zonas"""
	# Limpiar zonas existentes
	for child in zones_grid.get_children():
		child.queue_free()

	# Crear tarjetas para cada zona
	for zone in available_zones:
		var zone_card = _create_zone_card(zone)
		zones_grid.add_child(zone_card)

func _create_zone_card(zone_data: Dictionary) -> Control:
	"""Crear tarjeta de zona con información completa de desbloqueo"""
	var card = ZONE_CARD_SCENE.instantiate()

	# Información básica
	var name = zone_data.get("name", "")
	var description = zone_data.get("description", "")
	var icon = zone_data.get("icon", null)
	var is_unlocked = zone_data.get("unlocked", false)
	var is_current = zone_data.get("id", "") == current_zone.get("id", "")
	var unlock_cost = zone_data.get("unlock_cost", 0)
	var multiplier = zone_data.get("price_multiplier", 1.0)

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

	# Preparar descripción enriquecida
	var rich_description = description
	if multiplier > 1.0:
		rich_description += "\n💎 Bonificación: x%.1f valor" % multiplier

	# Configurar tarjeta
	card.setup_card(name, rich_description, icon, action_text)

	# Configurar estado visual
	var action_button = card.get_node("MarginContainer/VBoxContainer/ActionButton")
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
		card.action_pressed.connect(_on_zone_card_selected.bind(zone_data))
	elif not is_unlocked and Save and Save.get_coins() >= unlock_cost:
		card.action_pressed.connect(_on_zone_unlock_pressed.bind(zone_data))

	return card

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
	var difficulty = zone_data.get("difficulty", 1)
	var fish_species = zone_data.get("fish_species", [])
	var fish_count = fish_species.size()
	var multiplier = zone_data.get("price_multiplier", 1.0)

	# Crear contenedor para indicadores
	var indicators_container = VBoxContainer.new()
	indicators_container.add_theme_constant_override("separation", 4)

	# Primera fila: Dificultad y especies
	var first_row = HBoxContainer.new()

	# Indicador de dificultad
	var difficulty_indicator = Label.new()
	var stars = ""
	for i in range(difficulty):
		stars += "⭐"
	difficulty_indicator.text = "Dificultad: %s" % stars
	difficulty_indicator.add_theme_font_size_override("font_size", 12)
	first_row.add_child(difficulty_indicator)

	# Espaciador
	var spacer1 = Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	first_row.add_child(spacer1)

	# Indicador de especies
	var species_indicator = Label.new()
	species_indicator.text = "🐟 %d especies" % fish_count
	species_indicator.add_theme_font_size_override("font_size", 12)
	first_row.add_child(species_indicator)

	indicators_container.add_child(first_row)

	# Segunda fila: Multiplicador y rareza (si hay datos)
	if multiplier > 1.0 or fish_species.size() > 0:
		var second_row = HBoxContainer.new()

		# Multiplicador
		if multiplier > 1.0:
			var multiplier_indicator = Label.new()
			multiplier_indicator.text = "💰 x%.1f precio" % multiplier
			multiplier_indicator.add_theme_font_size_override("font_size", 11)
			multiplier_indicator.add_theme_color_override("font_color", Color.GOLD)
			second_row.add_child(multiplier_indicator)

		# Espaciador
		var spacer2 = Control.new()
		spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		second_row.add_child(spacer2)

		# Mejor rareza disponible
		if fish_species.size() > 0:
			var max_rarity = 0
			for fish in fish_species:
				var rarity = fish.get("rarity", 0)
				if rarity > max_rarity:
					max_rarity = rarity

			var rarity_indicator = Label.new()
			var rarity_text = ""
			var rarity_color = Color.WHITE

			match max_rarity:
				0:
					rarity_text = "Común"
					rarity_color = Color.WHITE
				1:
					rarity_text = "Poco común"
					rarity_color = Color.GREEN
				2:
					rarity_text = "Raro"
					rarity_color = Color.BLUE
				3:
					rarity_text = "Épico"
					rarity_color = Color.PURPLE
				4:
					rarity_text = "Legendario"
					rarity_color = Color.GOLD

			rarity_indicator.text = "✨ Hasta %s" % rarity_text
			rarity_indicator.add_theme_font_size_override("font_size", 11)
			rarity_indicator.add_theme_color_override("font_color", rarity_color)
			second_row.add_child(rarity_indicator)

		indicators_container.add_child(second_row)

	# Añadir al final de la tarjeta
	var description_container = card.get_node("MarginContainer/VBoxContainer")
	description_container.add_child(indicators_container)

func _update_current_zone_display() -> void:
	"""Actualizar información de zona actual con datos profesionales"""
	if current_zone.is_empty():
		zone_name.text = "Ninguna zona seleccionada"
		zone_description.text = "Selecciona una zona del mapa para pescar"
		difficulty_label.text = "Dificultad: -"
		fish_count_label.text = "- especies"
		fishing_button.disabled = true
		preview_button.disabled = true
		return

	# Información básica
	var name = current_zone.get("name", "Zona Desconocida")
	var multiplier = current_zone.get("price_multiplier", 1.0)

	zone_name.text = "Zona Actual: %s" % name
	if multiplier > 1.0:
		zone_name.text += " (x%.1f bonus)" % multiplier

	zone_description.text = current_zone.get("description", "")
	zone_icon.texture = current_zone.get("icon", null)

	# Actualizar dificultad con colores
	var difficulty = current_zone.get("difficulty", 1)
	var stars = ""
	for i in range(difficulty):
		stars += "⭐"
	difficulty_label.text = "Dificultad: %s" % stars

	# Color según dificultad
	match difficulty:
		1: difficulty_label.add_theme_color_override("font_color", Color.GREEN)
		2: difficulty_label.add_theme_color_override("font_color", Color.YELLOW)
		3: difficulty_label.add_theme_color_override("font_color", Color.ORANGE)
		4: difficulty_label.add_theme_color_override("font_color", Color.RED)
		_: difficulty_label.add_theme_color_override("font_color", Color.PURPLE)

	# Actualizar conteo de especies con información detallada
	var fish_species = current_zone.get("fish_species", [])
	var fish_count = fish_species.size()
	fish_count_label.text = "%d especies disponibles" % fish_count

	# Agregar información de rarezas disponibles
	if fish_species.size() > 0:
		var rarities = {}
		for fish in fish_species:
			var rarity = fish.get("rarity", 0)
			rarities[rarity] = true

		var rarity_count = rarities.size()
		fish_count_label.text += " (%d tipos de rareza)" % rarity_count

	# Habilitar botones solo si la zona está desbloqueada
	var is_unlocked = current_zone.get("unlocked", false)
	fishing_button.disabled = not is_unlocked
	preview_button.disabled = not is_unlocked

	if not is_unlocked:
		fishing_button.text = "🔒 Zona Bloqueada"
		preview_button.text = "🔒 Vista Previa"
	else:
		fishing_button.text = "🎣 Ir a Pescar"
		preview_button.text = "👁 Vista Previa"

func _on_zone_card_selected(zone_data: Dictionary) -> void:
	"""Manejar selección de zona desbloqueada"""
	current_zone = zone_data
	_update_current_zone_display()
	_refresh_zones_grid() # Refrescar para actualizar indicadores

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
		var current_zone_id = Save.game_data.get("current_zone", "orilla") if Save else "orilla"
		setup_map(zones, current_zone_id)

	# Reproducir sonido de éxito
	if SFX and SFX.has_method("play_event"):
		SFX.play_event("unlock_success")

	print("Zona desbloqueada exitosamente: %s" % zone_id)

func _on_fishing_button_pressed() -> void:
	"""Solicitar ir a pescar en la zona actual"""
	if not current_zone.is_empty():
		var zone_id = current_zone.get("id", "")
		fishing_requested.emit(zone_id)

func _on_preview_button_pressed() -> void:
	"""Solicitar vista previa de la zona actual"""
	if not current_zone.is_empty():
		var zone_id = current_zone.get("id", "")
		zone_preview_requested.emit(zone_id)
