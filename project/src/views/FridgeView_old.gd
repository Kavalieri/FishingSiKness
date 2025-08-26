# FridgeView versión antigua (archivado)
extends Control

var inventory_grid: GridContainer
var sell_selected_btn: Button
var sell_all_btn: Button
var capacity_label: Label

var selected_fish_indices := []

func _ready():
	setup_ui()
	refresh_display()

func setup_ui():
	# Crear la interfaz de la nevera
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)
	main_vbox.anchor_right = 1.0
	main_vbox.anchor_bottom = 1.0
	main_vbox.offset_left = 10
	main_vbox.offset_right = -10
	main_vbox.offset_top = 10
	main_vbox.offset_bottom = -10

	# Etiqueta de capacidad
	capacity_label = Label.new()
	capacity_label.text = "Capacidad: 0/12"
	capacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(capacity_label)

	# Scroll container para el inventario
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	# Grid container para los peces (3 columnas)
	inventory_grid = GridContainer.new()
	inventory_grid.columns = 3
	inventory_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(inventory_grid)

	# Botones de venta
	var button_container = HBoxContainer.new()
	main_vbox.add_child(button_container)

	sell_selected_btn = Button.new()
	sell_selected_btn.text = "VENDER SELECCIÓN"
	sell_selected_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_selected_btn.custom_minimum_size.y = 48
	sell_selected_btn.pressed.connect(_on_sell_selected_pressed)
	button_container.add_child(sell_selected_btn)

	sell_all_btn = Button.new()
	sell_all_btn.text = "VENDER TODO"
	sell_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_all_btn.custom_minimum_size.y = 48
	sell_all_btn.pressed.connect(_on_sell_all_pressed)
	button_container.add_child(sell_all_btn)

func _on_visibility_changed():
	if visible:
		refresh_display()

func refresh_display():
	if not inventory_grid:
		return

	# Limpiar grid
	for child in inventory_grid.get_children():
		child.queue_free()

	selected_fish_indices.clear()

	# Actualizar capacidad
	var current_count = Save.get_inventory_count()
	var max_count = Save.get_max_inventory()
	capacity_label.text = "Capacidad: %d/%d" % [current_count, max_count]

	# Añadir peces al grid
	var inventory = Save.get_inventory()
	for i in range(inventory.size()):
		var fish_data = inventory[i]
		var fish_button = create_fish_button(fish_data, i)
		inventory_grid.add_child(fish_button)

	# Llenar espacios vacíos hasta completar el grid
	var empty_slots = max_count - current_count
	for i in range(empty_slots):
		var empty_button = create_empty_slot()
		inventory_grid.add_child(empty_button)

func create_fish_button(fish_data: Dictionary, index: int) -> Button:
	var button = Button.new()
	var name = fish_data.get("name", "Pez")
	var size = fish_data.get("size", 0.0)
	var value = fish_data.get("value", 0)

	button.text = "%s\n%.1fcm\n%dc" % [name, size, value]
	button.custom_minimum_size = Vector2(120, 80)
	button.toggle_mode = true
	button.pressed.connect(_on_fish_selected.bind(index, button))

	return button

func create_empty_slot() -> Control:
	var button = Button.new()
	button.text = "Vacío"
	button.custom_minimum_size = Vector2(120, 80)
	button.disabled = true
	return button

func _on_fish_selected(index: int, button: Button):
	if button.button_pressed:
		selected_fish_indices.append(index)
	else:
		selected_fish_indices.erase(index)

	# Actualizar botón de vender selección
	if selected_fish_indices.size() > 0:
		sell_selected_btn.text = "VENDER SELECCIÓN (%d)" % selected_fish_indices.size()
	else:
		sell_selected_btn.text = "VENDER SELECCIÓN"

func _on_sell_selected_pressed():
	if selected_fish_indices.size() == 0:
		return

	# Ordenar indices de mayor a menor para no afectar el orden al eliminar
	selected_fish_indices.sort()
	selected_fish_indices.reverse()

	var total_value = 0
	for index in selected_fish_indices:
		total_value += Save.sell_fish(index)

	if SFX:
		SFX.play_event("success")

	print("Sold selected fish for ", total_value, " coins")
	refresh_display()

func _on_sell_all_pressed():
	var total_value = Save.sell_all_fish()

	if SFX:
		SFX.play_event("success")

	print("Sold all fish for ", total_value, " coins")
	refresh_display()
