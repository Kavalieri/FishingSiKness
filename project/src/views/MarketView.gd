class_name MarketView
extends Control

var info_label: Label
var main_container: VBoxContainer

func _ready():
	setup_background()
	setup_ui()
	refresh_display()

func setup_background():
	"""Configurar fondo principal usando BackgroundManager"""
	if BackgroundManager:
		BackgroundManager.setup_main_background(self)
		print("✅ Fondo principal configurado en MarketView")
	else:
		print("⚠️ BackgroundManager no disponible en MarketView")

func _on_visibility_changed():
	if visible:
		refresh_display()

func setup_ui():
	main_container = VBoxContainer.new()
	add_child(main_container)
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	main_container.offset_left = 15
	main_container.offset_right = -15
	main_container.offset_top = 15
	main_container.offset_bottom = -15
	main_container.add_theme_constant_override("separation", 15)

	# Header con título y información básica
	create_market_header()

	# Información resumida del inventario
	create_inventory_summary()

	# Botón principal para abrir la nevera/inventario
	create_main_action_button()

	# Información adicional del mercado
	create_market_info()

func create_market_header():
	var header_vbox = VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 5)
	main_container.add_child(header_vbox)

	# Título principal
	var title = Label.new()
	var current_zone = Save.game_data.get("current_zone", "orilla")
	# Obtener nombre de zona del sistema de contenido
	var zone_def = Content.get_zone_by_id(current_zone) if Content else null
	var zone_name = zone_def.name if zone_def else current_zone.capitalize()
	title.text = "🏪 MERCADO DE %s" % zone_name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color.GOLD)
	header_vbox.add_child(title)

	# Subtítulo
	var subtitle = Label.new()
	subtitle.text = "Compra, vende y gestiona tu inventario"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	header_vbox.add_child(subtitle)

func create_inventory_summary():
	var summary_panel = PanelContainer.new()
	summary_panel.add_theme_color_override("bg_color", Color(0.2, 0.2, 0.3, 0.5))
	main_container.add_child(summary_panel)

	var summary_vbox = VBoxContainer.new()
	summary_vbox.add_theme_constant_override("separation", 8)
	summary_panel.add_child(summary_vbox)

	# Título de la sección
	var section_title = Label.new()
	section_title.text = "📦 RESUMEN DE INVENTARIO"
	section_title.add_theme_font_size_override("font_size", 16)
	section_title.add_theme_color_override("font_color", Color.CYAN)
	summary_vbox.add_child(section_title)

	# Label para información dinámica
	info_label = Label.new()
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_font_size_override("font_size", 14)
	summary_vbox.add_child(info_label)

func create_main_action_button():
	# Botón principal para abrir inventario con todas las opciones
	var main_button = Button.new()
	main_button.text = "🧊 ABRIR NEVERA COMPLETA"
	main_button.custom_minimum_size = Vector2(0, 60)
	main_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_button.add_theme_font_size_override("font_size", 18)
	main_button.add_theme_color_override("font_color", Color.WHITE)
	main_button.add_theme_color_override("font_hover_color", Color.LIGHT_GREEN)
	main_button.pressed.connect(_on_open_inventory_pressed)
	main_container.add_child(main_button)

func create_market_info():
	var info_panel = PanelContainer.new()
	info_panel.add_theme_color_override("bg_color", Color(0.1, 0.3, 0.1, 0.3))
	main_container.add_child(info_panel)

	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 5)
	info_panel.add_child(info_vbox)

	var info_title = Label.new()
	info_title.text = "💰 INFORMACIÓN DEL MERCADO"
	info_title.add_theme_font_size_override("font_size", 14)
	info_title.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	info_vbox.add_child(info_title)

	var market_info = Label.new()
	market_info.text = ("• Precios ya calculados por zona\n" +
		"• Comisión del mercado: 0%%\n" +
		"• Estado: ABIERTO 🟢")
	market_info.add_theme_font_size_override("font_size", 12)
	market_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(market_info)

func refresh_display():
	if not info_label:
		return

	var inventory = Save.get_inventory()
	var total_value = 0
	var fish_summary = {}

	# Calcular estadísticas usando el precio final ya calculado
	for fish_data in inventory:
		var name = fish_data.get("name", "Pez")
		var value = fish_data.get("value", 0) # Precio final ya calculado
		total_value += value

		if fish_summary.has(name):
			fish_summary[name].count += 1
			fish_summary[name].value += value
		else:
			fish_summary[name] = {"count": 1, "value": value}

	# Crear texto informativo
	var info_text = ""

	if inventory.size() == 0:
		info_text = "Tu nevera está vacía.\n\n¡Ve a pescar para conseguir peces que vender!"
	else:
		info_text = "PECES DISPONIBLES PARA VENDER:\n\n"

		var sorted_fish = fish_summary.keys()
		sorted_fish.sort()

		for fish_name in sorted_fish:
			var data = fish_summary[fish_name]
			info_text += "• %s x%d = %dc\n" % [fish_name, data.count, data.value]

		info_text += "\nVALOR TOTAL: %dc" % total_value
		info_text += " (precios finales)\n"

		info_text += "Capacidad: %d/%d peces" % [inventory.size(), Save.get_max_inventory()]

	info_label.text = info_text

func _on_goto_fridge_pressed():
	# Abrir panel de inventario unificado con opción de venta
	var screen_manager = get_tree().current_scene
	if screen_manager and screen_manager.has_method("show_inventory"):
		screen_manager.show_inventory(true, "🧊 NEVERA - VENTA")
		if SFX:
			SFX.play_event("click")

func _on_open_inventory_pressed():
	# Abre directamente la nevera con todas las opciones (venta y descarte)
	var screen_manager = get_tree().get_first_node_in_group("ScreenManager")
	if not screen_manager:
		# Fallback: buscar en current_scene
		screen_manager = get_tree().current_scene
		if screen_manager and not screen_manager.has_method("show_inventory"):
			# Buscar como hijo del current_scene
			screen_manager = screen_manager.get_node_or_null("ScreenManager")

	if screen_manager and screen_manager.has_method("show_inventory"):
		screen_manager.show_inventory(true, "🧊 NEVERA - MERCADO")
		if SFX:
			SFX.play_event("click")
		print("✅ Abriendo nevera desde MarketView")
	else:
		print("❌ ERROR: No se pudo encontrar ScreenManager o método show_inventory")
		print("Current scene: ", get_tree().current_scene)
		print("Current scene name: ", get_tree().current_scene.name if get_tree().current_scene else "null")
		# Fallback: intentar abrir directamente
		var direct_manager = get_tree().current_scene
		if direct_manager and direct_manager.has_method("show_inventory"):
			direct_manager.show_inventory(true, "🧊 NEVERA - MERCADO")
			print("✅ Nevera abierta usando fallback directo")
		else:
			print("❌ Fallback también falló")
