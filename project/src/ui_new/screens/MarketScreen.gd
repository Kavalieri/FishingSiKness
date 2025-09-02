# MarketScreen - Sistema completo de mercado integrado con UnifiedInventorySystem
extends Control

# Señales
signal item_sold(fish_data: Dictionary, price: int)
signal market_refreshed()

# Enums
enum MarketMode {SELL, BUY}

# Constants
const SELL_MULTIPLIER = 0.8

# Variables de estado
var current_mode: MarketMode = MarketMode.SELL

func _init() -> void:
	print("[MarketScreen] _init() llamado - Script inicializado CORRECTAMENTE")

func _ready() -> void:
	print("[MarketScreen] _ready() llamado - INICIO SISTEMA COMPLETO")
	print("[MarketScreen] UnifiedInventorySystem disponible: %s" % str(UnifiedInventorySystem != null))

	# Configurar la interfaz paso a paso
	await get_tree().process_frame # Esperar un frame para que todos los nodos estén listos

	_setup_ui_system()

	print("[MarketScreen] _ready() completado exitosamente")

func _setup_ui_system():
	"""Configurar el sistema de UI completo"""
	print("[MarketScreen] === CONFIGURANDO SISTEMA UI ===")

	# Paso 1: Verificar nodos críticos
	_verify_critical_nodes()

	# Paso 2: Probar sistema de inventario
	_test_inventory_integration()

	# Paso 3: Configurar interfaz
	_setup_market_interface()

func _verify_critical_nodes():
	"""Verificar que todos los nodos críticos existan"""
	print("[MarketScreen] Verificando nodos críticos...")

	var critical_paths = [
		"VBoxContainer",
		"VBoxContainer/ResourcesPanel/ResourcesContainer/MoneyContainer/MoneyLabel",
		"VBoxContainer/SellModeContainer/SellPanel/SellItemsContainer"
	]

	for path in critical_paths:
		if has_node(path):
			print("[MarketScreen] ✅ %s encontrado" % path)
		else:
			print("[MarketScreen] ❌ %s NO encontrado" % path)

func _test_inventory_integration():
	"""Probar la integración con el sistema de inventario"""
	print("[MarketScreen] === PROBANDO INTEGRACIÓN INVENTARIO ===")

	if not UnifiedInventorySystem:
		print("[MarketScreen] ❌ UnifiedInventorySystem no disponible")
		return

	var fishing_container = UnifiedInventorySystem.get_fishing_container()
	if not fishing_container:
		print("[MarketScreen] ❌ Contenedor de pesca no disponible")
		return

	print("[MarketScreen] ✅ Contenedor disponible con %d items" % fishing_container.items.size())

	# Si está vacío, añadir items de prueba
	if fishing_container.items.size() == 0:
		_populate_test_inventory()

	# Mostrar items en la UI
	_display_inventory_items()

func _populate_test_inventory():
	"""Poblar el inventario con items de prueba"""
	print("[MarketScreen] Añadiendo items de prueba al inventario...")

	if not Content:
		print("[MarketScreen] ❌ Content system no disponible")
		return

	# Añadir varios peces de prueba
	var test_fish_ids = ["salmon", "trucha", "lubina"]
	var added_count = 0

	for fish_id in test_fish_ids:
		var fish_data = Content.get_fish_by_id(fish_id)
		if fish_data:
			var item_instance = ItemInstance.new()
			item_instance.from_fish_data({
				"fish_id": fish_id,
				"size": randf_range(15.0, 35.0),
				"quality": randf_range(0.5, 1.0),
				"timestamp": Time.get_unix_time_from_system()
			})

			if UnifiedInventorySystem.add_item(item_instance, "fishing"):
				added_count += 1
				print("[MarketScreen] ✅ Pez añadido: %s" % fish_data.display_name)

	print("[MarketScreen] Total peces de prueba añadidos: %d" % added_count)

func _display_inventory_items():
	"""Mostrar los items del inventario en la UI"""
	print("[MarketScreen] Mostrando items en la interfaz...")

	var fishing_container = UnifiedInventorySystem.get_fishing_container()
	if not fishing_container:
		print("[MarketScreen] ❌ No hay contenedor para mostrar")
		return

	# Buscar el contenedor de la UI
	if not has_node("VBoxContainer/SellModeContainer/SellPanel/SellItemsContainer"):
		print("[MarketScreen] ❌ Contenedor UI no encontrado")
		return

	var ui_container = get_node("VBoxContainer/SellModeContainer/SellPanel/SellItemsContainer")

	# Limpiar contenido anterior
	for child in ui_container.get_children():
		child.queue_free()

	print("[MarketScreen] Creando UI para %d items..." % fishing_container.items.size())

	# Crear elementos visuales para cada item
	for item in fishing_container.items:
		_create_item_display(ui_container, item)

	if fishing_container.items.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "🎣 No hay peces en el inventario"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ui_container.add_child(empty_label)

func _create_item_display(container: Control, item: ItemInstance):
	"""Crear la representación visual de un item"""
	var item_panel = PanelContainer.new()
	var hbox = HBoxContainer.new()

	# Información del pez
	var info_label = Label.new()
	var fish_name = item.get_display_name()
	var size = item.size
	var quality_percent = int(item.quality * 100)

	info_label.text = "🐟 %s | Tamaño: %.1fcm | Calidad: %d%%" % [fish_name, size, quality_percent]

	# Botón de venta
	var sell_button = Button.new()
	var sell_price = _calculate_sell_price(item)
	sell_button.text = "Vender ($%d)" % sell_price
	sell_button.pressed.connect(_on_sell_item.bind(item))

	hbox.add_child(info_label)
	hbox.add_child(sell_button)
	item_panel.add_child(hbox)
	container.add_child(item_panel)

	print("[MarketScreen] Item visual creado: %s" % fish_name)

func _calculate_sell_price(item: ItemInstance) -> int:
	"""Calcular el precio de venta de un item"""
	if not Content:
		return 10 # Precio por defecto

	var fish_data = Content.get_fish_by_id(item.fish_id)
	if not fish_data:
		return 10

	var base_price = fish_data.base_value
	var size_multiplier = 1.0 + (item.size / 100.0) # Peces más grandes valen más
	var quality_multiplier = item.quality

	var final_price = int(base_price * size_multiplier * quality_multiplier * SELL_MULTIPLIER)
	return max(final_price, 1) # Mínimo 1 moneda

func _on_sell_item(item: ItemInstance):
	"""Vender un item específico"""
	print("[MarketScreen] Vendiendo item: %s" % item.get_display_name())

	var sell_price = _calculate_sell_price(item)

	# Remover item del inventario
	if UnifiedInventorySystem.remove_item(item):
		# Añadir dinero al jugador
		if Save:
			Save.game_data.coins += sell_price
			print("[MarketScreen] ✅ Item vendido por $%d" % sell_price)

			# Actualizar UI
			_update_money_display()
			_display_inventory_items() # Refrescar la lista
		else:
			print("[MarketScreen] ❌ Error: Save system no disponible")
	else:
		print("[MarketScreen] ❌ Error removiendo item del inventario")

func _setup_market_interface():
	"""Configurar la interfaz del mercado"""
	print("[MarketScreen] Configurando interfaz del mercado...")

	_update_money_display()

	print("[MarketScreen] ✅ Interfaz configurada correctamente")

func _update_money_display():
	"""Actualizar la visualización de dinero y gemas"""
	if has_node("VBoxContainer/ResourcesPanel/ResourcesContainer/MoneyContainer/MoneyLabel"):
		var money_label = get_node("VBoxContainer/ResourcesPanel/ResourcesContainer/MoneyContainer/MoneyLabel")
		if Save:
			money_label.text = str(int(Save.game_data.coins))

	if has_node("VBoxContainer/ResourcesPanel/ResourcesContainer/GemsContainer/GemsLabel"):
		var gems_label = get_node("VBoxContainer/ResourcesPanel/ResourcesContainer/GemsContainer/GemsLabel")
		if Save:
			gems_label.text = str(int(Save.game_data.gems))

var sell_inventory: FilteredInventory
var buy_inventory: FilteredInventory

# Referencias a nodos
@onready var sell_button: Button = $VBoxContainer/MarketTabs/SellButton
@onready var buy_button: Button = $VBoxContainer/MarketTabs/BuyButton
@onready var money_label: Label = $VBoxContainer/ResourcesPanel/ResourcesContainer/MoneyContainer/MoneyLabel
@onready var gems_label: Label = $VBoxContainer/ResourcesPanel/ResourcesContainer/GemsContainer/GemsLabel
@onready var sell_mode_container: Control = $VBoxContainer/SellModeContainer
@onready var buy_mode_container: Control = $VBoxContainer/BuyModeContainer
@onready var sell_all_button: Button = $VBoxContainer/SellModeContainer/SellPanel/SellFilters/SellAllButton
@onready var auto_sell_toggle: CheckBox = $VBoxContainer/SellModeContainer/SellPanel/SellFilters/AutoSellToggle
@onready var sell_items_container: Control = $VBoxContainer/SellModeContainer/SellPanel/SellItemsContainer
@onready var category_option: OptionButton = $VBoxContainer/BuyModeContainer/BuyPanel/BuyFilters/CategoryOption
@onready var refresh_button: Button = $VBoxContainer/BuyModeContainer/BuyPanel/BuyFilters/RefreshButton
@onready var buy_items_container: Control = $VBoxContainer/BuyModeContainer/BuyPanel/BuyItemsContainer
@onready var transaction_summary_panel: PanelContainer = $VBoxContainer/TransactionSummary
@onready var summary_text: Label = $VBoxContainer/TransactionSummary/SummaryContainer/SummaryText
@onready var clear_button: Button = $VBoxContainer/TransactionSummary/SummaryContainer/ClearButton

# Funciones principales - VERSIÓN SIMPLIFICADA PARA DEBUG
func _init() -> void:
	print("[MarketScreen] _init() llamado - Script inicializado")

func _ready() -> void:
	print("[MarketScreen] _ready() llamado - INICIO - VERSIÓN SIMPLIFICADA")
	print("[MarketScreen] UnifiedInventorySystem disponible: %s" % str(UnifiedInventorySystem != null))

	# Solo debug básico sin usar las variables @onready aún
	var vbox = get_node("VBoxContainer")
	print("[MarketScreen] VBoxContainer encontrado: %s" % str(vbox != null))

	if UnifiedInventorySystem:
		print("[MarketScreen] Sistema disponible, verificando contenedor...")
		var fishing_container = UnifiedInventorySystem.get_fishing_container()
		if fishing_container:
			print("[MarketScreen] Contenedor encontrado con %d items" % fishing_container.items.size())
		else:
			print("[MarketScreen] ERROR: No se pudo obtener fishing_container")
	else:
		print("[MarketScreen] ERROR: UnifiedInventorySystem no disponible")

	print("[MarketScreen] _ready() completado exitosamente")

	# TEMPORALMENTE COMENTADO PARA DEBUG:
	# if UnifiedInventorySystem:
	#	print("[MarketScreen] Llamando _refresh_sellable_items...")
	#	_refresh_sellable_items()
	# else:
	#	print("[MarketScreen] Esperando UnifiedInventorySystem...")

	print("[MarketScreen] _ready() completado - sin errores")

func _connect_signals() -> void:
	sell_button.toggled.connect(_on_mode_toggled.bind(MarketMode.SELL))
	buy_button.toggled.connect(_on_mode_toggled.bind(MarketMode.BUY))
	sell_all_button.pressed.connect(_on_sell_all_pressed)
	auto_sell_toggle.toggled.connect(_on_auto_sell_toggled)
	refresh_button.pressed.connect(_on_refresh_market_pressed)
	clear_button.pressed.connect(_on_clear_summary_pressed)

func _setup_inventories() -> void:
	"""Configurar inventarios reutilizando FilteredInventory"""
	# Inventario de venta
	sell_inventory = INVENTORY_SCENE.instantiate()
	sell_inventory.inventory_closed.connect(_on_inventory_closed)
	sell_inventory.item_sold.connect(_on_item_sold_from_inventory)
	sell_items_container.add_child(sell_inventory)

	# Inventario de compra
	buy_inventory = INVENTORY_SCENE.instantiate()
	buy_inventory.inventory_closed.connect(_on_inventory_closed)
	buy_inventory.item_used.connect(_on_item_bought_from_inventory) # Reutilizar señal como "comprar"
	buy_items_container.add_child(buy_inventory)

func setup_market(money: int, gems: int, sell_items: Array[Dictionary], buy_items: Array[Dictionary]) -> void:
	"""Configurar mercado con datos y cargar inventario de peces"""
	print("[MarketScreen] setup_market llamado")
	player_money = money
	player_gems = gems

	# Cargar inventario real de peces del UnifiedInventorySystem
	if UnifiedInventorySystem:
		print("[MarketScreen] UnifiedInventorySystem disponible")
		var fishing_container = UnifiedInventorySystem.get_fishing_container()
		if fishing_container:
			print("[MarketScreen] Container encontrado con %d items" % fishing_container.items.size())
			sellable_items = _process_fish_inventory(fishing_container.items)
		else:
			print("[MarketScreen] No se encontró fishing container")
			sellable_items = sell_items
	else:
		print("[MarketScreen] UnifiedInventorySystem no disponible, usando sell_items")
		sellable_items = sell_items

	buyable_items = buy_items

	_update_resources_display()
	_refresh_current_mode()

# Funciones de procesamiento de inventario
func _refresh_sellable_items() -> void:
	"""Refrescar lista de peces vendibles"""
	print("[MarketScreen] Refrescando items vendibles...")

	if UnifiedInventorySystem:
		var fishing_container = UnifiedInventorySystem.get_fishing_container()
		if fishing_container:
			print("[MarketScreen] Container encontrado con %d items" % fishing_container.items.size())

			# Si el inventario está vacío, agregar algunos peces de prueba
			if fishing_container.items.size() == 0:
				print("[MarketScreen] Inventario vacío, añadiendo peces de prueba...")
				_add_test_fish()
				# Volver a verificar después de añadir peces
				fishing_container = UnifiedInventorySystem.get_fishing_container()
				print("[MarketScreen] Container después de prueba: %d items" % fishing_container.items.size())

			sellable_items = _process_fish_inventory(fishing_container.items)
			print("[MarketScreen] Items procesados: %d" % sellable_items.size())
		else:
			print("[MarketScreen] No se encontró fishing container")
			sellable_items = []
		_setup_sell_mode()
	else:
		print("[MarketScreen] UnifiedInventorySystem no disponible")
		sellable_items = []

func _process_fish_inventory(items: Array) -> Array[Dictionary]:
	"""Procesar items del inventario para convertirlos a formato del mercado"""
	print("[MarketScreen] Procesando %d items del inventario..." % items.size())
	var processed_items: Array[Dictionary] = []

	for i in range(items.size()):
		var item_instance = items[i]
		print("[MarketScreen] Item %d: %s" % [i, str(item_instance)])

		var fish_data = item_instance.to_fish_data()
		print("[MarketScreen] Fish data: %s" % str(fish_data))

		# Añadir índice de inventario para referencia de venta
		fish_data["inventory_index"] = i

		processed_items.append(fish_data)

	print("[MarketScreen] Items procesados final: %d" % processed_items.size())
	return processed_items

func _add_test_fish() -> void:
	"""Añadir algunos peces de prueba al inventario si está vacío"""
	print("[MarketScreen] Añadiendo peces de prueba...")

	if not Content:
		print("[MarketScreen] Sistema Content no disponible")
		return

	# Buscar algunas definiciones de peces
	var fish_definitions = Content.get_fish_definitions()
	if fish_definitions.size() == 0:
		print("[MarketScreen] No hay definiciones de peces disponibles")
		return

	print("[MarketScreen] Encontradas %d definiciones de peces" % fish_definitions.size())

	# Añadir los primeros 3 peces encontrados
	for i in range(min(3, fish_definitions.size())):
		var fish_def = fish_definitions.values()[i]
		print("[MarketScreen] Añadiendo pez de prueba: %s" % fish_def.display_name)

		# Crear ItemInstance del pez
		var fish_item = ItemInstance.new()
		fish_item.item_definition = fish_def
		fish_item.quantity = 1
		fish_item.metadata = {
			"size": randf_range(fish_def.size_min, fish_def.size_max),
			"zone_caught": "test_zone",
			"timestamp": Time.get_unix_time_from_system()
		}

		# Añadir al inventario
		if UnifiedInventorySystem.add_item(fish_item, "fishing"):
			print("[MarketScreen] ✅ Pez %s añadido exitosamente" % fish_def.display_name)
		else:
			print("[MarketScreen] ❌ Error añadiendo pez %s" % fish_def.display_name)

# Funciones de UI y display
func _update_resources_display() -> void:
	money_label.text = _format_number(player_money)
	gems_label.text = str(player_gems)

func _format_number(number: int) -> String:
	if number >= 1000000:
		return "%.1fM" % (number / 1000000.0)
	elif number >= 1000:
		return "%.1fK" % (number / 1000.0)

	return str(number)

func _refresh_current_mode() -> void:
	"""Actualizar la vista actual según el modo seleccionado"""
	sell_mode_container.visible = (current_mode == MarketMode.SELL)
	buy_mode_container.visible = (current_mode == MarketMode.BUY)

	if current_mode == MarketMode.SELL:
		_setup_sell_mode()
	else:
		_setup_buy_mode()

func _setup_sell_mode() -> void:
	"""Configurar modo de venta con inventario de peces"""
	print("[MarketScreen] Configurando modo venta con %d items" % sellable_items.size())

	# Mostrar información del inventario
	_update_inventory_display()

	# Configurar inventario individual de peces
	if sellable_items.size() > 0:
		print("[MarketScreen] Configurando sell_inventory con items")
		sell_inventory.setup_inventory(sellable_items, "Peces para Vender")
	else:
		print("[MarketScreen] Configurando sell_inventory vacío")
		sell_inventory.setup_inventory([], "Inventario Vacío")

func _update_inventory_display() -> void:
	"""Actualizar información del inventario en el panel"""
	var total_fish = sellable_items.size()
	var total_value = 0
	var rarity_count = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}

	for fish in sellable_items:
		total_value += fish.get("value", 0)
		var rarity = fish.get("rarity", 0)
		rarity_count[rarity] += 1

	# Actualizar summary text si existe
	if summary_text:
		var info_text = "📊 RESUMEN DEL INVENTARIO\n\n"
		info_text += "🐟 Total de peces: %d\n" % total_fish
		info_text += "💰 Valor total: %s monedas\n\n" % _format_number(total_value)
		info_text += "✨ Por rareza:\n"

		for rarity in rarity_count:
			if rarity_count[rarity] > 0:
				var color_text = ""
				match rarity:
					0: color_text = "⚪ Común"
					1: color_text = "🟢 Poco común"
					2: color_text = "🔵 Raro"
					3: color_text = "🟣 Épico"
					4: color_text = "🟡 Legendario"
				info_text += "  %s: %d peces\n" % [color_text, rarity_count[rarity]]

		summary_text.text = info_text

func _setup_buy_mode() -> void:
	"""Configurar modo de compra"""
	# Filtrar objetos por categoría seleccionada
	var filtered_buyables = _filter_buyables_by_category()
	var buyables_with_prices = _add_buy_prices_to_items(filtered_buyables)
	buy_inventory.setup_inventory(buyables_with_prices, "Tienda")

# Funciones de procesamiento de items
func _add_sell_prices_to_items(items: Array[Dictionary]) -> Array[Dictionary]:
	"""Añadir precios de venta a los objetos"""
	var items_with_prices: Array[Dictionary] = []
	for item in items:
		var item_copy = item.duplicate()
		var base_value = item.get("value", 0)
		item_copy["sell_price"] = base_value
		item_copy["description"] = "%s\n💰 Precio de venta: %s" % [
			item.get("description", ""),
			_format_number(base_value)
		]
		items_with_prices.append(item_copy)
	return items_with_prices

func _add_buy_prices_to_items(items: Array[Dictionary]) -> Array[Dictionary]:
	"""Añadir precios de compra a los objetos"""
	var items_with_prices: Array[Dictionary] = []
	for item in items:
		var item_copy = item.duplicate()
		var buy_price = item.get("buy_price", item.get("value", 0) * 2)
		item_copy["buy_price"] = buy_price
		item_copy["description"] = "%s\n💰 Precio: %s" % [
			item.get("description", ""),
			_format_number(buy_price)
		]
		# Marcar como usable para reutilizar botón "Usar" como "Comprar"
		item_copy["usable"] = true
		item_copy["sellable"] = false
		items_with_prices.append(item_copy)
	return items_with_prices

func _filter_buyables_by_category() -> Array[Dictionary]:
	"""Filtrar objetos comprables por categoría seleccionada"""
	var selected_category = category_option.get_item_text(category_option.selected)

	if selected_category == "Todo":
		return buyable_items

	return buyable_items.filter(
		func(item): return item.get("category", "").to_lower() == selected_category.to_lower()
	)

func _create_sellable_fish_data(fish_data: Dictionary, index: int) -> Dictionary:
	"""Crear datos de pez para la venta con información completa"""
	var sellable_fish = fish_data.duplicate()

	# Añadir información específica del mercado
	sellable_fish["inventory_index"] = index
	sellable_fish["sell_price"] = fish_data.get("value", 0)
	sellable_fish["category"] = "fish"

	# Información de rareza
	var rarity = fish_data.get("rarity", 0)
	sellable_fish["rarity_name"] = RARITY_NAMES.get(rarity, "Común")
	sellable_fish["rarity_color"] = RARITY_COLORS.get(rarity, Color.WHITE)

	# Descripción enriquecida
	var description = "🐟 %s\n" % fish_data.get("name", "Pez desconocido")
	description += "💰 Valor: %s monedas\n" % _format_number(fish_data.get("value", 0))
	description += "📏 Tamaño: %.1f cm\n" % fish_data.get("size", 0.0)
	description += "📍 Capturado en: %s\n" % fish_data.get("zone_caught", "Desconocida")
	description += "✨ Rareza: %s" % sellable_fish["rarity_name"]

	# Añadir timestamp si está disponible
	if fish_data.has("timestamp"):
		var time_str = Time.get_datetime_string_from_unix_time(fish_data["timestamp"])
		description += "\n🕐 Capturado: %s" % time_str

	sellable_fish["description"] = description

	return sellable_fish

func _apply_filters_and_sorting(items: Array[Dictionary]) -> Array[Dictionary]:
	"""Aplicar filtros y ordenamiento a los items"""
	var filtered_items = items

	# Aplicar filtro de rareza
	if rarity_filter >= 0:
		filtered_items = filtered_items.filter(
			func(item): return item.get("rarity", 0) == rarity_filter
		)

	# Aplicar filtro de zona
	if zone_filter != "":
		filtered_items = filtered_items.filter(
			func(item): return item.get("zone_caught", "").to_lower() == zone_filter.to_lower()
		)

	# Aplicar ordenamiento
	match sort_mode:
		"value":
			filtered_items.sort_custom(func(a, b): return a.get("value", 0) > b.get("value", 0))
		"rarity":
			filtered_items.sort_custom(func(a, b): return a.get("rarity", 0) > b.get("rarity", 0))
		"size":
			filtered_items.sort_custom(func(a, b): return a.get("size", 0.0) > b.get("size", 0.0))
		"time":
			filtered_items.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))

	return filtered_items

# Funciones de transacciones
func _add_transaction_to_summary(type: String, item_name: String, quantity: int, total_value: int) -> void:
	"""Añadir transacción al resumen"""
	var transaction = {
		"type": type,
		"item": item_name,
		"quantity": quantity,
		"value": total_value,
		"timestamp": Time.get_unix_time_from_system()
	}
	transaction_summary.append(transaction)
	_update_summary_display()

func _update_summary_display() -> void:
	"""Actualizar visualización del resumen"""
	if transaction_summary.is_empty():
		transaction_summary_panel.visible = false
		return

	transaction_summary_panel.visible = true
	var total_earned = 0
	var total_spent = 0

	for transaction in transaction_summary:
		if transaction.type == "sell":
			total_earned += transaction.value
		else:
			total_spent += transaction.value

	var summary = ""
	if total_earned > 0:
		summary += "Ganado: +%s 💰" % _format_number(total_earned)
	if total_spent > 0:
		if summary != "":
			summary += " | "
		summary += "Gastado: -%s 💰" % _format_number(total_spent)

	summary_text.text = summary

# Funciones de filtros públicas
func set_rarity_filter(rarity: int) -> void:
	rarity_filter = rarity
	_refresh_sellable_items()

func set_zone_filter(zone: String) -> void:
	zone_filter = zone
	_refresh_sellable_items()

func set_sort_mode(mode: String) -> void:
	sort_mode = mode
	_refresh_sellable_items()

func get_available_zones() -> Array[String]:
	var zones: Array[String] = []
	for item in sellable_items:
		var zone = item.get("zone_caught", "")
		if zone != "" and not zones.has(zone):
			zones.append(zone)
	return zones

func get_available_rarities() -> Array[int]:
	var rarities: Array[int] = []
	for item in sellable_items:
		var rarity = item.get("rarity", 0)
		if not rarities.has(rarity):
			rarities.append(rarity)
	return rarities

# Event handlers
func _on_sell_all_pressed() -> void:
	"""Vender todos los peces del inventario"""
	if sellable_items.size() == 0:
		print("No hay peces para vender")
		return

	var total_value = 0
	var fish_count = sellable_items.size()
	var fish_indices: Array[int] = []

	# Recopilar índices y calcular valor total
	for fish in sellable_items:
		var inventory_index = fish.get("inventory_index", -1)
		if inventory_index >= 0:
			fish_indices.append(inventory_index)
			total_value += fish.get("value", 0)

	if fish_indices.size() > 0:
		# Usar UnifiedInventorySystem para vender todos los peces
		var earned = UnifiedInventorySystem.sell_items_by_indices(fish_indices)

		if earned > 0:
			# Actualizar dinero
			player_money += earned
			_update_resources_display()
			_add_transaction_to_summary("sell", "Venta masiva", fish_count, earned)

			# Refrescar inventario
			_refresh_sellable_items()

			print("Vendidos %d peces por %d monedas" % [fish_count, earned])

func _on_item_sold_from_inventory(item_data: Dictionary) -> void:
	"""Manejar venta de pez individual"""
	var inventory_index = item_data.get("inventory_index", -1)
	if inventory_index < 0:
		print("Índice de inventario inválido")
		return

	var sell_price = item_data.get("value", 0)
	var fish_name = item_data.get("name", "Pez desconocido")

	# Vender pez específico usando UnifiedInventorySystem
	var earned = UnifiedInventorySystem.sell_items_by_indices([inventory_index])

	if earned > 0:
		# Actualizar dinero
		player_money += earned
		_update_resources_display()
		_add_transaction_to_summary("sell", fish_name, 1, earned)

		# Refrescar inventario
		_refresh_sellable_items()

		# Emitir señal
		item_sold.emit(item_data, 1)

		print("Vendido %s por %d monedas" % [fish_name, earned])
	else:
		print("Error al vender el pez")

func _on_mode_toggled(mode: MarketMode, pressed: bool) -> void:
	if not pressed:
		return

	current_mode = mode
	_refresh_current_mode()

func _on_auto_sell_toggled(enabled: bool) -> void:
	auto_sell_toggled.emit(enabled)

func _on_refresh_market_pressed() -> void:
	"""Actualizar ofertas del mercado"""
	_setup_buy_mode()

func _on_clear_summary_pressed() -> void:
	"""Limpiar resumen de transacciones"""
	transaction_summary.clear()
	_update_summary_display()

func _on_inventory_closed() -> void:
	# No hacer nada, los inventarios están embebidos
	pass

func _on_item_bought_from_inventory(item_data: Dictionary) -> void:
	"""Manejar compra desde inventario (reutilizando señal item_used)"""
	var buy_price = item_data.get("buy_price", item_data.get("value", 0))
	var quantity = 1 # Por ahora cantidad fija

	if player_money >= buy_price:
		player_money -= buy_price
		_update_resources_display()
		_add_transaction_to_summary("buy", item_data.get("name", ""), quantity, buy_price)

		item_bought.emit(item_data, quantity)
