# Versión compleja de InventoryPanel (no usar class_name para evitar conflictos)
extends ColorRect

signal fish_selected(fish_index: int)
signal fish_deselected(fish_index: int)
signal sell_selected_requested()
signal sell_all_requested()
signal discard_selected_requested()
signal discard_all_requested()
signal close_requested()

# Referencias a UI (se conectan automáticamente desde la escena)
@onready var fish_grid_container: GridContainer = $MainContainer/FishScrollContainer/FishGridContainer
@onready var sell_selected_button: Button = $MainContainer/ActionsContainer/SellSelectedButton
@onready var sell_all_button: Button = $MainContainer/ActionsContainer/SellAllButton
@onready var discard_selected_button: Button = $MainContainer/ActionsContainer/DiscardSelectedButton
@onready var discard_all_button: Button = $MainContainer/ActionsContainer/DiscardAllButton
@onready var close_button: Button = $MainContainer/HeaderContainer/CloseButton

func _ready():
	# Conectar señales de los botones
	if sell_selected_button:
		sell_selected_button.pressed.connect(_on_sell_selected_pressed)
	if sell_all_button:
		sell_all_button.pressed.connect(_on_sell_all_pressed)
	if discard_selected_button:
		discard_selected_button.pressed.connect(_on_discard_selected_pressed)
	if discard_all_button:
		discard_all_button.pressed.connect(_on_discard_all_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

var main_panel: PanelContainer
var inventory_grid: GridContainer
var info_container: VBoxContainer
var selected_fish_indices: Array[int] = []
var show_sell_buttons: bool = true
var title_text: String = "🧊 INVENTARIO"

func _init(show_sell: bool = true, title: String = "🧊 INVENTARIO"):
	show_sell_buttons = show_sell
	title_text = title

# El resto de funciones ya están definidas más abajo

func refresh_display():
	"""Configurar el contenido del panel después del centrado"""
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	# Agregar margen interno
	main_vbox.add_theme_constant_override("margin_left", 20)
	main_vbox.add_theme_constant_override("margin_right", 20)
	main_vbox.add_theme_constant_override("margin_top", 20)
	main_vbox.add_theme_constant_override("margin_bottom", 20)
	main_panel.add_child(main_vbox)

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

	# Botones de acción (venta y descarte)
	if show_sell_buttons:
		var button_container = VBoxContainer.new()
		button_container.add_theme_constant_override("separation", 10)
		main_vbox.add_child(button_container)

		# Fila superior: Botones de venta
		var sell_row = HBoxContainer.new()
		sell_row.alignment = BoxContainer.ALIGNMENT_CENTER
		button_container.add_child(sell_row)

		var sell_selected_btn = Button.new()
		sell_selected_btn.text = "💰 VENDER SELECCIONADO"
		sell_selected_btn.custom_minimum_size = Vector2(200, 50)
		sell_selected_btn.add_theme_color_override("font_color", Color.WHITE)
		sell_selected_btn.add_theme_color_override("font_hover_color", Color.LIGHT_GREEN)
		sell_selected_btn.pressed.connect(_on_sell_selected_pressed)
		sell_row.add_child(sell_selected_btn)

		var separator1 = VSeparator.new()
		separator1.custom_minimum_size.x = 20
		sell_row.add_child(separator1)

		var sell_all_btn = Button.new()
		sell_all_btn.text = "💰 VENDER TODO"
		sell_all_btn.custom_minimum_size = Vector2(200, 50)
		sell_all_btn.add_theme_color_override("font_color", Color.WHITE)
		sell_all_btn.add_theme_color_override("font_hover_color", Color.LIGHT_GREEN)
		sell_all_btn.pressed.connect(_on_sell_all_pressed)
		sell_row.add_child(sell_all_btn)

		# Fila inferior: Botones de descarte
		var discard_row = HBoxContainer.new()
		discard_row.alignment = BoxContainer.ALIGNMENT_CENTER
		button_container.add_child(discard_row)

		var discard_selected_btn = Button.new()
		discard_selected_btn.text = "🗑️ DESCARTAR SELECCIONADO"
		discard_selected_btn.custom_minimum_size = Vector2(200, 50)
		discard_selected_btn.add_theme_color_override("font_color", Color.WHITE)
		discard_selected_btn.add_theme_color_override("font_hover_color", Color.ORANGE_RED)
		discard_selected_btn.pressed.connect(_on_discard_selected_pressed)
		discard_row.add_child(discard_selected_btn)

		var separator2 = VSeparator.new()
		separator2.custom_minimum_size.x = 20
		discard_row.add_child(separator2)

		var discard_all_btn = Button.new()
		discard_all_btn.text = "🗑️ DESCARTAR TODO"
		discard_all_btn.custom_minimum_size = Vector2(200, 50)
		discard_all_btn.add_theme_color_override("font_color", Color.WHITE)
		discard_all_btn.add_theme_color_override("font_hover_color", Color.ORANGE_RED)
		discard_all_btn.pressed.connect(_on_discard_all_pressed)
		discard_row.add_child(discard_all_btn)

# FUNCIÓN DUPLICADA COMENTADA - usar la anterior
#func refresh_display():
#	if not inventory_grid or not info_container:
#		return
#
#	# Limpiar grid anterior
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

	# Configurar colores según rareza si existe
	if fish_data.has("rarity_color"):
		var color = fish_data.get("rarity_color", Color.WHITE)
		fish_button.modulate = color

	if show_sell_buttons:
		fish_button.pressed.connect(_on_fish_toggled.bind(index))

	# Doble clic o clic derecho para mostrar info detallada
	fish_button.gui_input.connect(_on_fish_button_input.bind(index))

	inventory_grid.add_child(fish_button)

func _on_fish_button_input(event: InputEvent, fish_index: int):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.double_click:
			emit_signal("fish_info_requested", fish_index)
			accept_event()

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
		var selected_value = calculate_selected_value()
		var selected_count = selected_fish_indices.size()
		show_confirmation_popup(
			"💰 CONFIRMAR VENTA",
			"¿Vender %d peces seleccionados por %d monedas?" % [selected_count, selected_value],
			_confirm_sell_selected
		)
	else:
		if SFX:
			SFX.play_event("error")

func _on_sell_all_pressed():
	var inventory = Save.get_inventory()
	if inventory.size() > 0:
		var total_value = calculate_total_value()
		show_confirmation_popup(
			"💰 CONFIRMAR VENTA",
			"¿Vender TODOS los %d peces por %d monedas?" % [inventory.size(), total_value],
			_confirm_sell_all
		)
	else:
		if SFX:
			SFX.play_event("error")

func _on_discard_selected_pressed():
	if selected_fish_indices.size() > 0:
		var selected_value = calculate_selected_value()
		var selected_count = selected_fish_indices.size()
		var message = "¿DESCARTAR %d peces seleccionados?\n⚠️ PERDERÁS %d monedas de valor"
		show_confirmation_popup(
			"🗑️ CONFIRMAR DESCARTE",
			message % [selected_count, selected_value],
			_confirm_discard_selected
		)
	else:
		if SFX:
			SFX.play_event("error")

func _on_discard_all_pressed():
	var inventory = Save.get_inventory()
	if inventory.size() > 0:
		var total_value = calculate_total_value()
		var message = "¿DESCARTAR TODOS los %d peces?\n⚠️ PERDERÁS %d monedas de valor"
		show_confirmation_popup(
			"🗑️ CONFIRMAR DESCARTE",
			message % [inventory.size(), total_value],
			_confirm_discard_all
		)
	else:
		if SFX:
			SFX.play_event("error")

func _on_close_pressed():
	emit_signal("close_requested")
	if SFX:
		SFX.play_event("click")

func _on_background_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Solo cerrar si se hace click en el fondo, no en el panel
		emit_signal("close_requested")

func _input(event):
	# Permitir cerrar con ESC
	if event.is_action_pressed("ui_cancel"):
		emit_signal("close_requested")

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

func _center_panel_fullscreen(panel: PanelContainer):
	"""Centrar el panel para ocupar toda la pantalla"""
	var viewport_size = get_viewport().get_visible_rect().size

	panel.custom_minimum_size = viewport_size
	panel.size = viewport_size
	panel.position = Vector2.ZERO

	# Hacer el panel semi-transparente para que se vea el fondo
	panel.modulate = Color(1, 1, 1, 1.0) # 100% opaco

	# Asegurar que está visible y en primer plano
	panel.show()
	panel.z_index = 100

func calculate_selected_value() -> int:
	var total = 0
	var inventory = Save.get_inventory()
	for index in selected_fish_indices:
		if index < inventory.size():
			total += inventory[index].get("value", 0)
	return total

func show_confirmation_popup(title: String, message: String, confirm_callback: Callable):
	"""Mostrar popup de confirmación"""
	var popup = create_confirmation_popup(title, message, confirm_callback)
	add_child(popup)

func create_confirmation_popup(title: String, message: String,
		confirm_callback: Callable) -> Control:
	"""Crear popup de confirmación personalizado"""
	var overlay = Control.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.z_index = 200

	# Fondo 100% opaco - consistente con otros menús
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 1.0)
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	overlay.add_child(background)

	# Panel del popup
	var popup_panel = PanelContainer.new()
	popup_panel.custom_minimum_size = Vector2(400, 200)
	popup_panel.position = Vector2(
		(get_viewport().get_visible_rect().size.x - 400) / 2,
		(get_viewport().get_visible_rect().size.y - 200) / 2
	)
	overlay.add_child(popup_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	popup_panel.add_child(vbox)

	# Título
	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(title_label)

	# Mensaje
	var message_label = Label.new()
	message_label.text = message
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(message_label)

	# Botones
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_container)

	var confirm_btn = Button.new()
	confirm_btn.text = "✅ CONFIRMAR"
	confirm_btn.custom_minimum_size = Vector2(120, 40)
	confirm_btn.add_theme_color_override("font_color", Color.WHITE)
	confirm_btn.add_theme_color_override("font_hover_color", Color.LIGHT_GREEN)
	confirm_btn.pressed.connect(func():
		confirm_callback.call()
		overlay.queue_free()
	)
	button_container.add_child(confirm_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "❌ CANCELAR"
	cancel_btn.custom_minimum_size = Vector2(120, 40)
	cancel_btn.add_theme_color_override("font_color", Color.WHITE)
	cancel_btn.add_theme_color_override("font_hover_color", Color.ORANGE_RED)
	cancel_btn.pressed.connect(func(): overlay.queue_free())
	button_container.add_child(cancel_btn)

	return overlay

func _confirm_sell_selected():
	"""Confirmar venta de peces seleccionados"""
	emit_signal("sell_selected_requested")
	if SFX:
		SFX.play_event("success")

func _confirm_sell_all():
	"""Confirmar venta de todos los peces"""
	emit_signal("sell_all_requested")
	if SFX:
		SFX.play_event("success")

func _confirm_discard_selected():
	"""Confirmar descarte de peces seleccionados"""
	emit_signal("discard_selected_requested")
	if SFX:
		SFX.play_event("success")

func _confirm_discard_all():
	"""Confirmar descarte de todos los peces"""
	emit_signal("discard_all_requested")
	if SFX:
		SFX.play_event("success")
