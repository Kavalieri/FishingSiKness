class_name MarketViewNew
extends Control

# Variables para la UI
var inventory_grid: GridContainer
var sell_selected_btn: Button
var sell_all_btn: Button
var capacity_label: Label
var total_value_label: Label

# Variables de estado
var selected_fish_indices := []

func _ready():
	setup_background()
	setup_ui()
	# Conectar señal de visibilidad para refrescar cuando se muestre
	visibility_changed.connect(_on_visibility_changed)

	# Conectar a señales de Save para actualización automática
	if Save:
		Save.game_data_changed.connect(_on_save_data_changed)
		Save.inventory_changed.connect(refresh_display)
		Save.coins_changed.connect(_on_coins_changed)

func _on_save_data_changed():
	"""Actualizar completamente la vista cuando cambien los datos de guardado"""
	refresh_display()

func _on_coins_changed(new_amount: int):
	"""Actualizar información de monedas cuando cambien"""
	refresh_display()

func setup_background():
	"""Configurar fondo usando BackgroundManager"""
	if BackgroundManager:
		BackgroundManager.setup_main_background(self)
		print("✅ Fondo principal configurado en MarketView")
	else:
		print("⚠️ BackgroundManager no disponible en MarketView")

func setup_ui():
	# Crear la interfaz principal
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)
	main_vbox.anchor_right = 1.0
	main_vbox.anchor_bottom = 1.0
	main_vbox.offset_left = 20
	main_vbox.offset_right = -20
	main_vbox.offset_top = 20
	main_vbox.offset_bottom = -20

	# Título del mercado
	var title = Label.new()
	title.text = "🏪 MERCADO DE PECES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.GOLD)
	main_vbox.add_child(title)

	# Separador
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 10
	main_vbox.add_child(separator)

	# Información del inventario
	var info_container = HBoxContainer.new()
	main_vbox.add_child(info_container)

	capacity_label = Label.new()
	capacity_label.text = "Inventario: 0/12"
	capacity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.add_child(capacity_label)

	total_value_label = Label.new()
	total_value_label.text = "Valor total: 0 COINS"
	total_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_value_label.add_theme_color_override("font_color", Color.YELLOW)
	info_container.add_child(total_value_label)

	# Scroll container para el inventario
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	# Grid container para los peces (3 columnas para mejor espacio)
	inventory_grid = GridContainer.new()
	inventory_grid.columns = 3
	inventory_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_grid.add_theme_constant_override("h_separation", 15)
	inventory_grid.add_theme_constant_override("v_separation", 15)
	scroll.add_child(inventory_grid)

	# Botones de venta
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	main_vbox.add_child(button_container)

	sell_selected_btn = Button.new()
	sell_selected_btn.text = "VENDER SELECCIONADOS"
	sell_selected_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_selected_btn.custom_minimum_size.y = 50
	sell_selected_btn.pressed.connect(_on_sell_selected_pressed)
	button_container.add_child(sell_selected_btn)

	sell_all_btn = Button.new()
	sell_all_btn.text = "VENDER TODO"
	sell_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_all_btn.custom_minimum_size.y = 50
	sell_all_btn.pressed.connect(_on_sell_all_pressed)
	button_container.add_child(sell_all_btn)

func _on_visibility_changed():
	if visible:
		refresh_display()

func refresh_display():
	print("🔄 MarketView: Refreshing display...")
	if not inventory_grid:
		return

	# Limpiar grid
	for child in inventory_grid.get_children():
		child.queue_free()

	selected_fish_indices.clear()

	# Obtener inventario del InventorySystem
	var inventory = InventorySystem.get_inventory()
	var current_count = inventory.size()
	# Obtener capacidad real del sistema de mejoras
	var max_count = Save.game_data.get("max_inventory", 12)

	# Actualizar etiquetas de información
	capacity_label.text = "Inventario: %d/%d peces" % [current_count, max_count]

	# Calcular valor total
	var total_value = 0
	for fish_data in inventory:
		total_value += fish_data.get("value", 0)
	total_value_label.text = "Valor total: %d💰" % total_value

	print("🐟 MarketView: Loading %d fish" % current_count)

	# Añadir peces al grid
	for i in range(current_count):
		var fish_data = inventory[i]
		var fish_button = create_fish_button(fish_data, i)
		inventory_grid.add_child(fish_button)

	# Llenar espacios vacíos hasta completar algunas filas
	var visible_slots = max(max_count, ((current_count / 3) + 2) * 3) # Mostrar al menos 2 filas extra para 3 columnas
	var empty_slots = visible_slots - current_count
	for i in range(empty_slots):
		var empty_button = create_empty_slot()
		inventory_grid.add_child(empty_button)

func create_fish_button(fish_data: Dictionary, index: int) -> Button:
	var button = Button.new()
	var name = fish_data.get("name", "Pez")
	var size = fish_data.get("size", 0.0)
	var value = fish_data.get("value", 0)
	var rarity = fish_data.get("rarity", "común")

	# Debug: imprimir rareza para verificar valores
	print("MarketView: Fish %s has rarity: '%s' (type: %s)" % [name, rarity, typeof(rarity)])

	# Crear un VBoxContainer para organizar el contenido
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.add_child(vbox)

	# Contenedor superior con sprite y botón info
	var top_container = HBoxContainer.new()
	top_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_container)

	# Cargar y mostrar el sprite del pescado
	var fish_sprite = TextureRect.new()
	# Manejar casos especiales con tildes y caracteres especiales
	var sprite_name = name.to_lower()
	sprite_name = sprite_name.replace("ó", "o").replace("á", "a").replace("é", "e").replace("í", "i").replace("ú", "u")
	var sprite_path = "res://art/fish/%s.png" % sprite_name
	var texture = load(sprite_path)
	if texture:
		fish_sprite.texture = texture
		fish_sprite.custom_minimum_size = Vector2(60, 60)
		fish_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		fish_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fish_sprite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_container.add_child(fish_sprite)

	# Botón de información detallada (esquina superior derecha)
	var info_button = Button.new()
	info_button.text = "ℹ️"
	info_button.custom_minimum_size = Vector2(20, 20)
	info_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	info_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_button.pressed.connect(_on_fish_info_pressed.bind(fish_data))
	top_container.add_child(info_button)

	# Información del pez
	var info_label = Label.new()
	info_label.text = "%s\n%.1fcm\n💰%d" % [name, size, value]
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info_label)

	button.custom_minimum_size = Vector2(180, 140)
	button.toggle_mode = true

	# Crear Panel con borde de rareza
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.9) # Fondo semi-transparente
	style_box.border_width_left = 4
	style_box.border_width_right = 4
	style_box.border_width_top = 4
	style_box.border_width_bottom = 4
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8

	# Color del borde según rareza
	var border_color: Color
	var rarity_name: String

	# Mapear valores numéricos a nombres de rareza
	var rarity_value = rarity if typeof(rarity) == TYPE_FLOAT or typeof(rarity) == TYPE_INT else 0
	match rarity_value:
		0, 0.0:
			rarity_name = "común"
			border_color = Color.WHITE
		1, 1.0:
			rarity_name = "rara"
			border_color = Color.BLUE
		2, 2.0:
			rarity_name = "épica"
			border_color = Color.PURPLE
		3, 3.0:
			rarity_name = "legendaria"
			border_color = Color.ORANGE
		_:
			rarity_name = str(rarity).to_lower()
			# Fallback para strings
			match rarity_name:
				"común":
					border_color = Color.WHITE
				"rara":
					border_color = Color.BLUE
				"épica":
					border_color = Color.PURPLE
				"legendaria":
					border_color = Color.ORANGE
				_:
					border_color = Color.GRAY

	# Mantener texto en blanco para legibilidad
	info_label.add_theme_color_override("font_color", Color.WHITE)

	style_box.border_color = border_color
	button.add_theme_stylebox_override("normal", style_box)

	# Stylebox para cuando está presionado
	var style_box_pressed = style_box.duplicate()
	style_box_pressed.bg_color = Color(0.3, 0.3, 0.3, 1.0)
	button.add_theme_stylebox_override("pressed", style_box_pressed)

	button.pressed.connect(_on_fish_selected.bind(index, button))
	return button

func create_empty_slot() -> Control:
	var button = Button.new()
	button.text = "Vacío"
	button.custom_minimum_size = Vector2(180, 140) # Mismo tamaño que las tarjetas de peces
	button.disabled = true
	button.add_theme_color_override("font_color", Color.GRAY)
	return button

func _on_fish_selected(index: int, button: Button):
	if button.button_pressed:
		selected_fish_indices.append(index)
	else:
		selected_fish_indices.erase(index)

	# Actualizar botón de vender selección
	if selected_fish_indices.size() > 0:
		sell_selected_btn.text = "🛒 VENDER SELECCIONADOS (%d)" % selected_fish_indices.size()
	else:
		sell_selected_btn.text = "🛒 VENDER SELECCIONADOS"

func _on_sell_selected_pressed():
	if selected_fish_indices.size() == 0:
		return

	print("MarketView: Selling %d selected fish" % selected_fish_indices.size())
	var total_earned = InventorySystem.sell_fishes(selected_fish_indices)
	print("MarketView: Earned %d coins from sale" % total_earned)
	print("MarketView: Current coins after sale: %d" % Save.get_coins())

	# Actualizar la TopBar para mostrar las nuevas monedas
	var screen_manager = get_tree().current_scene
	print("MarketView: Screen manager found: ", screen_manager != null)
	if screen_manager:
		# La TopBar está dentro del nodo Main, no directamente en el ScreenManager
		var top_bar = screen_manager.get_node_or_null("Main/TopBar")
		print("MarketView: TopBar found: ", top_bar != null)
		if top_bar and top_bar.has_method("update_display"):
			top_bar.update_display()
			print("✅ TopBar actualizada después de la venta")
		else:
			print("❌ TopBar no encontrada o no tiene update_display()")

	if SFX:
		SFX.play_event("success")

	refresh_display()

func _on_sell_all_pressed():
	var inventory = InventorySystem.get_inventory()
	if inventory.size() == 0:
		return

	print("MarketView: Selling all %d fish" % inventory.size())
	# Crear array con todos los índices
	var all_indices = []
	for i in range(inventory.size()):
		all_indices.append(i)

	var total_earned = InventorySystem.sell_fishes(all_indices)
	print("MarketView: Earned %d coins from selling all fish" % total_earned)
	print("MarketView: Current coins after sale: %d" % Save.get_coins())

	# Actualizar la TopBar para mostrar las nuevas monedas
	var screen_manager = get_tree().current_scene
	print("MarketView: Screen manager found: ", screen_manager != null)
	if screen_manager:
		# La TopBar está dentro del nodo Main, no directamente en el ScreenManager
		var top_bar = screen_manager.get_node_or_null("Main/TopBar")
		print("MarketView: TopBar found: ", top_bar != null)
		if top_bar and top_bar.has_method("update_display"):
			top_bar.update_display()
			print("✅ TopBar actualizada después de la venta")
		else:
			print("❌ TopBar no encontrada o no tiene update_display()")

	if SFX:
		SFX.play_event("success")

	refresh_display()

func _on_fish_info_pressed(fish_data: Dictionary):
	"""Mostrar información detallada del pescado en una ventana flotante"""
	show_fish_detail_dialog(fish_data)

func show_fish_detail_dialog(fish_data: Dictionary):
	"""Crear y mostrar ventana flotante con información detallada del pescado"""

	# Determinar la rareza correcta ANTES de usarla
	var rarity = fish_data.get("rarity", "común")
	var rarity_name: String = "común" # Valor por defecto

	# Mapear valores numéricos a nombres de rareza
	if typeof(rarity) == TYPE_FLOAT or typeof(rarity) == TYPE_INT:
		match rarity:
			0, 0.0:
				rarity_name = "común"
			1, 1.0:
				rarity_name = "rara"
			2, 2.0:
				rarity_name = "épica"
			3, 3.0:
				rarity_name = "legendaria"
			_:
				rarity_name = "común"
	else:
		rarity_name = str(rarity).to_lower()

	# Crear ventana flotante
	var dialog = AcceptDialog.new()
	dialog.title = "🐟 Información Detallada"
	dialog.size = Vector2(400, 350)
	dialog.popup_window = true

	# Contenido principal
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)

	# Sprite del pescado (más grande)
	var fish_sprite = TextureRect.new()
	# Manejar casos especiales con tildes y caracteres especiales
	var sprite_name = fish_data.get("name", "").to_lower()
	sprite_name = sprite_name.replace("ó", "o").replace("á", "a").replace("é", "e").replace("í", "i").replace("ú", "u")
	var sprite_path = "res://art/fish/%s.png" % sprite_name
	var texture = load(sprite_path)
	if texture:
		fish_sprite.texture = texture
		fish_sprite.custom_minimum_size = Vector2(100, 100)
		fish_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		fish_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(fish_sprite)

	# Información básica
	var title_label = Label.new()
	title_label.text = fish_data.get("name", "Pez Desconocido")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title_label)

	# Datos específicos (ahora rarity_name ya tiene el valor correcto)
	var info_text = """
📏 Tamaño: %.1f cm
💰 Valor: %d monedas
🌟 Rareza: %s
🎣 Peso: %.1f kg
📍 Zona de captura: %s
📅 Capturado: %s
📝 Descripción: %s
""" % [
		fish_data.get("size", 0.0),
		fish_data.get("value", 0),
		rarity_name.capitalize(),
		fish_data.get("weight", 0.0),
		fish_data.get("capture_zone_id", "Desconocida"),
		Time.get_datetime_string_from_unix_time(fish_data.get("timestamp", 0)),
		fish_data.get("description", "Sin descripción disponible")
	]

	var info_label = RichTextLabel.new()
	info_label.text = info_text.strip_edges()
	info_label.fit_content = true
	info_label.custom_minimum_size.y = 200
	vbox.add_child(info_label)

	# Aplicar color del título según rareza
	match rarity_name:
		"común":
			title_label.add_theme_color_override("font_color", Color.WHITE)
		"rara":
			title_label.add_theme_color_override("font_color", Color.BLUE)
		"épica":
			title_label.add_theme_color_override("font_color", Color.PURPLE)
		"legendaria":
			title_label.add_theme_color_override("font_color", Color.ORANGE)
		_:
			title_label.add_theme_color_override("font_color", Color.WHITE)

	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered()

	# Auto-eliminar cuando se cierre
	dialog.confirmed.connect(func(): dialog.queue_free())
	dialog.close_requested.connect(func(): dialog.queue_free())
