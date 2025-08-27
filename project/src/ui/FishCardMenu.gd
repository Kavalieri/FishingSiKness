class_name FishCardMenu
extends Control
## Menú flotante para mostrar información de una captura de pez
##
## Este es el nuevo menú que solicitaste: "tarjeta de captura"

signal card_closed()

var fish_data: Dictionary
var close_button: Button

func _init(fish_info: Dictionary = {}):
	fish_data = fish_info

func setup_menu():
	"""Configurar el contenido específico de la tarjeta de pez"""
	name = "FishCardMenu"

	# Crear panel principal centrado
	var panel = PanelContainer.new()
	panel.anchor_left = 0.3
	panel.anchor_right = 0.7
	panel.anchor_top = 0.3
	panel.anchor_bottom = 0.7
	add_child(panel)

	# Contenedor principal vertical
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Header con título y botón cerrar
	var header = HBoxContainer.new()
	vbox.add_child(header)

	var title = Label.new()
	title.text = "🎣 CAPTURA REALIZADA"
	title.add_theme_font_size_override("font_size", 20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	close_button = Button.new()
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.pressed.connect(_on_close_pressed)
	header.add_child(close_button)

	# Separador
	var separator = HSeparator.new()
	vbox.add_child(separator)

	# Información del pez
	create_fish_info(vbox)

	# Botón continuar
	var continue_button = Button.new()
	continue_button.text = "🎣 CONTINUAR PESCANDO"
	continue_button.custom_minimum_size = Vector2(200, 40)
	continue_button.pressed.connect(_on_continue_pressed)
	vbox.add_child(continue_button)

func create_fish_info(container: VBoxContainer):
	"""Crear la información del pez capturado"""
	var fish_name = fish_data.get("name", "Pez Misterioso")
	var fish_value = fish_data.get("value", 0)
	var fish_rarity = fish_data.get("rarity", "común")
	var fish_zone = fish_data.get("zone", "Desconocida")

	# Icono y nombre del pez
	var fish_header = HBoxContainer.new()
	container.add_child(fish_header)

	var fish_icon = Label.new()
	fish_icon.text = get_fish_icon(fish_name)
	fish_icon.add_theme_font_size_override("font_size", 48)
	fish_icon.custom_minimum_size = Vector2(80, 80)
	fish_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fish_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fish_header.add_child(fish_icon)

	var fish_info = VBoxContainer.new()
	fish_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fish_header.add_child(fish_info)

	# Nombre
	var name_label = Label.new()
	name_label.text = fish_name
	name_label.add_theme_font_size_override("font_size", 24)
	fish_info.add_child(name_label)

	# Valor
	var value_label = Label.new()
	value_label.text = "💰 Valor: %d monedas" % fish_value
	value_label.add_theme_font_size_override("font_size", 16)
	fish_info.add_child(value_label)

	# Rareza
	var rarity_label = Label.new()
	rarity_label.text = "⭐ Rareza: %s" % fish_rarity.capitalize()
	rarity_label.add_theme_font_size_override("font_size", 16)
	rarity_label.modulate = get_rarity_color(fish_rarity)
	fish_info.add_child(rarity_label)

	# Zona
	var zone_label = Label.new()
	zone_label.text = "🌍 Zona: %s" % fish_zone
	zone_label.add_theme_font_size_override("font_size", 16)
	fish_info.add_child(zone_label)

func get_fish_icon(fish_name: String) -> String:
	"""Obtener icono apropiado para el pez"""
	var name_lower = fish_name.to_lower()

	var fish_icons = {
		"sardina": "🐟",
		"trucha": "🐠",
		"salmon": "🍣",
		"calamar": "🦑",
		"pulpo": "🐙",
		"cangrejo": "🦀",
		"langosta": "🦞",
		"globo": "🐡"
	}

	for fish_type in fish_icons:
		if fish_type in name_lower:
			return fish_icons[fish_type]

	return "🐟"

func get_rarity_color(rarity: String) -> Color:
	"""Obtener color según rareza"""
	var colors = {
		"común": Color.WHITE,
		"poco común": Color.GREEN,
		"raro": Color.BLUE,
		"épico": Color.PURPLE,
		"legendario": Color.GOLD
	}

	return colors.get(rarity.to_lower(), Color.WHITE)

func _on_close_pressed():
	"""Cerrar la tarjeta"""
	card_closed.emit()

func _on_continue_pressed():
	"""Continuar pescando"""
	card_closed.emit()

func _input(event):
	"""Cerrar con ESC"""
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		card_closed.emit()
