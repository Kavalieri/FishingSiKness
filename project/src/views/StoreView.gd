class_name StoreView
extends BaseWindow

# NOTA: En el futuro, este array debería reemplazarse por la carga de recursos .tres
# desde el directorio 'project/data/store/' para un diseño 100% data-driven.
var store_items = [
	{
		"id": "gems_pack_small", "name": "Pack Pequeño de Gemas",
		"description": "25 gemas brillantes", "cost": 99, "currency": "real_money",
		"reward_type": "gems", "reward_amount": 25, "icon": "GEMS"
	},
	{
		"id": "gems_pack_medium", "name": "Pack Mediano de Gemas",
		"description": "60 gemas brillantes + 5 extra", "cost": 199, "currency": "real_money",
		"reward_type": "gems", "reward_amount": 65, "icon": "GEMSGEMS"
	},
	{
		"id": "coins_for_gems_small", "name": "Monedas Rápidas",
		"description": "500 monedas instantáneas", "cost": 5, "currency": "gems",
		"reward_type": "coins", "reward_amount": 500, "icon": "🪙"
	},
	{
		"id": "coins_for_gems_large", "name": "Cofre de Monedas",
		"description": "2000 monedas instantáneas", "cost": 15, "currency": "gems",
		"reward_type": "coins", "reward_amount": 2000, "icon": "COINS"
	}
]

# Referencias a los nodos que existen en nuestra escena StoreView.tscn
@onready var coins_label: Label = %CoinsLabel
@onready var gems_label: Label = %GemsLabel
@onready var store_items_container: VBoxContainer = %StoreItemsContainer


# Este método es llamado automáticamente por BaseWindow después de que la ventana se abre.
func _setup_content() -> void:
	# La lógica que antes estaba en _ready o setup_menu ahora va aquí.
	update_currency_display()
	populate_store_items()


func update_currency_display() -> void:
	# Esta función ahora es más segura porque los nodos están garantizados por la escena.
	var coins = Save.get_coins() if Save else 0
	coins_label.text = "COINS: %d" % coins
	
	var gems = Save.get_gems() if Save else 0
	gems_label.text = "GEMS: %d" % gems


func populate_store_items() -> void:
	# Limpiar elementos anteriores para evitar duplicados si se refresca.
	for child in store_items_container.get_children():
		child.queue_free()

	# Crear cada producto a partir de nuestros datos.
	for item_data in store_items:
		create_store_item_widget(item_data)


func create_store_item_widget(item_data: Dictionary) -> void:
	# Creamos el widget para un solo item de la tienda.
	# NOTA: En el futuro, esto podría ser su propia escena 'StoreItemWidget.tscn'.
	var item_panel = PanelContainer.new()
	item_panel.custom_minimum_size.y = 80
	store_items_container.add_child(item_panel)

	var hbox = HBoxContainer.new()
	item_panel.add_child(hbox)

	var icon = Label.new()
	icon.text = item_data.get("icon", "?")
	icon.custom_minimum_size = Vector2(80, 0)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = item_data.get("name", "Producto")
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = item_data.get("description", "")
	desc_label.modulate = Color.GRAY
	info_vbox.add_child(desc_label)

	var buy_button = Button.new()
	var cost = item_data.get("cost", 0)
	var currency_symbol = "$" if item_data.get("currency") == "real_money" else "GEMS"
	buy_button.text = "%s %d" % [currency_symbol, cost]
	buy_button.custom_minimum_size.x = 120
	buy_button.pressed.connect(_on_buy_pressed.bind(item_data))
	hbox.add_child(buy_button)


func _on_buy_pressed(item_data: Dictionary) -> void:
	print("Intentando comprar: ", item_data.get("name"))
	# Aquí iría la lógica de compra real, llamando a un sistema de economía.