# MarketScreen - Sistema de mercado integrado con UnifiedInventorySystem
extends Control
class_name MarketScreen

# Señales
signal item_sold(item_instance: ItemInstance, price: int)
signal market_refreshed()
signal item_selected(item_instance: ItemInstance)
signal item_deselected(item_instance: ItemInstance)
signal fish_details_requested(item_instance: ItemInstance)

# Referencias a nodos
@onready var items_container: Control = $VBoxContainer/SellModeContainer/SellPanel/SellItemsContainer/ItemsList
@onready var sell_all_button: Button = $VBoxContainer/SellModeContainer/SellPanel/SellFilters/SellAllButton
# Nodos eliminados: money_label, inventory_counter, filter_rarity, filter_sort
var money_label: Label = null
var inventory_counter: Label = null
var filter_rarity: OptionButton = null
var filter_sort: OptionButton = null

# Variables para selección múltiple y filtros
var selected_items: Array[ItemInstance] = []
var current_filter_rarity: String = "all"
var current_sort_mode: String = "value_desc"
var current_filter_zone: String = "all"
var min_value_filter: int = 0
var max_value_filter: int = 999999
var show_only_selected: bool = false

# Referencias adicionales para filtros
@onready var filter_zone: OptionButton
@onready var value_range_container: HBoxContainer
@onready var min_value_input: SpinBox
@onready var max_value_input: SpinBox
@onready var selected_count_label: Label
@onready var sell_selected_button: Button
@onready var select_all_button: Button
@onready var deselect_all_button: Button

func _ready() -> void:
	print("[MARKET] _ready() - Inicializando pantalla de mercado.")
	
	# Verificar nodos críticos
	print("[MARKET] Verificando nodos...")
	print("[MARKET] - items_container: %s" % (items_container != null))
	print("[MARKET] - sell_all_button: %s" % (sell_all_button != null))
	
	if not UnifiedInventorySystem:
		print("[MARKET] ERROR: UnifiedInventorySystem no está disponible.")
		return

	# Conectar señales de botones principales
	if sell_all_button:
		sell_all_button.pressed.connect(_on_sell_all_pressed)
		print("[MARKET] Botón 'Vender Todo' conectado")
	
	# Buscar y conectar botones adicionales
	selected_count_label = find_child("SelectedCountLabel", true, false)
	sell_selected_button = find_child("SellSelectedButton", true, false)
	select_all_button = find_child("SelectAllButton", true, false)
	deselect_all_button = find_child("DeselectAllButton", true, false)
	filter_zone = find_child("FilterZone", true, false)
	min_value_input = find_child("MinValueInput", true, false)
	max_value_input = find_child("MaxValueInput", true, false)
	
	# Conectar botones de selección si existen
	if sell_selected_button:
		sell_selected_button.pressed.connect(_on_sell_selected_pressed)
	if select_all_button:
		select_all_button.pressed.connect(_on_select_all_pressed)
	if deselect_all_button:
		deselect_all_button.pressed.connect(_on_deselect_all_pressed)
	
	# Conectar filtros si existen
	if filter_rarity:
		filter_rarity.item_selected.connect(_on_rarity_filter_changed)
	if filter_zone:
		filter_zone.item_selected.connect(_on_zone_filter_changed)
	if filter_sort:
		filter_sort.item_selected.connect(_on_sort_changed)
	
	# Configurar filtros de valor
	if min_value_input:
		min_value_input.value_changed.connect(_on_min_value_changed)
	if max_value_input:
		max_value_input.value_changed.connect(_on_max_value_changed)
	
	# Conectar señal de inventario
	if UnifiedInventorySystem.has_signal("inventory_updated"):
		UnifiedInventorySystem.inventory_updated.connect(_on_inventory_updated)
		print("[MARKET] Señal inventory_updated conectada")
	else:
		print("[MARKET] ERROR: UnifiedInventorySystem no tiene señal inventory_updated")
	
	# Inicializar filtros
	_setup_filters()

func setup_market_screen() -> void:
	"""Método llamado por CentralHost para configurar la pantalla"""
	print("[MARKET] === CONFIGURANDO MARKET SCREEN ===")
	print("[MARKET] Save disponible: %s" % (Save != null))
	if Save:
		print("[MARKET] game_data disponible: %s" % (Save.game_data != null))
		if Save.game_data and Save.game_data.has("catches_database"):
			print("[MARKET] catches_database existe con %d entradas" % Save.game_data["catches_database"].size())
		else:
			print("[MARKET] catches_database NO existe")
	
	# Esperar un frame para asegurar que Save esté listo
	await get_tree().process_frame
	_refresh_market_view()
	print("[MARKET] Pantalla de mercado configurada.")

func _refresh_market_view() -> void:
	"""Refresca toda la vista del mercado: dinero e inventario."""
	print("[MARKET] Refrescando vista completa del mercado...")
	_update_money_display()
	_display_inventory_items()
	print("[MARKET] Vista del mercado refrescada")

func _on_inventory_updated(container_name: String) -> void:
	"""Se llama cuando el inventario de UnifiedInventorySystem cambia."""
	if container_name == "fishing":
		print("[MarketScreen] Recibida actualización del inventario de pesca.")
		_refresh_market_view()

func _update_money_display() -> void:
	"""Actualiza la etiqueta de dinero (deshabilitado - se usa TopBar)."""
	# No actualizar money_label ya que la información está en TopBar
	pass

func _display_inventory_items() -> void:
	"""Muestra los peces del inventario en la UI con filtros aplicados."""
	print("[MARKET] _display_inventory_items() iniciado")
	if not items_container:
		print("[MARKET] ERROR: El nodo 'ItemsList' para los items no se encuentra.")
		return
		
	# Limpiar vista anterior
	for child in items_container.get_children():
		child.queue_free()

	# Obtener capturas desde Save directamente
	if not Save or not Save.game_data.has("catches_database"):
		print("[MARKET] No hay datos de capturas")
		_show_empty_inventory_message()
		return

	# Filtrar capturas no vendidas
	var available_catches = []
	for catch_entry in Save.game_data["catches_database"]:
		if not catch_entry.get("is_sold", false) and catch_entry.get("in_inventory", true):
			available_catches.append(catch_entry)

	print("[MARKET] Capturas disponibles: %d" % available_catches.size())

	if available_catches.is_empty():
		print("[MARKET] Inventario vacío.")
		_show_empty_inventory_message()
		return

	# Crear ItemInstance desde cada captura y usar tarjetas existentes
	var filtered_items: Array[ItemInstance] = []
	for catch_entry in available_catches:
		var item_instance = ItemInstance.new()
		# Crear fish_data desde catch_entry
		var fish_data = {
			"id": catch_entry.get("fish_id", "unknown"),
			"name": catch_entry.get("fish_name", "Pez"),
			"size": catch_entry.get("size", 0.0),
			"weight": catch_entry.get("weight", 0.0),
			"value": catch_entry.get("value", 0),
			"rarity": catch_entry.get("rarity", "común"),
			"zone_caught": catch_entry.get("zone_caught", "desconocido")
		}
		item_instance.from_fish_data(fish_data)
		item_instance.instance_data["catch_id"] = catch_entry.get("id", "")
		
		if _item_passes_filters(item_instance):
			filtered_items.append(item_instance)
	
	if filtered_items.is_empty():
		print("[MARKET] No hay items que pasen los filtros actuales.")
		_show_no_results_message()
		return
	
	# Ordenar items
	filtered_items = _sort_items(filtered_items)
	
	print("[MARKET] Mostrando %d peces (de %d total) después de filtros." % [filtered_items.size(), available_catches.size()])
	
	# Usar las tarjetas existentes
	for item_instance in filtered_items:
		_create_item_card(item_instance)
	
	# Actualizar contador de inventario
	_update_inventory_counter(filtered_items.size(), available_catches.size())
	print("[MARKET] Items del inventario mostrados correctamente")

func _show_empty_inventory_message() -> void:
	"""Mostrar mensaje cuando el inventario está vacío"""
	var empty_container = VBoxContainer.new()
	empty_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var empty_icon = Label.new()
	empty_icon.text = "🎣"
	empty_icon.add_theme_font_size_override("font_size", 48)
	empty_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_container.add_child(empty_icon)
	
	var empty_label = Label.new()
	empty_label.text = "No tienes peces para vender."
	empty_label.add_theme_font_size_override("font_size", 18)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_container.add_child(empty_label)
	
	var suggestion_label = Label.new()
	suggestion_label.text = "¡Ve a pescar para llenar tu inventario!"
	suggestion_label.add_theme_font_size_override("font_size", 14)
	suggestion_label.add_theme_color_override("font_color", Color.GRAY)
	suggestion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_container.add_child(suggestion_label)
	
	items_container.add_child(empty_container)

func _show_no_results_message() -> void:
	"""Mostrar mensaje cuando no hay resultados para los filtros actuales"""
	var no_results_container = VBoxContainer.new()
	no_results_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var filter_icon = Label.new()
	filter_icon.text = "🔍"
	filter_icon.add_theme_font_size_override("font_size", 48)
	filter_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	no_results_container.add_child(filter_icon)
	
	var no_results_label = Label.new()
	no_results_label.text = "No se encontraron peces con los filtros actuales."
	no_results_label.add_theme_font_size_override("font_size", 16)
	no_results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	no_results_container.add_child(no_results_label)
	
	var suggestion_label = Label.new()
	suggestion_label.text = "Prueba ajustando los filtros o ve a pescar más."
	suggestion_label.add_theme_font_size_override("font_size", 12)
	suggestion_label.add_theme_color_override("font_color", Color.GRAY)
	suggestion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	no_results_container.add_child(suggestion_label)
	
	items_container.add_child(no_results_container)



func _create_item_card(item: ItemInstance) -> void:
	"""Crea una tarjeta visual profesional para un pez en el mercado."""
	var fish_def = item.get_item_def()
	if not fish_def:
		print("[MARKET] ERROR: No se pudo obtener fish_def para item")
		return

	# Contenedor principal de la tarjeta con fondo elegante
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 120)
	
	# Fondo sólido opaco para legibilidad
	var rarity = item.instance_data.get("rarity_bonus", "común")
	var card_bg = StyleBoxFlat.new()
	card_bg.bg_color = Color(0.1, 0.1, 0.1, 0.95)  # Fondo oscuro opaco
	card_bg.border_width_left = 3
	card_bg.border_width_right = 3
	card_bg.border_width_top = 3
	card_bg.border_width_bottom = 3
	card_bg.border_color = _get_rarity_color(rarity)
	card_bg.corner_radius_top_left = 8
	card_bg.corner_radius_top_right = 8
	card_bg.corner_radius_bottom_left = 8
	card_bg.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", card_bg)

	# Layout principal horizontal con más espacio
	var main_layout = HBoxContainer.new()
	main_layout.add_theme_constant_override("separation", 12)
	card.add_child(main_layout)

	# Checkbox para selección múltiple con estilo
	var selection_container = VBoxContainer.new()
	selection_container.alignment = BoxContainer.ALIGNMENT_CENTER
	var checkbox = CheckBox.new()
	checkbox.button_pressed = item in selected_items
	checkbox.toggled.connect(_on_item_checkbox_toggled.bind(item))
	selection_container.add_child(checkbox)
	main_layout.add_child(selection_container)



	# Icono del pez con marco
	var icon_frame = PanelContainer.new()
	var icon_frame_style = StyleBoxFlat.new()
	icon_frame_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	icon_frame_style.corner_radius_top_left = 6
	icon_frame_style.corner_radius_top_right = 6
	icon_frame_style.corner_radius_bottom_left = 6
	icon_frame_style.corner_radius_bottom_right = 6
	icon_frame.add_theme_stylebox_override("panel", icon_frame_style)
	icon_frame.custom_minimum_size = Vector2(80, 80)
	
	var icon = TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Cargar sprite del pez si existe
	if fish_def.sprite:
		icon.texture = fish_def.sprite
	else:
		# Placeholder con color de rareza
		var placeholder = ColorRect.new()
		placeholder.color = _get_rarity_color(rarity)
		placeholder.color.a = 0.5
		icon_frame.add_child(placeholder)
	icon_frame.add_child(icon)
	main_layout.add_child(icon_frame)

	# Información detallada del pez
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_container.add_theme_constant_override("separation", 4)
	main_layout.add_child(info_container)

	# Nombre con rareza destacada
	var name_container = HBoxContainer.new()
	info_container.add_child(name_container)
	
	var name_label = Label.new()
	name_label.text = fish_def.name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_container.add_child(name_label)
	
	var rarity_badge = Label.new()
	rarity_badge.text = "★ %s" % rarity.capitalize()
	rarity_badge.add_theme_font_size_override("font_size", 14)
	rarity_badge.add_theme_color_override("font_color", _get_rarity_color(rarity))
	name_container.add_child(rarity_badge)

	# Estadísticas organizadas
	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 16)
	stats_grid.add_theme_constant_override("v_separation", 2)
	info_container.add_child(stats_grid)
	
	# Tamaño
	var size_icon = Label.new()
	size_icon.text = "📏"
	stats_grid.add_child(size_icon)
	var size_label = Label.new()
	size_label.text = "%.1f cm" % item.instance_data.get("size", 0.0)
	size_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	stats_grid.add_child(size_label)
	
	# Peso
	var weight_icon = Label.new()
	weight_icon.text = "⚖️"
	stats_grid.add_child(weight_icon)
	var weight_label = Label.new()
	weight_label.text = "%.1f g" % item.instance_data.get("weight", 0.0)
	weight_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	stats_grid.add_child(weight_label)
	
	# Zona de captura
	var zone_icon = Label.new()
	zone_icon.text = "🗺️"
	stats_grid.add_child(zone_icon)
	var zone_label = Label.new()
	var zone_id = item.instance_data.get("capture_zone_id", "desconocida")
	zone_label.text = _get_zone_display_name(zone_id)
	zone_label.add_theme_font_size_override("font_size", 12)
	zone_label.add_theme_color_override("font_color", Color.GRAY)
	stats_grid.add_child(zone_label)

	# Panel de acciones reordenado
	var actions_container = VBoxContainer.new()
	actions_container.alignment = BoxContainer.ALIGNMENT_CENTER
	actions_container.add_theme_constant_override("separation", 6)
	main_layout.add_child(actions_container)
	
	# 1. Botón detalles arriba
	var details_button = Button.new()
	details_button.text = "ℹ️ Detalles"
	details_button.custom_minimum_size = Vector2(100, 30)
	details_button.pressed.connect(_on_fish_details_pressed.bind(item))
	actions_container.add_child(details_button)
	
	# 2. Precio en el medio
	var price_panel = PanelContainer.new()
	var price_style = StyleBoxFlat.new()
	price_style.bg_color = Color(0.8, 0.6, 0.0, 0.3)
	price_style.border_width_left = 2
	price_style.border_width_right = 2
	price_style.border_width_top = 2
	price_style.border_width_bottom = 2
	price_style.border_color = Color.GOLD
	price_style.corner_radius_top_left = 4
	price_style.corner_radius_top_right = 4
	price_style.corner_radius_bottom_left = 4
	price_style.corner_radius_bottom_right = 4
	price_panel.add_theme_stylebox_override("panel", price_style)
	
	var price_container = VBoxContainer.new()
	price_container.alignment = BoxContainer.ALIGNMENT_CENTER
	price_panel.add_child(price_container)
	
	var coin_icon = Label.new()
	coin_icon.text = "💰"
	coin_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_container.add_child(coin_icon)
	
	var value_label = Label.new()
	var sell_price = item.instance_data.get("value", 0)
	value_label.text = str(sell_price)
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", Color.GOLD)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_container.add_child(value_label)
	
	actions_container.add_child(price_panel)
	
	# 3. Botón vender abajo
	var sell_button = Button.new()
	sell_button.text = "💰 Vender"
	sell_button.custom_minimum_size = Vector2(100, 36)
	var sell_style = StyleBoxFlat.new()
	sell_style.bg_color = Color(0.2, 0.7, 0.2, 0.8)
	sell_style.corner_radius_top_left = 4
	sell_style.corner_radius_top_right = 4
	sell_style.corner_radius_bottom_left = 4
	sell_style.corner_radius_bottom_right = 4
	sell_button.add_theme_stylebox_override("normal", sell_style)
	sell_button.pressed.connect(_on_sell_one_pressed.bind(item))
	actions_container.add_child(sell_button)

	items_container.add_child(card)
	print("[MARKET] Tarjeta profesional mejorada creada para: %s" % fish_def.name)

func _on_sell_one_pressed(item_to_sell: ItemInstance) -> void:
	"""Vende un único pez."""
	var catch_id = item_to_sell.instance_data.get("catch_id", "")
	var value = item_to_sell.get_market_value()
	
	print("[MarketScreen] Vendiendo: %s (ID: %s) por %d" % [item_to_sell.get_display_name(), catch_id, value])
	
	if catch_id != "" and Save and Save.mark_catch_as_sold(catch_id, value):
		Save.add_coins(value)
		Save.save_game()
		_refresh_market_view()
	else:
		print("[MarketScreen] ERROR: No se pudo vender")

func _on_sell_all_pressed() -> void:
	"""Vende todos los peces del inventario de pesca."""
	print("[MarketScreen] Intentando vender todos los peces...")
	UnifiedInventorySystem.sell_all_fish()



func _on_fish_details_pressed(item: ItemInstance) -> void:
	"""Mostrar detalles del pez en ventana flotante"""
	fish_details_requested.emit(item)
	_create_fish_details_popup(item)

func _create_fish_details_popup(item: ItemInstance) -> void:
	"""Crear ventana flotante con detalles completos del pez"""
	var fish_def = item.get_item_def()
	if not fish_def:
		return
	
	# Overlay de fondo
	var overlay = Control.new()
	overlay.name = "FishDetailsOverlay"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.z_index = 1000
	
	# Fondo semi-transparente clickeable
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			overlay.queue_free()
	)
	overlay.add_child(background)
	
	# Panel principal de detalles
	var details_panel = PanelContainer.new()
	details_panel.custom_minimum_size = Vector2(600, 500)
	details_panel.position = Vector2(
		(get_viewport().get_visible_rect().size.x - 600) / 2,
		(get_viewport().get_visible_rect().size.y - 500) / 2
	)
	
	# Estilo del panel
	var panel_style = StyleBoxFlat.new()
	var rarity = item.instance_data.get("rarity_bonus", "común")
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = _get_rarity_color(rarity)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	details_panel.add_theme_stylebox_override("panel", panel_style)
	
	overlay.add_child(details_panel)
	
	# Contenido principal
	var main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 16)
	details_panel.add_child(main_container)
	
	# Header con botón de cierre
	var header = HBoxContainer.new()
	main_container.add_child(header)
	
	var title_label = Label.new()
	title_label.text = "Detalles del Pez"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	
	var close_button = Button.new()
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(40, 40)
	close_button.pressed.connect(func(): overlay.queue_free())
	header.add_child(close_button)
	
	# Contenido principal en dos columnas
	var content_container = HBoxContainer.new()
	content_container.add_theme_constant_override("separation", 20)
	main_container.add_child(content_container)
	
	# Columna izquierda - Imagen y nombre
	var left_column = VBoxContainer.new()
	left_column.custom_minimum_size.x = 250
	content_container.add_child(left_column)
	
	# Imagen del pez
	var fish_image_frame = PanelContainer.new()
	var image_style = StyleBoxFlat.new()
	image_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	image_style.corner_radius_top_left = 8
	image_style.corner_radius_top_right = 8
	image_style.corner_radius_bottom_left = 8
	image_style.corner_radius_bottom_right = 8
	fish_image_frame.add_theme_stylebox_override("panel", image_style)
	fish_image_frame.custom_minimum_size = Vector2(200, 200)
	
	var fish_image = TextureRect.new()
	fish_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	fish_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if fish_def.sprite:
		fish_image.texture = fish_def.sprite
	fish_image_frame.add_child(fish_image)
	left_column.add_child(fish_image_frame)
	
	# Nombre y rareza
	var name_container = VBoxContainer.new()
	name_container.alignment = BoxContainer.ALIGNMENT_CENTER
	left_column.add_child(name_container)
	
	var fish_name = Label.new()
	fish_name.text = fish_def.name
	fish_name.add_theme_font_size_override("font_size", 28)
	fish_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_container.add_child(fish_name)
	
	var rarity_label = Label.new()
	rarity_label.text = "★ %s ★" % rarity.capitalize()
	rarity_label.add_theme_font_size_override("font_size", 18)
	rarity_label.add_theme_color_override("font_color", _get_rarity_color(rarity))
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_container.add_child(rarity_label)
	
	# Columna derecha - Estadísticas detalladas
	var right_column = VBoxContainer.new()
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.add_theme_constant_override("separation", 12)
	content_container.add_child(right_column)
	
	# Estadísticas de captura
	var capture_stats = _create_stats_section("Estadísticas de Captura", [
		["Tamaño", "%.1f cm" % item.instance_data.get("size", 0.0), Color.LIGHT_BLUE],
		["Peso", "%.1f g" % item.instance_data.get("weight", 0.0), Color.LIGHT_GREEN],
		["Zona", item.instance_data.get("capture_zone_id", "Desconocida").capitalize(), Color.CYAN],
		["Valor", "%d monedas" % item.instance_data.get("value", 0), Color.GOLD]
	])
	right_column.add_child(capture_stats)
	
	# Información de la especie
	var species_stats = _create_stats_section("Información de la Especie", [
		["Tamaño Mínimo", "%.1f cm" % fish_def.size_min, Color.WHITE],
		["Tamaño Máximo", "%.1f cm" % fish_def.size_max, Color.WHITE],
		["Valor Base", "%d monedas" % fish_def.base_market_value, Color.WHITE],
		["Rareza Base", str(fish_def.rarity), Color.WHITE]
	])
	right_column.add_child(species_stats)
	
	# Descripción si existe
	if fish_def.description and fish_def.description != "":
		var description_section = _create_description_section(fish_def.description)
		right_column.add_child(description_section)
	
	# Botones de acción
	var actions_container = HBoxContainer.new()
	actions_container.alignment = BoxContainer.ALIGNMENT_CENTER
	actions_container.add_theme_constant_override("separation", 12)
	main_container.add_child(actions_container)
	
	var sell_button = Button.new()
	sell_button.text = "💰 Vender por %d monedas" % item.instance_data.get("value", 0)
	sell_button.custom_minimum_size = Vector2(200, 40)
	var sell_style = StyleBoxFlat.new()
	sell_style.bg_color = Color(0.2, 0.7, 0.2, 0.8)
	sell_style.corner_radius_top_left = 6
	sell_style.corner_radius_top_right = 6
	sell_style.corner_radius_bottom_left = 6
	sell_style.corner_radius_bottom_right = 6
	sell_button.add_theme_stylebox_override("normal", sell_style)
	sell_button.pressed.connect(func(): 
		_on_sell_one_pressed(item)
		overlay.queue_free()
	)
	actions_container.add_child(sell_button)
	
	var close_details_button = Button.new()
	close_details_button.text = "Cerrar"
	close_details_button.custom_minimum_size = Vector2(100, 40)
	close_details_button.pressed.connect(func(): overlay.queue_free())
	actions_container.add_child(close_details_button)
	
	# Añadir al árbol de escena
	get_tree().current_scene.add_child(overlay)

func _create_stats_section(title: String, stats: Array) -> Control:
	"""Crear sección de estadísticas"""
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	
	var section_title = Label.new()
	section_title.text = title
	section_title.add_theme_font_size_override("font_size", 18)
	section_title.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	section.add_child(section_title)
	
	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 20)
	stats_grid.add_theme_constant_override("v_separation", 4)
	section.add_child(stats_grid)
	
	for stat in stats:
		var label = Label.new()
		label.text = stat[0] + ":"
		label.add_theme_font_size_override("font_size", 14)
		stats_grid.add_child(label)
		
		var value = Label.new()
		value.text = stat[1]
		value.add_theme_font_size_override("font_size", 14)
		value.add_theme_color_override("font_color", stat[2])
		stats_grid.add_child(value)
	
	return section

func _create_description_section(description: String) -> Control:
	"""Crear sección de descripción"""
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	
	var section_title = Label.new()
	section_title.text = "Descripción"
	section_title.add_theme_font_size_override("font_size", 18)
	section_title.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	section.add_child(section_title)
	
	var desc_label = Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.x = 300
	section.add_child(desc_label)
	
	return section



func _get_rarity_color(rarity: String) -> Color:
	"""Obtener color basado en rareza del pez"""
	match rarity.to_lower():
		"común", "common":
			return Color.WHITE
		"poco_común", "uncommon":
			return Color.GREEN
		"raro", "rare":
			return Color.BLUE
		"épico", "epic":
			return Color.PURPLE
		"legendario", "legendary":
			return Color.ORANGE
		_:
			return Color.WHITE







func setup_market(money: int, gems: int, sell_items: Array, buy_items: Array) -> void:
	"""Método de compatibilidad para configuración con parámetros"""
	print("[MARKET] setup_market() llamado con %d items para vender" % sell_items.size())
	setup_market_screen()

func _update_inventory_counter(filtered_count: int, total_count: int) -> void:
	"""Actualizar contador de inventario"""
	# Crear contador si no existe
	if not inventory_counter:
		inventory_counter = Label.new()
		inventory_counter.add_theme_font_size_override("font_size", 16)
		inventory_counter.add_theme_color_override("font_color", Color.WHITE)
		inventory_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# Añadir al contenedor principal
		var main_container = get_node("VBoxContainer")
		if main_container:
			main_container.add_child(inventory_counter)
			main_container.move_child(inventory_counter, 0)  # Poner al principio
	
	# Obtener capacidad del inventario
	var fishing_container = UnifiedInventorySystem.get_fishing_container()
	var max_capacity = fishing_container.capacity if fishing_container else 20
	
	if filtered_count == total_count:
		inventory_counter.text = "Inventario: %d/%d peces" % [total_count, max_capacity]
	else:
		inventory_counter.text = "Mostrando: %d de %d/%d peces" % [filtered_count, total_count, max_capacity]
	
	# Cambiar color según capacidad
	var usage_percent = float(total_count) / float(max_capacity)
	if usage_percent >= 1.0:
		inventory_counter.add_theme_color_override("font_color", Color.RED)
	elif usage_percent >= 0.8:
		inventory_counter.add_theme_color_override("font_color", Color.ORANGE)
	else:
		inventory_counter.add_theme_color_override("font_color", Color.WHITE)

func _on_item_checkbox_toggled(pressed: bool, item: ItemInstance) -> void:
	"""Manejar selección/deselección de items"""
	if pressed:
		if item not in selected_items:
			selected_items.append(item)
			item_selected.emit(item)
	else:
		selected_items.erase(item)
		item_deselected.emit(item)
	
	_update_selection_ui()

func _update_selection_ui() -> void:
	"""Actualizar UI basada en selección actual"""
	var selection_count = selected_items.size()
	var total_value = 0
	
	# Calcular valor total de items seleccionados
	for item in selected_items:
		total_value += item.instance_data.get("value", 0)
	
	# Actualizar contador de selección
	if selected_count_label:
		if selection_count > 0:
			selected_count_label.text = "Seleccionados: %d (%d monedas)" % [selection_count, total_value]
			selected_count_label.add_theme_color_override("font_color", Color.GOLD)
		else:
			selected_count_label.text = "Ningún item seleccionado"
			selected_count_label.add_theme_color_override("font_color", Color.GRAY)
	
	# Actualizar botones
	if sell_selected_button:
		if selection_count > 0:
			sell_selected_button.text = "Vender Seleccionados (%d)" % selection_count
			sell_selected_button.disabled = false
		else:
			sell_selected_button.text = "Vender Seleccionados"
			sell_selected_button.disabled = true
	
	if deselect_all_button:
		deselect_all_button.disabled = selection_count == 0
	
	# Actualizar botón principal
	if sell_all_button:
		if selection_count > 0:
			sell_all_button.text = "Vender Todo (excepto seleccionados)"
		else:
			sell_all_button.text = "Vender Todo"

func _setup_filters() -> void:
	"""Configurar opciones de filtros"""
	# Configurar filtro de rareza
	if filter_rarity:
		filter_rarity.clear()
		filter_rarity.add_item("Todas las rarezas")
		filter_rarity.add_item("Común")
		filter_rarity.add_item("Raro")
		filter_rarity.add_item("Épico")
		filter_rarity.add_item("Legendario")
	
	# Configurar filtro de zona
	if filter_zone:
		filter_zone.clear()
		filter_zone.add_item("Todas las zonas")
		# Añadir zonas dinámicamente desde el inventario
		_populate_zone_filter()
	
	# Configurar filtro de ordenamiento
	if filter_sort:
		filter_sort.clear()
		filter_sort.add_item("Valor (Mayor a Menor)")
		filter_sort.add_item("Valor (Menor a Mayor)")
		filter_sort.add_item("Tamaño (Mayor a Menor)")
		filter_sort.add_item("Tamaño (Menor a Mayor)")
		filter_sort.add_item("Rareza")
		filter_sort.add_item("Nombre (A-Z)")
		filter_sort.add_item("Zona")

func _populate_zone_filter() -> void:
	"""Poblar filtro de zonas con zonas disponibles en el inventario"""
	if not filter_zone or not UnifiedInventorySystem:
		return
	
	var fishing_container = UnifiedInventorySystem.get_fishing_container()
	if not fishing_container:
		return
	
	var zones_found = {}
	for item in fishing_container.items:
		var zone = item.instance_data.get("capture_zone_id", "Desconocida")
		if zone not in zones_found:
			zones_found[zone] = true
			filter_zone.add_item(zone.capitalize())

func _on_rarity_filter_changed(index: int) -> void:
	"""Manejar cambio de filtro de rareza"""
	match index:
		0: current_filter_rarity = "all"
		1: current_filter_rarity = "común"
		2: current_filter_rarity = "raro"
		3: current_filter_rarity = "épico"
		4: current_filter_rarity = "legendario"
	_refresh_market_view()

func _on_zone_filter_changed(index: int) -> void:
	"""Manejar cambio de filtro de zona"""
	if index == 0:
		current_filter_zone = "all"
	else:
		current_filter_zone = filter_zone.get_item_text(index).to_lower()
	_refresh_market_view()

func _on_sort_changed(index: int) -> void:
	"""Manejar cambio de ordenamiento"""
	match index:
		0: current_sort_mode = "value_desc"
		1: current_sort_mode = "value_asc"
		2: current_sort_mode = "size_desc"
		3: current_sort_mode = "size_asc"
		4: current_sort_mode = "rarity"
		5: current_sort_mode = "name"
		6: current_sort_mode = "zone"
	_refresh_market_view()

func _on_min_value_changed(value: float) -> void:
	"""Manejar cambio de valor mínimo"""
	min_value_filter = int(value)
	_refresh_market_view()

func _on_max_value_changed(value: float) -> void:
	"""Manejar cambio de valor máximo"""
	max_value_filter = int(value)
	_refresh_market_view()

func _on_select_all_pressed() -> void:
	"""Seleccionar todos los items visibles"""
	var fishing_container = UnifiedInventorySystem.get_fishing_container()
	if not fishing_container:
		return
	
	selected_items.clear()
	for item in fishing_container.items:
		if _item_passes_filters(item):
			selected_items.append(item)
	
	_refresh_market_view()
	_update_selection_ui()

func _on_deselect_all_pressed() -> void:
	"""Deseleccionar todos los items"""
	selected_items.clear()
	_refresh_market_view()
	_update_selection_ui()

func _on_sell_selected_pressed() -> void:
	"""Vender items seleccionados"""
	if selected_items.is_empty():
		return
	
	var total_value = 0
	for item in selected_items:
		total_value += item.instance_data.get("value", 0)
		UnifiedInventorySystem.sell_item(item)
	
	selected_items.clear()
	print("[MARKET] Vendidos items seleccionados por %d monedas" % total_value)

func _item_passes_filters(item: ItemInstance) -> bool:
	"""Verificar si un item pasa todos los filtros activos"""
	# Filtro de rareza
	if current_filter_rarity != "all":
		var item_rarity = item.instance_data.get("rarity_bonus", "común")
		if item_rarity != current_filter_rarity:
			return false
	
	# Filtro de zona
	if current_filter_zone != "all":
		var item_zone = item.instance_data.get("capture_zone_id", "desconocida").to_lower()
		if item_zone != current_filter_zone:
			return false
	
	# Filtro de valor
	var item_value = item.instance_data.get("value", 0)
	if item_value < min_value_filter or item_value > max_value_filter:
		return false
	
	# Filtro de solo seleccionados
	if show_only_selected and item not in selected_items:
		return false
	
	return true

func _sort_items(items: Array[ItemInstance]) -> Array[ItemInstance]:
	"""Ordenar items según el modo de ordenamiento actual"""
	var sorted_items = items.duplicate()
	
	match current_sort_mode:
		"value_desc":
			sorted_items.sort_custom(func(a, b): return a.instance_data.get("value", 0) > b.instance_data.get("value", 0))
		"value_asc":
			sorted_items.sort_custom(func(a, b): return a.instance_data.get("value", 0) < b.instance_data.get("value", 0))
		"size_desc":
			sorted_items.sort_custom(func(a, b): return a.instance_data.get("size", 0.0) > b.instance_data.get("size", 0.0))
		"size_asc":
			sorted_items.sort_custom(func(a, b): return a.instance_data.get("size", 0.0) < b.instance_data.get("size", 0.0))
		"name":
			sorted_items.sort_custom(func(a, b): return a.get_item_def().name < b.get_item_def().name)
		"zone":
			sorted_items.sort_custom(func(a, b): return a.instance_data.get("capture_zone_id", "") < b.instance_data.get("capture_zone_id", ""))
		"rarity":
			var rarity_order = {"común": 0, "raro": 1, "épico": 2, "legendario": 3}
			sorted_items.sort_custom(func(a, b): 
				var a_rarity = rarity_order.get(a.instance_data.get("rarity_bonus", "común"), 0)
				var b_rarity = rarity_order.get(b.instance_data.get("rarity_bonus", "común"), 0)
				return a_rarity > b_rarity
			)
	
	return sorted_items

func _get_zone_display_name(zone_id: String) -> String:
	"""Convertir ID de zona a nombre bonito"""
	var zone_names = {
		"lago_montana_alpes": "Lagos de Montaña - Alpes",
		"grandes_lagos_norteamerica": "Grandes Lagos de Norteamérica",
		"costas_atlanticas": "Costas Atlánticas",
		"rios_amazonicos": "Ríos Amazónicos",
		"oceanos_profundos": "Océanos Profundos",
		"orilla": "Orilla",
		"lago": "Lago",
		"rio": "Río",
		"costa": "Costa",
		"mar": "Mar",
		"glaciar": "Glaciar",
		"industrial": "Industrial",
		"abismo": "Abismo",
		"infernal": "Infernal"
	}
	return zone_names.get(zone_id, zone_id.capitalize().replace("_", " "))

