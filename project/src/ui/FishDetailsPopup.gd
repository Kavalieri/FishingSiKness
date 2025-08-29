class_name FishDetailsPopup
extends AcceptDialog

# Referencias a los nodos del popup
@onready var fish_sprite: TextureRect = \
	$BackgroundPanel/MainContainer/HeaderContainer/FishSprite
@onready var fish_name_label: Label = \
	$BackgroundPanel/MainContainer/HeaderContainer/TitleContainer/FishNameLabel
@onready var species_label: Label = \
	$BackgroundPanel/MainContainer/HeaderContainer/TitleContainer/SpeciesLabel
@onready var price_label: Label = \
	$BackgroundPanel/MainContainer/StatsContainer/PriceContainer/PriceLabel
@onready var size_label: Label = \
	$BackgroundPanel/MainContainer/StatsContainer/SizeContainer/SizeLabel
@onready var zone_label: Label = \
	$BackgroundPanel/MainContainer/StatsContainer/ZoneContainer/ZoneLabel
@onready var timestamp_label: Label = \
	$BackgroundPanel/MainContainer/StatsContainer/TimestampContainer/TimestampLabel
@onready var bonus_label: Label = \
	$BackgroundPanel/MainContainer/StatsContainer/BonusContainer/BonusLabel
@onready var description_label: Label = \
	$BackgroundPanel/MainContainer/DescriptionContainer/DescriptionLabel

func _ready():
	# Configurar el popup para que se cierre al hacer clic fuera o presionar escape
	close_requested.connect(_on_close_requested)

	# Configurar fondo de tarjeta de pez
	setup_fishcard_background()

func setup_fishcard_background():
	"""Configurar fondo específico para tarjetas de pez"""
	var background_panel = $BackgroundPanel
	if background_panel and BackgroundManager:
		BackgroundManager.setup_fishcard_background(background_panel)
		print("OK Fondo de tarjeta de pez configurado")
	else:
		print("⚠️ No se pudo configurar fondo de tarjeta de pez")

func show_fish_details(fish_def: FishDef, capture_data: Dictionary):
	"""Mostrar los detalles completos del pescado en el popup"""
	if not fish_def or capture_data.is_empty():
		return

	# Configurar información básica
	if fish_name_label:
		fish_name_label.text = fish_def.name

	if species_label:
		species_label.text = fish_def.species_category

	if fish_sprite and fish_def.sprite:
		fish_sprite.texture = fish_def.sprite

	# Configurar estadísticas de captura
	if price_label:
		var price = capture_data.get("value", 0)
		price_label.text = "Precio: %dc" % price

	if size_label:
		var size = capture_data.get("size", 0.0)
		size_label.text = "Tamaño: %.1fcm" % size

	if zone_label:
		var zone = capture_data.get("capture_zone_id", "desconocida")
		zone_label.text = "Zona: %s" % _capitalize_zone_name(zone)

	if timestamp_label:
		var timestamp = capture_data.get("capture_timestamp", "Desconocido")
		timestamp_label.text = "Capturado: %s" % _format_timestamp(timestamp)

	if bonus_label:
		var bonus = capture_data.get("zone_multiplier", 1.0)
		bonus_label.text = "Bonus zona: x%.1f" % bonus

	if description_label:
		description_label.text = fish_def.description

	# Mostrar el popup
	popup_centered()

func _capitalize_zone_name(zone_name: String) -> String:
	"""Capitalizar la primera letra del nombre de la zona"""
	if zone_name.is_empty():
		return "Desconocida"

	return zone_name.capitalize()

func _format_timestamp(timestamp: String) -> String:
	"""Formatear el timestamp para ser más legible"""
	if timestamp == "Desconocido" or timestamp.is_empty():
		return "Desconocido"

	# Formato: 2025-08-26T18:01:22 -> 26/08/2025 18:01
	var parts = timestamp.split("T")
	if parts.size() == 2:
		var date_part = parts[0]
		var time_part = parts[1].split(":").slice(0, 2) # Solo horas:minutos

		var date_components = date_part.split("-")
		if date_components.size() == 3:
			var formatted_date = "%s/%s/%s" % [date_components[2], date_components[1], date_components[0]]
			var formatted_time = ":".join(time_part)
			return "%s %s" % [formatted_date, formatted_time]

	return timestamp

func _on_close_requested():
	"""Cerrar el popup"""
	hide()
