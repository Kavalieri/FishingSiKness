class_name StoreView
extends Control

signal close_requested()

var store_container: VBoxContainer
var coins_label: Label
var gems_label: Label

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

func _ready():
	setup_ui()
	refresh_display()

func setup_ui():
	# Fondo opaco
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.95) # Más opaco
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.gui_input.connect(_on_background_clicked)
	add_child(background)

	# Panel principal (centrado dinámicamente)
	var main_panel = PanelContainer.new()
	add_child(main_panel)

	# Centrado dinámico en _ready
	call_deferred("_center_panel", main_panel)
	call_deferred("_setup_panel_content", main_panel)

func refresh_display():
	if not store_container:
		return

	# Actualizar monedas y gemas
	if coins_label:
		coins_label.text = "🪙 %d monedas" % Save.get_coins()
	if gems_label:
		gems_label.text = "💎 %d gemas" % Save.get_gems()

	# Limpiar productos anteriores
	for child in store_container.get_children():
		child.queue_free()

	# Crear productos
	for item_data in store_items:
		create_store_item(item_data)

func create_store_item(item_data: Dictionary):
	var item_container = PanelContainer.new()
	item_container.custom_minimum_size.y = 80
	store_container.add_child(item_container)

	var hbox = HBoxContainer.new()
	item_container.add_child(hbox)

	# Icono
	var icon_label = Label.new()
	icon_label.text = item_data.icon
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
	name_label.text = item_data.name
	name_label.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = item_data.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	info_vbox.add_child(desc_label)

	# Botón de compra
	var buy_button = Button.new()
	buy_button.custom_minimum_size = Vector2(120, 60)
	hbox.add_child(buy_button)

	var can_afford = false
	var currency_text = ""

	match item_data.currency:
		"real_money":
			currency_text = "$%.2f" % (item_data.cost / 100.0)
			can_afford = true # Siempre disponible para dinero real
			buy_button.text = "COMPRAR\n%s" % currency_text
		"gems":
			currency_text = "%d💎" % item_data.cost
			can_afford = Save.get_gems() >= item_data.cost
			buy_button.text = "COMPRAR\n%s" % currency_text
		"coins":
			currency_text = "%d🪙" % item_data.cost
			can_afford = Save.get_coins() >= item_data.cost
			buy_button.text = "COMPRAR\n%s" % currency_text

	if can_afford:
		buy_button.pressed.connect(_on_item_purchased.bind(item_data))
	else:
		buy_button.disabled = true
		buy_button.modulate = Color.GRAY

func _on_item_purchased(item_data: Dictionary):
	match item_data.currency:
		"real_money":
			# Simulación de compra con dinero real
			_process_real_money_purchase(item_data)
		"gems":
			if Save.spend_gems(item_data.cost):
				_grant_reward(item_data)
				if SFX:
					SFX.play_event("success")
				refresh_display()
			else:
				if SFX:
					SFX.play_event("error")
		"coins":
			if Save.spend_coins(item_data.cost):
				_grant_reward(item_data)
				if SFX:
					SFX.play_event("success")
				refresh_display()
			else:
				if SFX:
					SFX.play_event("error")

func _process_real_money_purchase(item_data: Dictionary):
	# En un juego real, aquí se integraría con Google Play/App Store
	# Por ahora, simulamos la compra exitosa
	print("Processing real money purchase: ", item_data.name)
	_grant_reward(item_data)
	if SFX:
		SFX.play_event("success")
	refresh_display()

	# Mostrar mensaje de confirmación
	var confirm_label = Label.new()
	confirm_label.text = "¡Compra exitosa!"
	confirm_label.add_theme_font_size_override("font_size", 20)
	confirm_label.add_theme_color_override("font_color", Color.GREEN)
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_label.position = Vector2(get_viewport().size.x / 2 - 100, 100)
	get_tree().current_scene.add_child(confirm_label)

	# Eliminar mensaje después de 2 segundos
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(confirm_label.queue_free)

func _grant_reward(item_data: Dictionary):
	match item_data.reward_type:
		"coins":
			Save.add_coins(item_data.reward_amount)
		"gems":
			Save.add_gems(item_data.reward_amount)

	print("Granted reward: ", item_data.reward_amount, " ", item_data.reward_type)

func _on_close_pressed():
	if SFX:
		SFX.play_event("click")
	emit_signal("close_requested")

func _on_background_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("close_requested")

func _input(event):
	# Permitir cerrar con ESC
	if event.is_action_pressed("ui_cancel"):
		emit_signal("close_requested")

func _setup_panel_content(main_panel: PanelContainer):
	"""Configurar el contenido del panel después del centrado"""
	var main_vbox = VBoxContainer.new()
	main_panel.add_child(main_vbox)

	# Header con título y botón cerrar
	var header = HBoxContainer.new()
	main_vbox.add_child(header)

	var title = Label.new()
	title.text = "🏪 TIENDA"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)

	var close_button = Button.new()
	close_button.text = "❌"
	close_button.custom_minimum_size = Vector2(48, 48)
	close_button.pressed.connect(_on_close_pressed)
	header.add_child(close_button)

	# Estado de monedas y gemas
	var currency_container = HBoxContainer.new()
	currency_container.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(currency_container)

	coins_label = Label.new()
	coins_label.add_theme_font_size_override("font_size", 20)
	currency_container.add_child(coins_label)

	var separator = VSeparator.new()
	separator.custom_minimum_size.x = 20
	currency_container.add_child(separator)

	gems_label = Label.new()
	gems_label.add_theme_font_size_override("font_size", 20)
	currency_container.add_child(gems_label)

	# Separador
	var hsep = HSeparator.new()
	hsep.custom_minimum_size.y = 10
	main_vbox.add_child(hsep)

	# Scroll container para productos
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	store_container = VBoxContainer.new()
	store_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(store_container)

func _center_panel(panel: PanelContainer):
	"""Centrar el panel dinámicamente en la pantalla"""
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_size = Vector2(viewport_size.x * 0.9, viewport_size.y * 0.9)

	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	panel.position = (viewport_size - panel_size) / 2

	# Hacer el panel semi-transparente para que se vea el fondo
	panel.modulate = Color(1, 1, 1, 0.95)

	# Asegurar que está visible
	panel.show()
