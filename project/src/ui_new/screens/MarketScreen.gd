class_name MarketScreen
extends Control

# Pantalla del mercado con inventario individualizado y rareza

signal market_closed
signal item_sold(item_data: Dictionary, quantity: int)
signal item_bought(item_data: Dictionary, quantity: int)
signal auto_sell_toggled(enabled: bool)

enum MarketMode {
	SELL,
	BUY
}

var current_mode: MarketMode = MarketMfunc_on_sell_all_pressed() -> void:
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
		# Usar InventorySystem para vender los peces
		var earned = InventorySystem.sell_fishes(fish_indices)

		# Actualizar dinero
		player_money = Save.get_coins() if Save else player_money + earned
		_update_resources_display()

		# Añadir transacción
		_add_transaction_to_summary("sell", "Venta masiva", fish_count, earned)

		# Refrescar inventario
		_refresh_sellable_items()

		print("Vendidos %d peces por %d monedas" % [fish_count, earned])

func _refresh_sellable_items() -> void:
	"""Refrescar lista de peces vendibles"""
	if InventorySystem:
		var fish_inventory = InventorySystem.get_inventory()
		sellable_items = _process_fish_inventory(fish_inventory)
		_setup_sell_mode()

func _on_item_sold_from_inventory(item_data: Dictionary) -> void:
	"""Manejar venta de pez individual"""
	var inventory_index = item_data.get("inventory_index", -1)
	if inventory_index < 0:
		print("Índice de inventario inválido")
		return

	var sell_price = item_data.get("value", 0)
	var fish_name = item_data.get("name", "Pez desconocido")

	# Vender pez específico usando InventorySystem
	var earned = InventorySystem.sell_fishes([inventory_index])

	if earned > 0:
		# Actualizar dinero
		player_money = Save.get_coins() if Save else player_money + earned
		_update_resources_display()

		# Añadir transacción
		_add_transaction_to_summary("sell", fish_name, 1, earned)

		# Refrescar inventario
		_refresh_sellable_items()

		# Emitir señal
		item_sold.emit(item_data, 1)

		print("Vendido %s por %d monedas" % [fish_name, earned])
	else:
		print("Error al vender pez")

# Funciones de filtrado y ordenamiento
func set_rarity_filter(rarity: int) -> void:
	"""Establecer filtro de rareza"""
	rarity_filter = rarity
	_refresh_sellable_items()

func set_zone_filter(zone: String) -> void:
	"""Establecer filtro de zona"""
	zone_filter = zone
	_refresh_sellable_items()

func set_sort_mode(mode: String) -> void:
	"""Establecer modo de ordenamiento"""
	sort_mode = mode
	_refresh_sellable_items()

func get_available_zones() -> Array[String]:
	"""Obtener zonas disponibles en el inventario"""
	var zones = []
	for fish in sellable_items:
		var zone = fish.get("zone_caught", "")
		if zone != "" and not zones.has(zone):
			zones.append(zone)
	return zones

func get_available_rarities() -> Array[int]:
	"""Obtener rarezas disponibles en el inventario"""
	var rarities = []
	for fish in sellable_items:
		var rarity = fish.get("rarity", 0)
		if not rarities.has(rarity):
			rarities.append(rarity)
	return raritiesr_money: int = 0
var player_gems: int = 0
var sellable_items: Array[Dictionary] = []
var buyable_items: Array[Dictionary] = []
var transaction_summary: Array[Dictionary] = []

# Para filtrado y organización
var rarity_filter: int = -1 # -1 = todos, 0-4 = rareza específica
var zone_filter: String = "" # "" = todas, zone_id = zona específica
var sort_mode: String = "value" # "value", "rarity", "size", "time"

const INVENTORY_SCENE = preload("res://scenes/ui_new/components/FilteredInventory.tscn")
const FISH_CARD_SCENE = preload("res://scenes/ui_new/components/Card.tscn")

# Colores por rareza
const RARITY_COLORS = {
	0: Color.WHITE, # Común
	1: Color.GREEN, # Poco común
	2: Color.BLUE, # Raro
	3: Color.PURPLE, # Épico
	4: Color.GOLD # Legendario
}

const RARITY_NAMES = {
	0: "Común",
	1: "Poco común",
	2: "Raro",
	3: "Épico",
	4: "Legendario"
}

@onready var sell_button: Button = $VBoxContainer/MarketTabs/SellButton
@onready var buy_button: Button = $VBoxContainer/MarketTabs/BuyButton
@onready var money_label: Label = $VBoxContainer/ResourcesPanel/ResourcesContainer / \
	MoneyContainer / MoneyLabel
@onready var gems_label: Label = $VBoxContainer/ResourcesPanel/ResourcesContainer / \
	GemsContainer / GemsLabel
@onready var sell_mode_container: Control = $VBoxContainer/SellModeContainer
@onready var buy_mode_container: Control = $VBoxContainer/BuyModeContainer
@onready var sell_all_button: Button = $VBoxContainer/SellModeContainer/SellPanel/SellFilters / \
	SellAllButton
@onready var auto_sell_toggle: CheckBox = $VBoxContainer/SellModeContainer/SellPanel / \
	SellFilters / AutoSellToggle
@onready var sell_items_container: Control = $VBoxContainer/SellModeContainer/SellPanel / \
	SellItemsContainer
@onready var category_option: OptionButton = $VBoxContainer/BuyModeContainer/BuyPanel / \
	BuyFilters / CategoryOption
@onready var refresh_button: Button = $VBoxContainer/BuyModeContainer/BuyPanel/BuyFilters / \
	RefreshButton
@onready var buy_items_container: Control = $VBoxContainer/BuyModeContainer/BuyPanel / \
	BuyItemsContainer
@onready var transaction_summary_panel: PanelContainer = $VBoxContainer/TransactionSummary
@onready var summary_text: Label = $VBoxContainer/TransactionSummary/SummaryContainer/SummaryText
@onready var clear_button: Button = $VBoxContainer/TransactionSummary/SummaryContainer / \
	ClearButton

var sell_inventory: FilteredInventory
var buy_inventory: FilteredInventory

func _ready() -> void:
	_connect_signals()
	_setup_inventories()

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

func setup_market(money: int, gems: int, sell_items: Array[Dictionary],
	buy_items: Array[Dictionary]) -> void:
	"""Configurar mercado con datos y cargar inventario de peces"""
	player_money = money
	player_gems = gems

	# Cargar inventario real de peces del InventorySystem
	if InventorySystem:
		var fish_inventory = InventorySystem.get_inventory()
		sellable_items = _process_fish_inventory(fish_inventory)
	else:
		sellable_items = sell_items

	buyable_items = buy_items

	_update_resources_display()
	_refresh_current_mode()

func _process_fish_inventory(fish_inventory: Array) -> Array[Dictionary]:
	"""Procesar inventario de peces para el mercado"""
	var processed_items: Array[Dictionary] = []

	for i in range(fish_inventory.size()):
		var fish_data = fish_inventory[i]
		var processed_fish = _create_sellable_fish_data(fish_data, i)
		processed_items.append(processed_fish)

	# Aplicar filtros y ordenamiento
	processed_items = _apply_filters_and_sorting(processed_items)

	return processed_items

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
		var timestamp = fish_data["timestamp"]
		if timestamp is Dictionary:
			description += "\n⏰ Capturado: %02d/%02d/%d" % [
				timestamp.get("day", 1),
				timestamp.get("month", 1),
				timestamp.get("year", 2025)
			]

	sellable_fish["description"] = description

	return sellable_fish

func _apply_filters_and_sorting(items: Array[Dictionary]) -> Array[Dictionary]:
	"""Aplicar filtros y ordenamiento al inventario"""
	var filtered_items = items

	# Filtrar por rareza si está activo
	if rarity_filter >= 0:
		filtered_items = filtered_items.filter(func(item):
			return item.get("rarity", 0) == rarity_filter
		)

	# Filtrar por zona si está activo
	if zone_filter != "":
		filtered_items = filtered_items.filter(func(item):
			return item.get("zone_caught", "") == zone_filter
		)

	# Ordenar según modo seleccionado
	match sort_mode:
		"value":
			filtered_items.sort_custom(func(a, b): return a.get("value", 0) > b.get("value", 0))
		"rarity":
			filtered_items.sort_custom(func(a, b): return a.get("rarity", 0) > b.get("rarity", 0))
		"size":
			filtered_items.sort_custom(func(a, b): return a.get("size", 0.0) > b.get("size", 0.0))
		"time":
			# Ordenar por timestamp (más reciente primero)
			filtered_items.sort_custom(func(a, b):
				var time_a = a.get("timestamp", {}).get("unix", 0) if a.has("timestamp") else 0
				var time_b = b.get("timestamp", {}).get("unix", 0) if b.has("timestamp") else 0
				return time_a > time_b
			)

	return filtered_items

func _update_resources_display() -> void:
	"""Actualizar visualización de recursos"""
	money_label.text = _format_number(player_money)
	gems_label.text = _format_number(player_gems)

func _format_number(number: int) -> String:
	"""Formatear números grandes"""
	if number >= 1000000:
		return "%.1fM" % (number / 1000000.0)
	elif number >= 1000:
		return "%.1fK" % (number / 1000.0)
	else:
		return str(number)

func _refresh_current_mode() -> void:
	"""Actualizar modo actual del mercado"""
	match current_mode:
		MarketMode.SELL:
			sell_mode_container.visible = true
			buy_mode_container.visible = false
			_setup_sell_mode()
		MarketMode.BUY:
			sell_mode_container.visible = false
			buy_mode_container.visible = true
			_setup_buy_mode()

func _setup_sell_mode() -> void:
	"""Configurar modo de venta con inventario de peces"""
	# Mostrar información del inventario
	_update_inventory_display()

	# Configurar inventario individual de peces
	if sellable_items.size() > 0:
		sell_inventory.setup_inventory(sellable_items, "Peces para Vender")
	else:
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

func _add_transaction_to_summary(type: String, item_name: String, quantity: int,
	total_value: int) -> void:
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

func _on_mode_toggled(mode: MarketMode, pressed: bool) -> void:
	if not pressed:
		return

	current_mode = mode
	_refresh_current_mode()

func _on_sell_all_pressed() -> void:
	"""Vender todos los objetos vendibles"""
	var total_value = 0
	var total_items = 0

	for item in sellable_items:
		var quantity = item.get("quantity", 1)
		var value = item.get("value", 0) * quantity
		total_value += value
		total_items += quantity

	if total_value > 0:
		player_money += total_value
		_update_resources_display()
		_add_transaction_to_summary("sell", "Venta masiva", total_items, total_value)

		# Limpiar inventario vendible
		sellable_items.clear()
		_setup_sell_mode()

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

func _on_item_sold_from_inventory(item_data: Dictionary) -> void:
	"""Manejar venta desde inventario"""
	var sell_price = item_data.get("sell_price", item_data.get("value", 0))
	var quantity = 1 # Por ahora cantidad fija

	player_money += sell_price
	_update_resources_display()
	_add_transaction_to_summary("sell", item_data.get("name", ""), quantity, sell_price)

	item_sold.emit(item_data, quantity)

func _on_item_bought_from_inventory(item_data: Dictionary) -> void:
	"""Manejar compra desde inventario (reutilizando señal item_used)"""
	var buy_price = item_data.get("buy_price", item_data.get("value", 0))
	var quantity = 1 # Por ahora cantidad fija

	if player_money >= buy_price:
		player_money -= buy_price
		_update_resources_display()
		_add_transaction_to_summary("buy", item_data.get("name", ""), quantity, buy_price)

		item_bought.emit(item_data, quantity)
