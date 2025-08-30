class_name MarketScreen
extends Control

# Pantalla del mercado según especificación

signal market_closed
signal item_sold(item_data: Dictionary, quantity: int)
signal item_bought(item_data: Dictionary, quantity: int)
signal auto_sell_toggled(enabled: bool)

enum MarketMode {
	SELL,
	BUY
}

var current_mode: MarketMode = MarketMode.SELL
var player_money: int = 0
var player_gems: int = 0
var sellable_items: Array[Dictionary] = []
var buyable_items: Array[Dictionary] = []
var transaction_summary: Array[Dictionary] = []

const INVENTORY_SCENE = preload("res://scenes/ui_new/components/FilteredInventory.tscn")

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
	"""Configurar mercado con datos"""
	player_money = money
	player_gems = gems
	sellable_items = sell_items
	buyable_items = buy_items

	_update_resources_display()
	_refresh_current_mode()

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
	"""Configurar modo de venta"""
	# Configurar inventario con objetos vendibles
	var sellable_with_prices = _add_sell_prices_to_items(sellable_items)
	sell_inventory.setup_inventory(sellable_with_prices, "Objetos para Vender")

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
