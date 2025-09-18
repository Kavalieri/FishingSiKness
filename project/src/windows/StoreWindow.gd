extends Control
# StoreWindow.gd - Implementación de tienda usando FloatingWindowManager
# Sistema modular completamente separado del ScreenManager existente

@onready var currency_label: Label
@onready var items_scroll: ScrollContainer
@onready var items_grid: GridContainer

# Datos de la tienda
var store_items = [
	{"id": "gems_120", "name": "120 Gemas", "price": 50, "currency": "coins", "icon": "gem"},
	{"id": "mega_rod", "name": "Caña Mega", "price": 100, "currency": "gems", "icon": "rod"},
	{"id": "lucky_bait", "name": "Carnada de la Suerte", "price": 25, "currency": "gems", "icon": "bait"},
	{"id": "coins_1000", "name": "1000 Monedas", "price": 10, "currency": "gems", "icon": "coin"}
]

func _ready() -> void:
	# Inicialización mínima
	pass

func setup_content():
	"""Configurar el contenido específico de la tienda - llamado automáticamente"""
	setup_store_content()
	update_currency_display()

func setup_store_content() -> void:
	"""Configurar el contenido específico de la tienda"""
	# if not content_container:
	# 	print("ERROR content_container no encontrado en StoreWindow")
	# 	return

	# Crear título
	var title = Label.new()
	title.text = "TIENDA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	add_child(title)

	# Separador
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 10
	add_child(separator)

	# Crear display de moneda
	currency_label = Label.new()
	currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	currency_label.add_theme_font_size_override("font_size", 18)
	currency_label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(currency_label)

	# Otro separador
	var separator2 = HSeparator.new()
	separator2.custom_minimum_size.y = 15
	add_child(separator2)

	# Crear contenedor con scroll para ítems
	items_scroll = ScrollContainer.new()
	items_scroll.custom_minimum_size = Vector2(450, 350)
	items_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(items_scroll)

	# Grid para los ítems - cambiar a 2 columnas para mejor layout
	items_grid = GridContainer.new()
	items_grid.columns = 2
	items_grid.add_theme_constant_override("h_separation", 15)
	items_grid.add_theme_constant_override("v_separation", 15)
	items_scroll.add_child(items_grid)

	# Crear los ítems de la tienda
	for item_data in store_items:
		create_store_item(item_data)

func create_store_item(item_data: Dictionary):
	"""Crear un ítem de tienda"""
	var item_panel = Panel.new()
	item_panel.custom_minimum_size = Vector2(200, 140)

	# Estilo del panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.6, 0.6, 0.8, 1.0)
	item_panel.add_theme_stylebox_override("panel", style_box)

	# Contenedor principal
	var margin_container = MarginContainer.new()
	margin_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin_container.add_theme_constant_override("margin_left", 10)
	margin_container.add_theme_constant_override("margin_right", 10)
	margin_container.add_theme_constant_override("margin_top", 10)
	margin_container.add_theme_constant_override("margin_bottom", 10)
	item_panel.add_child(margin_container)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin_container.add_child(vbox)

	# Nombre del ítem
	var name_label = Label.new()
	name_label.text = item_data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Precio
	var price_label = Label.new()
	# Usar iconos simples sin emojis
	var currency_symbol = "COIN" if item_data.currency == "coins" else "GEM"
	price_label.text = "%s %d" % [currency_symbol, item_data.price]
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(price_label)

	# Botón de compra
	var buy_button = Button.new()
	buy_button.text = "Comprar"
	buy_button.pressed.connect(_on_item_purchased.bind(item_data))
	vbox.add_child(buy_button)

	items_grid.add_child(item_panel)

func _on_item_purchased(item_data: Dictionary):
	"""Procesar compra de ítem"""
	print("SHOP Intentando comprar: %s por %d %s" % [item_data.name, item_data.price, item_data.currency])

	# Validar si el jugador tiene suficiente moneda
	var current_currency = 0
	if item_data.currency == "coins":
		current_currency = Save.get_coins()
	else:
		current_currency = Save.get_gems()

	if current_currency < item_data.price:
		print("ERROR Fondos insuficientes")
		SFX.play_error()
		return

	# Procesar la compra
	if item_data.currency == "coins":
		Save.set_coins(Save.get_coins() - item_data.price)
	else:
		Save.set_gems(Save.get_gems() - item_data.price)

	# Otorgar el ítem comprado
	match item_data.id:
		"gems_120":
			Save.set_gems(Save.get_gems() + 120)
		"coins_1000":
			Save.set_coins(Save.get_coins() + 1000)
		_:
			print("GIFT Ítem %s agregado al inventario" % item_data.id)

	update_currency_display()
	SFX.play_purchase()
	print("SUCCESS Compra exitosa: %s" % item_data.name)

func update_currency_display():
	"""Actualizar la visualización de moneda"""
	if currency_label:
		currency_label.text = "COINS %d | GEMS %d" % [Save.get_coins(), Save.get_gems()]

func get_window_type() -> FloatingWindowManager.WindowType:
	"""Especificar que esta es una ventana de menú"""
	return FloatingWindowManager.WindowType.MENU
