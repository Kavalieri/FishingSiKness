class_name StoreView
extends BaseFloatingMenu

signal close_requested()

# Productos de la tienda
var store_items = [
	{
		"id": "gems_pack_small",
		"name": "Pack Pequeño de Gemas",
		"description": "25 gemas brillantes",
		"cost": 99,
		"currency": "real_money",
		"reward_type": "gems",
		"reward_amount": 25,
		"icon": "💎"
	},
	{
		"id": "gems_pack_medium",
		"name": "Pack Mediano de Gemas",
		"description": "60 gemas brillantes + 5 extra",
		"cost": 199,
		"currency": "real_money",
		"reward_type": "gems",
		"reward_amount": 65,
		"icon": "💎💎"
	},
	{
		"id": "gems_pack_large",
		"name": "Pack Grande de Gemas",
		"description": "150 gemas brillantes + 25 extra",
		"cost": 499,
		"currency": "real_money",
		"reward_type": "gems",
		"reward_amount": 175,
		"icon": "💎💎💎"
	},
	{
		"id": "coins_for_gems_small",
		"name": "Monedas Rápidas",
		"description": "500 monedas instantáneas",
		"cost": 5,
		"currency": "gems",
		"reward_type": "coins",
		"reward_amount": 500,
		"icon": "🪙"
	},
	{
		"id": "coins_for_gems_large",
		"name": "Cofre de Monedas",
		"description": "2000 monedas instantáneas",
		"cost": 15,
		"currency": "gems",
		"reward_type": "coins",
		"reward_amount": 2000,
		"icon": "💰"
	}
]

# UI references
var store_container: VBoxContainer
var coins_label: Label
var gems_label: Label
var store_items_container: VBoxContainer
var close_button: Button

func setup_menu():
	"""Configurar interfaz de la tienda"""
	name = "StoreView"

	# Crear contenedor principal
	store_container = VBoxContainer.new()
	store_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	store_container.offset_left = 20
	store_container.offset_top = 20
	store_container.offset_right = -20
	store_container.offset_bottom = -20
	add_child(store_container)

	create_store_ui()

func create_store_ui():
	"""Crear la interfaz de la tienda"""
	# Header con título y botón cerrar
	var header_container = HBoxContainer.new()
	store_container.add_child(header_container)

	var title_label = Label.new()
	title_label.text = "💎 TIENDA DE GEMAS"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(title_label)

	close_button = Button.new()
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(40, 40)
	close_button.pressed.connect(_on_close_pressed)
	header_container.add_child(close_button)

	# Separador
	var separator = HSeparator.new()
	store_container.add_child(separator)

	# Container de monedas
	var currency_container = HBoxContainer.new()
	store_container.add_child(currency_container)

	coins_label = Label.new()
	coins_label.text = "🪙 0"
	coins_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	currency_container.add_child(coins_label)

	gems_label = Label.new()
	gems_label.text = "💎 0"
	gems_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	currency_container.add_child(gems_label)

	# Scroll container para items
	var store_scroll_container = ScrollContainer.new()
	store_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	store_container.add_child(store_scroll_container)

	store_items_container = VBoxContainer.new()
	store_scroll_container.add_child(store_items_container)

	# Actualizar display inicial
	refresh_display()

func update_currency_display():
	"""Actualizar valores de monedas y gemas"""
	if coins_label and is_instance_valid(coins_label):
		var coins = Save.get_coins() if Save else 0
		coins_label.text = "🪙 %d" % coins
	if gems_label and is_instance_valid(gems_label):
		var gems = Save.get_gems() if Save else 0
		gems_label.text = "💎 %d" % gems

func populate_store_items():
	"""Crear elementos de la tienda"""
	# Limpiar elementos anteriores
	if store_items_container:
		for child in store_items_container.get_children():
			child.queue_free()

	# Crear cada producto
	for item_data in store_items:
		create_store_item(item_data)

func refresh_display():
	"""Actualizar toda la interfaz de la tienda"""
	if not store_container:
		return

	update_currency_display()
	populate_store_items()

func create_store_item(item_data: Dictionary):
	"""Crear un elemento de producto en la tienda"""
	if not item_data or item_data.is_empty():
		print("⚠️ StoreView: item_data vacío o inválido")
		return

	if not store_items_container or not is_instance_valid(store_items_container):
		print("⚠️ StoreView: store_items_container no válido")
		return

	var item_container = PanelContainer.new()
	item_container.custom_minimum_size.y = 80
	store_items_container.add_child(item_container)

	var hbox = HBoxContainer.new()
	item_container.add_child(hbox)

	# Icono
	var icon_label = Label.new()
	var icon_text = item_data.get("icon", "💎")
	if icon_text and icon_text != "":
		icon_label.text = str(icon_text)
	else:
		icon_label.text = "💎"
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.custom_minimum_size = Vector2(60, 60)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_label)

	# Info del producto
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	var name_text = item_data.get("name", "Producto")
	name_label.text = str(name_text) if name_text else "Producto"
	name_label.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	var desc_text = item_data.get("description", "")
	desc_label.text = str(desc_text) if desc_text else ""
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	info_vbox.add_child(desc_label)

	# Botón de compra
	var buy_button = Button.new()
	var cost = item_data.get("cost", 0)
	var currency = item_data.get("currency", "coins")
	var currency_symbol = "💰" if currency == "real_money" else "💎" if currency == "gems" else "🪙"
	buy_button.text = "%s %d" % [currency_symbol, cost]
	buy_button.custom_minimum_size = Vector2(100, 50)
	buy_button.pressed.connect(_on_buy_pressed.bind(item_data))
	hbox.add_child(buy_button)

func _on_buy_pressed(item_data: Dictionary):
	"""Manejar compra de producto"""
	print("Comprar: ", item_data.get("name", "Producto"))
	# Aquí iría la lógica de compra

	# Por ahora, solo mostrar mensaje
	var notification = Label.new()
	notification.text = "¡Compra realizada!"
	notification.modulate = Color.GREEN
	get_tree().root.add_child(notification)

	# Remover después de 2 segundos
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(notification):
		notification.queue_free()

func _on_close_pressed():
	"""Cerrar la tienda"""
	close_requested.emit()

func _input(event):
	"""Manejar tecla ESC para cerrar"""
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()
