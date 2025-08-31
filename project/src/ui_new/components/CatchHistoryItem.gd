class_name CatchHistoryItem
extends PanelContainer

# Item individual del historial de capturas

@onready var fish_icon: TextureRect = $MarginContainer/HBoxContainer/FishIcon
@onready var fish_name_label: Label = $MarginContainer/HBoxContainer/InfoVBox/FishNameLabel
@onready var size_label: Label = $MarginContainer/HBoxContainer/InfoVBox/DetailsHBox/SizeLabel
@onready var rarity_label: Label = $MarginContainer/HBoxContainer/InfoVBox/DetailsHBox/RarityLabel
@onready var value_label: Label = $MarginContainer/HBoxContainer/RightVBox/ValueLabel
@onready var time_label: Label = $MarginContainer/HBoxContainer/RightVBox/TimeLabel

func setup_catch_data(catch_data: Dictionary) -> void:
	"""Configurar el item con datos de una captura"""

	# Nombre del pez
	var fish_name = catch_data.get("name", "Pez Desconocido")
	fish_name_label.text = fish_name

	# Icono del pez
	var fish_icon_texture = catch_data.get("icon", null)
	if fish_icon_texture:
		fish_icon.texture = fish_icon_texture
	else:
		# Fallback: intentar cargar desde Content o archivo
		fish_icon.texture = _load_fish_fallback_icon(fish_name)

	# Tamaño del pez
	var size = catch_data.get("size", 0.0)
	if size > 0:
		size_label.text = "📏 %.1fcm" % size
	else:
		size_label.text = "📏 --cm"

	# Rareza
	var rarity = catch_data.get("rarity", "común")
	var rarity_icon = _get_rarity_icon(rarity)
	rarity_label.text = "%s %s" % [rarity_icon, rarity.capitalize()]

	# Valor
	var value = catch_data.get("value", 0)
	value_label.text = "%d 💰" % value

	# Tiempo de captura
	var timestamp = catch_data.get("timestamp", {})
	time_label.text = _format_timestamp(timestamp)

func _load_fish_fallback_icon(fish_name: String) -> Texture2D:
	"""Cargar icono de pez como fallback"""
	var icon_path = "res://art/fish/%s.png" % fish_name.to_lower()
	if ResourceLoader.exists(icon_path):
		return ResourceLoader.load(icon_path, "Texture2D")

	# Fallback final
	return ResourceLoader.load("res://art/fish/sardina.png", "Texture2D")

func _get_rarity_icon(rarity: String) -> String:
	"""Obtener icono según rareza"""
	match rarity.to_lower():
		"común", "common":
			return "⚪"
		"rara", "uncommon":
			return "🟢"
		"épica", "rare":
			return "🔵"
		"legendaria", "epic":
			return "🟣"
		"mítica", "legendary":
			return "🟡"
		_:
			return "⚪"

func _format_timestamp(timestamp: Dictionary) -> String:
	"""Formatear timestamp para mostrar"""
	if timestamp.is_empty():
		return "??:??"

	var hour = timestamp.get("hour", 0)
	var minute = timestamp.get("minute", 0)
	return "%02d:%02d" % [hour, minute]
