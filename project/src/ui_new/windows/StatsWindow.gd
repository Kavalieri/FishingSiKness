extends Control

signal window_closed

var stats_data: Dictionary = {}
var recent_catches: Array = []

func _ready() -> void:
	visible = false
	_setup_ui()

func _setup_ui() -> void:
	# Fondo semi-transparente
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	
	# Panel principal
	var panel = PanelContainer.new()
	panel.anchor_left = 0.1
	panel.anchor_right = 0.9
	panel.anchor_top = 0.1
	panel.anchor_bottom = 0.9
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	
	# Título
	var title = Label.new()
	title.text = "ESTADÍSTICAS DE PESCA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	# Botón cerrar
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.anchor_left = 1.0
	close_btn.anchor_right = 1.0
	close_btn.offset_left = -50
	close_btn.offset_top = 10
	close_btn.offset_right = -10
	close_btn.offset_bottom = 50
	close_btn.pressed.connect(_close_window)
	panel.add_child(close_btn)
	
	# Contenido principal
	_create_stats_content(vbox)
	
	# Cerrar al hacer click en fondo
	bg.gui_input.connect(_on_background_clicked)

func _create_stats_content(parent: VBoxContainer) -> void:
	# Grid de estadísticas principales
	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 20)
	stats_grid.add_theme_constant_override("v_separation", 10)
	parent.add_child(stats_grid)
	
	# Estadísticas principales
	_add_stat_card(stats_grid, "Peces Hoy", "0", Color.CYAN)
	_add_stat_card(stats_grid, "Valor Ganado", "0 monedas", Color.GOLD)
	_add_stat_card(stats_grid, "Racha Actual", "0", Color.GREEN)
	_add_stat_card(stats_grid, "Tasa Éxito", "0%", Color.ORANGE)
	
	# Separador
	var sep = HSeparator.new()
	parent.add_child(sep)
	
	# Historial reciente
	var history_title = Label.new()
	history_title.text = "CAPTURAS RECIENTES"
	history_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	history_title.add_theme_font_size_override("font_size", 16)
	parent.add_child(history_title)
	
	# Scroll para historial
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 200
	parent.add_child(scroll)
	
	var history_list = VBoxContainer.new()
	history_list.add_theme_constant_override("separation", 8)
	scroll.add_child(history_list)
	
	# Guardar referencias
	set_meta("stats_grid", stats_grid)
	set_meta("history_list", history_list)

func _add_stat_card(parent: GridContainer, title: String, value: String, color: Color) -> void:
	var card = PanelContainer.new()
	card.add_theme_color_override("background_color", Color(0.2, 0.2, 0.2, 0.8))
	card.custom_minimum_size = Vector2(120, 80)
	parent.add_child(card)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", color)
	vbox.add_child(title_label)
	
	var value_label = Label.new()
	value_label.text = value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(value_label)
	
	# Guardar referencia para actualizar
	card.set_meta("value_label", value_label)
	card.set_meta("stat_type", title.to_lower().replace(" ", "_"))

func show_stats() -> void:
	_load_stats_data()
	_update_display()
	visible = true

func _load_stats_data() -> void:
	if StatsTracker:
		stats_data = StatsTracker.get_formatted_stats()
		recent_catches = StatsTracker.get_recent_catches()
	else:
		stats_data = {"today": {"fish_caught": 0, "value_earned": 0, "current_streak": 0, "success_rate": "0%"}}
		recent_catches = []

func _update_display() -> void:
	var stats_grid = get_meta("stats_grid", null)
	if not stats_grid:
		return
	
	var today = stats_data.get("today", {})
	
	# Actualizar tarjetas de estadísticas
	for card in stats_grid.get_children():
		var value_label = card.get_meta("value_label", null)
		var stat_type = card.get_meta("stat_type", "")
		
		if not value_label:
			continue
		
		match stat_type:
			"peces_hoy":
				value_label.text = str(today.get("fish_caught", 0))
			"valor_ganado":
				value_label.text = str(today.get("value_earned", 0)) + " monedas"
			"racha_actual":
				value_label.text = str(today.get("current_streak", 0))
			"tasa_éxito":
				value_label.text = today.get("success_rate", "0%")
	
	# Actualizar historial
	_update_history_display()

func _update_history_display() -> void:
	var history_list = get_meta("history_list", null)
	if not history_list:
		return
	
	# Limpiar historial anterior
	for child in history_list.get_children():
		child.queue_free()
	
	if recent_catches.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No hay capturas recientes"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color.GRAY)
		history_list.add_child(empty_label)
		return
	
	# Mostrar últimas 5 capturas
	var max_show = min(5, recent_catches.size())
	for i in range(max_show):
		var catch_data = recent_catches[i]
		_create_catch_item(history_list, catch_data)

func _create_catch_item(parent: VBoxContainer, catch_data: Dictionary) -> void:
	var item_panel = PanelContainer.new()
	item_panel.add_theme_color_override("background_color", Color(0.15, 0.15, 0.15, 0.9))
	parent.add_child(item_panel)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	item_panel.add_child(hbox)
	
	# Nombre del pez
	var name_label = Label.new()
	name_label.text = catch_data.get("name", "Pez")
	name_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(name_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	# Valor
	var value_label = Label.new()
	value_label.text = str(catch_data.get("value", 0)) + " monedas"
	value_label.add_theme_color_override("font_color", Color.GOLD)
	hbox.add_child(value_label)

func _close_window() -> void:
	visible = false
	window_closed.emit()
	queue_free()

func _on_background_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_window()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_close_window()
		get_viewport().set_input_as_handled()