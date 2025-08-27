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
	total_value_label.text = "Valor total: 0💰"
	total_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_value_label.add_theme_color_override("font_color", Color.YELLOW)
	info_container.add_child(total_value_label)

	# Scroll container para el inventario
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	# Grid container para los peces (4 columnas para mejor aprovechamiento)
	inventory_grid = GridContainer.new()
	inventory_grid.columns = 4
	inventory_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_grid.add_theme_constant_override("h_separation", 10)
	inventory_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(inventory_grid)

	# Botones de venta
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	main_vbox.add_child(button_container)

	sell_selected_btn = Button.new()
	sell_selected_btn.text = "🛒 VENDER SELECCIONADOS"
	sell_selected_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_selected_btn.custom_minimum_size.y = 50
	sell_selected_btn.pressed.connect(_on_sell_selected_pressed)
	button_container.add_child(sell_selected_btn)

	sell_all_btn = Button.new()
	sell_all_btn.text = "💰 VENDER TODO"
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
	var max_count = 12 # TODO: obtener del sistema de mejoras

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
	var visible_slots = max(max_count, ((current_count / 4) + 2) * 4) # Mostrar al menos 2 filas extra
	var empty_slots = visible_slots - current_count
	for i in range(empty_slots):
		var empty_button = create_empty_slot()
		inventory_grid.add_child(empty_button)

func create_fish_button(fish_data: Dictionary, index: int) -> Button:
	var button = Button.new()
	var name = fish_data.get("name", "Pez")
	var size = fish_data.get("size", 0.0)
	var value = fish_data.get("value", 0)
	var rarity = fish_data.get("rarity", "common")

	# Formato del botón con información del pez
	button.text = "%s\n%.1fcm\n💰%d" % [name, size, value]
	button.custom_minimum_size = Vector2(140, 100)
	button.toggle_mode = true

	# Color según rareza
	match str(rarity).to_lower():
		"common":
			button.add_theme_color_override("font_color", Color.WHITE)
		"rare":
			button.add_theme_color_override("font_color", Color.CYAN)
		"epic":
			button.add_theme_color_override("font_color", Color.MAGENTA)
		"legendary":
			button.add_theme_color_override("font_color", Color.GOLD)

	button.pressed.connect(_on_fish_selected.bind(index, button))
	return button

func create_empty_slot() -> Control:
	var button = Button.new()
	button.text = "Vacío"
	button.custom_minimum_size = Vector2(140, 100)
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
