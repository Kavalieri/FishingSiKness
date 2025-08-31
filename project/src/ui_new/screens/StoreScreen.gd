class_name StoreScreen
extends Control

# Pantalla de tienda de gemas y objetos premium

signal store_screen_closed
signal gem_pack_purchased(pack_id: String)
signal item_purchased(item_id: String)

@onready var back_button: Button = $VBoxContainer/Header/BackButton
@onready var title_label: Label = $VBoxContainer/Header/TitleLabel
@onready var money_label: Label = $VBoxContainer/Header/ResourcesContainer/MoneyLabel
@onready var gems_label: Label = $VBoxContainer/Header/ResourcesContainer/GemsLabel
@onready var tabs_container: HBoxContainer = $VBoxContainer/TabsContainer
@onready var content_container: Control = $VBoxContainer/ContentContainer

# Pestañas de la tienda
@onready var gems_tab: Button = $VBoxContainer/TabsContainer/GemsTab
@onready var items_tab: Button = $VBoxContainer/TabsContainer/ItemsTab
@onready var offers_tab: Button = $VBoxContainer/TabsContainer/OffersTab

enum StoreTab {
	GEMS,
	ITEMS,
	OFFERS
}

var current_tab: StoreTab = StoreTab.GEMS

# Datos de paquetes de gemas
var gem_packs: Array[Dictionary] = [
	{
		"id": "small_gems",
		"name": "Puñado de Gemas",
		"gems": 100,
		"price": "$1.99",
		"bonus": 0
	},
	{
		"id": "medium_gems",
		"name": "Bolsa de Gemas",
		"gems": 500,
		"price": "$4.99",
		"bonus": 50
	},
	{
		"id": "large_gems",
		"name": "Cofre de Gemas",
		"gems": 1200,
		"price": "$9.99",
		"bonus": 200
	},
	{
		"id": "mega_gems",
		"name": "Tesoro de Gemas",
		"gems": 2500,
		"price": "$19.99",
		"bonus": 500
	}
]

# Datos de objetos premium
var premium_items: Array[Dictionary] = [
	{
		"id": "premium_rod",
		"name": "Caña Dorada",
		"description": "Caña especial con +50% valor de peces",
		"gems_cost": 250,
		"type": "upgrade"
	},
	{
		"id": "lucky_bait",
		"name": "Señuelo de la Suerte",
		"description": "5x usos, +25% peces raros",
		"gems_cost": 100,
		"type": "consumable"
	},
	{
		"id": "xp_booster",
		"name": "Impulsor de XP",
		"description": "2x XP por 1 hora",
		"gems_cost": 50,
		"type": "consumable"
	}
]

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	update_resources_display()

func _setup_ui() -> void:
	"""Configurar interfaz inicial"""
	title_label.text = "Tienda"
	_update_tab_display()
	_show_current_tab_content()

func _connect_signals() -> void:
	"""Conectar señales de la interfaz"""
	back_button.pressed.connect(_on_back_pressed)
	gems_tab.pressed.connect(_on_tab_pressed.bind(StoreTab.GEMS))
	items_tab.pressed.connect(_on_tab_pressed.bind(StoreTab.ITEMS))
	offers_tab.pressed.connect(_on_tab_pressed.bind(StoreTab.OFFERS))

func update_resources_display() -> void:
	"""Actualizar visualización de recursos"""
	if Save:
		var coins = Save.get_coins()
		var gems = Save.get_gems()

		money_label.text = _format_number(coins)
		gems_label.text = str(gems)

func _on_tab_pressed(tab: StoreTab) -> void:
	"""Cambiar pestaña activa"""
	current_tab = tab
	_update_tab_display()
	_show_current_tab_content()

func _update_tab_display() -> void:
	"""Actualizar visualización de pestañas"""
	gems_tab.button_pressed = (current_tab == StoreTab.GEMS)
	items_tab.button_pressed = (current_tab == StoreTab.ITEMS)
	offers_tab.button_pressed = (current_tab == StoreTab.OFFERS)

func _show_current_tab_content() -> void:
	"""Mostrar contenido de la pestaña actual"""
	# Limpiar contenido anterior
	for child in content_container.get_children():
		child.queue_free()

	match current_tab:
		StoreTab.GEMS:
			_create_gems_content()
		StoreTab.ITEMS:
			_create_items_content()
		StoreTab.OFFERS:
			_create_offers_content()

func _create_gems_content() -> void:
	"""Crear contenido de paquetes de gemas"""
	var scroll = ScrollContainer.new()
	var grid = VBoxContainer.new()

	scroll.add_child(grid)
	content_container.add_child(scroll)

	for pack in gem_packs:
		var card = _create_gem_pack_card(pack)
		grid.add_child(card)

func _create_items_content() -> void:
	"""Crear contenido de objetos premium"""
	var scroll = ScrollContainer.new()
	var grid = VBoxContainer.new()

	scroll.add_child(grid)
	content_container.add_child(scroll)

	for item in premium_items:
		var card = _create_premium_item_card(item)
		grid.add_child(card)

func _create_offers_content() -> void:
	"""Crear contenido de ofertas especiales"""
	var label = Label.new()
	label.text = "¡Ofertas especiales próximamente!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(label)

func _create_gem_pack_card(pack: Dictionary) -> Control:
	"""Crear tarjeta de paquete de gemas"""
	var card = Panel.new()
	var vbox = VBoxContainer.new()

	# Título del paquete
	var title = Label.new()
	title.text = pack.get("name", "")
	title.add_theme_font_size_override("font_size", 18)

	# Cantidad de gemas
	var gems_count = Label.new()
	var total_gems = pack.get("gems", 0) + pack.get("bonus", 0)
	gems_count.text = "%d gemas" % total_gems
	if pack.get("bonus", 0) > 0:
		gems_count.text += " (+%d bonus!)" % pack.get("bonus", 0)

	# Precio
	var price = Label.new()
	price.text = pack.get("price", "")
	price.add_theme_color_override("font_color", Color.GREEN)

	# Botón de compra
	var buy_button = Button.new()
	buy_button.text = "Comprar"
	buy_button.pressed.connect(_on_gem_pack_purchase.bind(pack.get("id", "")))

	vbox.add_child(title)
	vbox.add_child(gems_count)
	vbox.add_child(price)
	vbox.add_child(buy_button)

	card.add_child(vbox)
	return card

func _create_premium_item_card(item: Dictionary) -> Control:
	"""Crear tarjeta de objeto premium"""
	var card = Panel.new()
	var vbox = VBoxContainer.new()

	# Título del objeto
	var title = Label.new()
	title.text = item.get("name", "")
	title.add_theme_font_size_override("font_size", 16)

	# Descripción
	var desc = Label.new()
	desc.text = item.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Costo en gemas
	var cost = Label.new()
	cost.text = "%d 💎" % item.get("gems_cost", 0)
	cost.add_theme_color_override("font_color", Color.CYAN)

	# Botón de compra
	var buy_button = Button.new()
	buy_button.text = "Comprar"

	var player_gems = Save.get_gems()
	var item_cost = item.get("gems_cost", 0)

	if player_gems >= item_cost:
		buy_button.pressed.connect(_on_item_purchase.bind(item.get("id", "")))
	else:
		buy_button.disabled = true
		buy_button.text = "Sin gemas suficientes"

	vbox.add_child(title)
	vbox.add_child(desc)
	vbox.add_child(cost)
	vbox.add_child(buy_button)

	card.add_child(vbox)
	return card

func _on_gem_pack_purchase(pack_id: String) -> void:
	"""Manejar compra de paquete de gemas"""
	Logger.info("Solicitud de compra de gemas: " + pack_id)
	# TODO: Integrar con sistema de compras reales
	gem_pack_purchased.emit(pack_id)

func _on_item_purchase(item_id: String) -> void:
	"""Manejar compra de objeto premium"""
	Logger.info("Compra de objeto premium: " + item_id)

	# Encontrar el objeto
	var item_data: Dictionary
	for item in premium_items:
		if item.get("id", "") == item_id:
			item_data = item
			break

	if item_data.is_empty():
		Logger.warn("Objeto no encontrado: " + item_id)
		return

	var cost = item_data.get("gems_cost", 0)
	var current_gems = Save.get_gems()

	if current_gems >= cost:
		Save.add_gems(-cost)
		Logger.info("Objeto comprado: %s por %d gemas" % [item_id, cost])
		# TODO: Entregar el objeto al jugador
		item_purchased.emit(item_id)
		_show_current_tab_content() # Refrescar para actualizar botones
	else:
		Logger.warn("Gemas insuficientes para comprar: " + item_id)

func _on_back_pressed() -> void:
	"""Cerrar pantalla de tienda"""
	store_screen_closed.emit()

func _format_number(number: int) -> String:
	"""Formatear números grandes"""
	if number >= 1000000:
		return "%.1fM" % (number / 1000000.0)
	elif number >= 1000:
		return "%.1fK" % (number / 1000.0)
	else:
		return str(number)
