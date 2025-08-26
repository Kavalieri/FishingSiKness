# Script alternativo para FishDetailsPopup (no usar class_name para evitar conflictos)
extends AcceptDialog

# Referencias a nodos UI
@onready var fish_sprite: TextureRect = \
	$VBoxContainer/HeaderContainer/FishSpriteContainer/FishSprite
@onready var fish_name_label: Label = \
	$VBoxContainer/HeaderContainer/InfoContainer/FishNameLabel
@onready var fish_price_label: Label = \
	$VBoxContainer/HeaderContainer/InfoContainer/FishPriceLabel

@onready var size_value_label: Label = \
	$VBoxContainer/StatsContainer/SizeContainer/SizeValueLabel
@onready var zone_value_label: Label = \
	$VBoxContainer/StatsContainer/ZoneContainer/ZoneValueLabel
@onready var timestamp_value_label: Label = \
	$VBoxContainer/StatsContainer/TimestampContainer/TimestampValueLabel

@onready var description_text: RichTextLabel = \
	$VBoxContainer/DescriptionContainer/DescriptionText

func _ready():
	title = "Detalles del Pescado"
	ok_button_text = "Cerrar"

func show_fish_details(fish_data: Dictionary):
	"""Mostrar los detalles del pescado en el popup"""
	if not fish_data:
		push_error("No se proporcionaron datos del pescado")
		return

	# Cargar datos básicos
	var fish_def: FishDef = fish_data.get("definition")
	if fish_def:
		fish_name_label.text = fish_def.display_name
		fish_sprite.texture = fish_def.sprite

		# Crear descripción con estadísticas del pescado
		var desc_text = fish_def.description + "\n\n"
		desc_text += "[b]Estadísticas base:[/b]\n"
		desc_text += "• Rareza: " + str(fish_def.rarity) + "\n"
		desc_text += "• Valor base: " + str(fish_def.base_value) + " monedas"

		description_text.text = desc_text

	# Mostrar precio final calculado
	var final_price = fish_data.get("price", 0)
	fish_price_label.text = str(final_price) + " monedas"

	# Mostrar datos de captura únicos
	var size = fish_data.get("size", 0.0)
	size_value_label.text = "%.2f cm" % size

	var zone = fish_data.get("zone", "desconocida")
	zone_value_label.text = _capitalize_zone_name(zone)

	var timestamp = fish_data.get("timestamp", 0)
	timestamp_value_label.text = _format_timestamp(timestamp)

	# Mostrar el popup
	popup_centered()

func _capitalize_zone_name(zone_name: String) -> String:
	"""Capitalizar la primera letra de cada palabra en el nombre de zona"""
	if zone_name.is_empty():
		return "Desconocida"

	var words = zone_name.split(" ")
	var capitalized_words = []

	for word in words:
		if word.length() > 0:
			var capitalized = word[0].to_upper() + word.substr(1).to_lower()
			capitalized_words.append(capitalized)

	return " ".join(capitalized_words)

func _format_timestamp(timestamp: int) -> String:
	"""Formatear timestamp a fecha y hora legible"""
	if timestamp == 0:
		return "Fecha desconocida"

	var datetime = Time.get_datetime_dict_from_unix_time(timestamp)

	return "%02d/%02d/%04d - %02d:%02d" % [
		datetime.day,
		datetime.month,
		datetime.year,
		datetime.hour,
		datetime.minute
	]
