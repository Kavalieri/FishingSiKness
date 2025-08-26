class_name InventoryPanel
extends PanelContainer

signal fish_selected(fish_index: int)
signal fish_deselected(fish_index: int)
signal sell_selected_requested()
signal sell_all_requested()
signal close_requested()

var inventory_grid: GridContainer
var info_container: VBoxContainer
var selected_fish_indices: Array[int] = []
var show_sell_buttons: bool = true
var title_text: String = "🧊 INVENTARIO"

func _init(show_sell: bool = true, title: String = "🧊 INVENTARIO"):
	show_sell_buttons = show_sell
	title_text = title

func _ready():
	setup_ui()
	refresh_display()

func setup_ui():
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)

	# Header con título y botón cerrar
	var header = HBoxContainer.new()
	main_vbox.add_child(header)

	var title = Label.new()
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)

	var close_button = Button.new()
	close_button.text = "❌"
	close_button.custom_minimum_size = Vector2(40, 40)
	close_button.pressed.connect(_on_close_pressed)
	header.add_child(close_button)

	# Info del inventario
	info_container = VBoxContainer.new()
	main_vbox.add_child(info_container)

	# Scroll container para el grid
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 400
	main_vbox.add_child(scroll)

	# Grid 3 columnas para los peces
	inventory_grid = GridContainer.new()
	inventory_grid.columns = 3
	inventory_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(inventory_grid)

	# Botones de venta (opcional)
	if show_sell_buttons:
		var button_container = HBoxContainer.new()
		button_container.alignment = BoxContainer.ALIGNMENT_CENTER
		main_vbox.add_child(button_container)

		var sell_selected_btn = Button.new()
		sell_selected_btn.text = "VENDER SELECCIONADO"
		sell_selected_btn.custom_minimum_size.y = 50
		sell_selected_btn.pressed.connect(_on_sell_selected_pressed)
		button_container.add_child(sell_selected_btn)

		var separator = VSeparator.new()
		separator.custom_minimum_size.x = 10
		button_container.add_child(separator)

		var sell_all_btn = Button.new()
		sell_all_btn.text = "VENDER TODO"
		sell_all_btn.custom_minimum_size.y = 50
		sell_all_btn.pressed.connect(_on_sell_all_pressed)
		button_container.add_child(sell_all_btn)

func refresh_display():
	if not inventory_grid or not info_container:
		return

	# Limpiar grid anterior
	for child in inventory_grid.get_children():
		child.queue_free()

	# Limpiar info anterior
	for child in info_container.get_children():
		child.queue_free()

	selected_fish_indices.clear()

	var inventory = Save.get_inventory()
	var max_inventory = Save.game_data.get("max_inventory", 12)

	# Mostrar información del inventario
	var capacity_label = Label.new()
	capacity_label.text = "📦 Capacidad: %d/%d" % [inventory.size(), max_inventory]
	capacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	capacity_label.add_theme_font_size_override("font_size", 16)
	info_container.add_child(capacity_label)

	if show_sell_buttons and inventory.size() > 0:
		var total_value = calculate_total_value()
		var value_label = Label.new()
		value_label.text = "💰 Valor total: %d monedas" % total_value
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.add_theme_font_size_override("font_size", 16)
		value_label.add_theme_color_override("font_color", Color.GOLD)
		info_container.add_child(value_label)

	# Separador
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 10
	info_container.add_child(separator)

	# Crear botones de peces
	for i in range(inventory.size()):
		var fish_data = inventory[i]
		create_fish_button(fish_data, i)

	# Llenar espacios vacíos hasta la capacidad máxima
	for i in range(inventory.size(), max_inventory):
		create_empty_slot()

func create_fish_button(fish_data: Dictionary, index: int):
	var fish_button = Button.new()
	fish_button.custom_minimum_size = Vector2(120, 100)
	fish_button.toggle_mode = true

	# Texto del botón con información del pez
	var fish_name = fish_data.get("name", "Pez")
	var fish_size = fish_data.get("size", 1.0)
	var fish_value = fish_data.get("value", 10)

	fish_button.text = "%s\n%.1fcm\n%d🪙" % [fish_name, fish_size, fish_value]

	if show_sell_buttons:
		fish_button.pressed.connect(_on_fish_toggled.bind(index))

	inventory_grid.add_child(fish_button)

func create_empty_slot():
	var empty_slot = Button.new()
	empty_slot.custom_minimum_size = Vector2(120, 100)
	empty_slot.text = "Vacío"
	empty_slot.disabled = true
	empty_slot.modulate = Color(0.5, 0.5, 0.5)
	inventory_grid.add_child(empty_slot)

func _on_fish_toggled(index: int):
	var fish_button = inventory_grid.get_child(index)

	if fish_button.button_pressed:
		selected_fish_indices.append(index)
		fish_button.modulate = Color.YELLOW
		emit_signal("fish_selected", index)
	else:
		selected_fish_indices.erase(index)
		fish_button.modulate = Color.WHITE
		emit_signal("fish_deselected", index)

	if SFX:
		SFX.play_event("click")

func _on_sell_selected_pressed():
	if selected_fish_indices.size() > 0:
		emit_signal("sell_selected_requested")
		if SFX:
			SFX.play_event("success")
	else:
		if SFX:
			SFX.play_event("error")

func _on_sell_all_pressed():
	var inventory = Save.get_inventory()
	if inventory.size() > 0:
		emit_signal("sell_all_requested")
		if SFX:
			SFX.play_event("success")
	else:
		if SFX:
			SFX.play_event("error")

func _on_close_pressed():
	emit_signal("close_requested")
	if SFX:
		SFX.play_event("click")

func calculate_total_value() -> int:
	var total = 0
	var inventory = Save.get_inventory()
	for fish_data in inventory:
		total += fish_data.get("value", 0)
	return total

func get_selected_fish_indices() -> Array[int]:
	return selected_fish_indices.duplicate()

func clear_selection():
	selected_fish_indices.clear()
	for i in range(inventory_grid.get_child_count()):
		var child = inventory_grid.get_child(i)
		if child is Button:
			child.button_pressed = false
			child.modulate = Color.WHITE
