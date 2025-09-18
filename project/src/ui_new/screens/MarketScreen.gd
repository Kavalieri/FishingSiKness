# MarketScreen - Sistema de mercado integrado con UnifiedInventorySystem
extends Control
class_name MarketScreen

# Señales
signal item_sold(item_instance: ItemInstance, price: int)
signal market_refreshed()

# Referencias a nodos
@onready var money_label: Label = $VBoxContainer/ResourcesPanel/ResourcesContainer/MoneyContainer/MoneyLabel
@onready var items_container: Control = $VBoxContainer/SellModeContainer/SellPanel/SellItemsContainer/ItemsList
@onready var sell_all_button: Button = $VBoxContainer/SellModeContainer/SellPanel/SellFilters/SellAllButton

func _ready() -> void:
	print("🔥 [MARKET] _ready() - Inicializando pantalla de mercado.")
	
	# Verificar nodos críticos
	print("🔥 [MARKET] Verificando nodos...")
	print("🔥 [MARKET] - money_label: %s" % (money_label != null))
	print("🔥 [MARKET] - items_container: %s" % (items_container != null))
	print("🔥 [MARKET] - sell_all_button: %s" % (sell_all_button != null))
	
	if not UnifiedInventorySystem:
		print("🔥 [MARKET] ERROR: UnifiedInventorySystem no está disponible.")
		return

	# Conectar señales de botones
	if sell_all_button:
		sell_all_button.pressed.connect(_on_sell_all_pressed)
		print("🔥 [MARKET] Botón 'Vender Todo' conectado")
	else:
		print("🔥 [MARKET] ERROR: sell_all_button no encontrado")
	
	# Conectar señal de inventario
	if UnifiedInventorySystem.has_signal("inventory_updated"):
		UnifiedInventorySystem.inventory_updated.connect(_on_inventory_updated)
		print("🔥 [MARKET] Señal inventory_updated conectada")
	else:
		print("🔥 [MARKET] ERROR: UnifiedInventorySystem no tiene señal inventory_updated")

func setup_market_screen() -> void:
	"""Método llamado por CentralHost para configurar la pantalla"""
	print("🔥 [MARKET] setup_market_screen() llamado")
	print("🔥 [MARKET] UnifiedInventorySystem disponible: %s" % (UnifiedInventorySystem != null))
	if UnifiedInventorySystem:
		var fishing_container = UnifiedInventorySystem.get_fishing_container()
		if fishing_container:
			print("🔥 [MARKET] Inventario de pesca tiene %d items" % fishing_container.items.size())
		else:
			print("🔥 [MARKET] ERROR: No se pudo obtener fishing_container")
	else:
		print("🔥 [MARKET] ERROR: UnifiedInventorySystem no disponible")
	_refresh_market_view()
	print("🔥 [MARKET] Pantalla de mercado configurada.")

func _refresh_market_view() -> void:
	"""Refresca toda la vista del mercado: dinero e inventario."""
	print("🔥 [MARKET] Refrescando vista completa del mercado...")
	_update_money_display()
	_display_inventory_items()
	print("🔥 [MARKET] Vista del mercado refrescada")

func _on_inventory_updated(container_name: String) -> void:
	"""Se llama cuando el inventario de UnifiedInventorySystem cambia."""
	if container_name == "fishing":
		print("[MarketScreen] Recibida actualización del inventario de pesca.")
		_refresh_market_view()

func _update_money_display() -> void:
	"""Actualiza la etiqueta de dinero."""
	if not money_label:
		print("🔥 [MARKET] ERROR: money_label no disponible")
		return
		
	if not Save:
		print("🔥 [MARKET] ERROR: Save no disponible")
		return
		
	var coins = Save.get_coins()
	money_label.text = str(coins)
	print("🔥 [MARKET] Dinero actualizado en UI: %d" % coins)

func _display_inventory_items() -> void:
	"""Muestra los peces del inventario en la UI."""
	print("🔥 [MARKET] _display_inventory_items() iniciado")
	if not items_container:
		print("🔥 [MARKET] ERROR: El nodo 'ItemsList' para los items no se encuentra.")
		return
		
	# Limpiar vista anterior
	for child in items_container.get_children():
		child.queue_free()

	if not UnifiedInventorySystem:
		print("🔥 [MARKET] ERROR: UnifiedInventorySystem no disponible")
		return

	var fishing_container = UnifiedInventorySystem.get_fishing_container()
	if not fishing_container:
		print("🔥 [MARKET] ERROR: No se pudo obtener fishing_container")
		return

	if fishing_container.items.is_empty():
		print("🔥 [MARKET] Inventario de pesca vacío.")
		var empty_label = Label.new()
		empty_label.text = "No tienes peces para vender."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_container.add_child(empty_label)
		return

	print("🔥 [MARKET] Mostrando %d peces del inventario." % fishing_container.items.size())
	# Crear una entrada por cada pez
	for item_instance in fishing_container.items:
		_create_item_card(item_instance)
	print("🔥 [MARKET] Items del inventario mostrados correctamente")

func _create_item_card(item: ItemInstance) -> void:
	"""Crea una tarjeta visual para un pez en el mercado."""
	var fish_def = item.get_item_def()
	if not fish_def:
		print("🔥 [MARKET] ERROR: No se pudo obtener fish_def para item")
		return

	var card = HBoxContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label = Label.new()
	name_label.text = "%s (%.1f cm)" % [fish_def.name, item.instance_data.get("size", 0.0)]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(name_label)

	var value_label = Label.new()
	var sell_price = item.instance_data.get("value", 0)
	value_label.text = str(sell_price) + " 💰"
	card.add_child(value_label)

	var sell_button = Button.new()
	sell_button.text = "Vender"
	sell_button.pressed.connect(_on_sell_one_pressed.bind(item))
	card.add_child(sell_button)

	items_container.add_child(card)
	print("🔥 [MARKET] Tarjeta creada para: %s" % fish_def.name)

func _on_sell_one_pressed(item_to_sell: ItemInstance) -> void:
	"""Vende un único pez."""
	print("[MarketScreen] Intentando vender un item: %s" % item_to_sell.get_item_def().name)
	UnifiedInventorySystem.sell_item(item_to_sell)

func _on_sell_all_pressed() -> void:
	"""Vende todos los peces del inventario de pesca."""
	print("[MarketScreen] Intentando vender todos los peces...")
	UnifiedInventorySystem.sell_all_fish()

func setup_market(money: int, gems: int, sell_items: Array, buy_items: Array) -> void:
	"""Método de compatibilidad para configuración con parámetros"""
	print("🔥 [MARKET] setup_market() llamado con %d items para vender" % sell_items.size())
	setup_market_screen()