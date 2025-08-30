class_name MapScreen
extends Control

# Pantalla del mapa según especificación

signal zone_selected(zone_id: String)
signal fishing_requested(zone_id: String)
signal zone_preview_requested(zone_id: String)

var available_zones: Array[Dictionary] = []
var current_zone: Dictionary = {}

const ZONE_CARD_SCENE = preload("res://scenes/ui_new/components/Card.tscn")

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
	"""Configurar mapa con zonas disponibles"""
	available_zones = zones

	# Encontrar zona actual
	if current_zone_id != "":
		for zone in zones:
			if zone.get("id", "") == current_zone_id:
				current_zone = zone
				break

	if current_zone.is_empty() and zones.size() > 0:
		current_zone = zones[0]

	_refresh_zones_grid()
	_update_current_zone_display()

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
	"""Crear tarjeta de zona reutilizando Card"""
	var card = ZONE_CARD_SCENE.instantiate()

	# Información básica
	var name = zone_data.get("name", "")
	var description = zone_data.get("description", "")
	var icon = zone_data.get("icon", null)
	var is_unlocked = zone_data.get("unlocked", true)
	var is_current = zone_data.get("id", "") == current_zone.get("id", "")

	# Texto de acción
	var action_text = ""
	if is_current:
		action_text = "Actual"
	elif is_unlocked:
		action_text = "Seleccionar"
	else:
		action_text = "Bloqueado"

	# Configurar tarjeta
	card.setup_card(name, description, icon, action_text)

	# Configurar estado
	var action_button = card.get_node("MarginContainer/VBoxContainer/ActionButton")
	if is_current:
		action_button.disabled = true
		card.modulate = Color(1.2, 1.2, 1.0) # Resaltado amarillento
	elif not is_unlocked:
		action_button.disabled = true
		card.modulate = Color.GRAY

	# Añadir indicadores visuales
	_add_zone_indicators(card, zone_data)

	# Conectar señal
	if is_unlocked and not is_current:
		card.action_pressed.connect(_on_zone_card_selected.bind(zone_data))

	return card

func _add_zone_indicators(card: Control, zone_data: Dictionary) -> void:
	"""Añadir indicadores visuales a la tarjeta de zona"""
	var difficulty = zone_data.get("difficulty", 1)
	var fish_count = zone_data.get("fish_species", []).size()

	# Crear contenedor para indicadores
	var indicators_container = HBoxContainer.new()

	# Indicador de dificultad
	var difficulty_indicator = Label.new()
	var stars = ""
	for i in range(difficulty):
		stars += "⭐"
	difficulty_indicator.text = stars
	indicators_container.add_child(difficulty_indicator)

	# Espaciador
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	indicators_container.add_child(spacer)

	# Indicador de especies
	var species_indicator = Label.new()
	species_indicator.text = "%d 🐟" % fish_count
	indicators_container.add_child(species_indicator)

	# Añadir al final de la descripción
	var description_container = card.get_node("MarginContainer/VBoxContainer")
	description_container.add_child(indicators_container)

func _update_current_zone_display() -> void:
	"""Actualizar información de zona actual"""
	if current_zone.is_empty():
		return

	zone_name.text = "Zona Actual: %s" % current_zone.get("name", "")
	zone_description.text = current_zone.get("description", "")
	zone_icon.texture = current_zone.get("icon", null)

	# Actualizar dificultad
	var difficulty = current_zone.get("difficulty", 1)
	var stars = ""
	for i in range(difficulty):
		stars += "⭐"
	difficulty_label.text = "Dificultad: %s" % stars

	# Actualizar conteo de especies
	var fish_count = current_zone.get("fish_species", []).size()
	fish_count_label.text = "%d especies" % fish_count

	# Habilitar botones
	fishing_button.disabled = false
	preview_button.disabled = false

func _on_zone_card_selected(zone_data: Dictionary) -> void:
	"""Manejar selección de zona"""
	current_zone = zone_data
	_update_current_zone_display()
	_refresh_zones_grid() # Refrescar para actualizar indicadores

	var zone_id = zone_data.get("id", "")
	zone_selected.emit(zone_id)

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
