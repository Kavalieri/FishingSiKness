class_name MapView
extends Control

signal zone_changed(zone_id: String)

var zones_container: VBoxContainer
var current_zone_label: Label
var zone_info_panel: PanelContainer
var zone_info_container: VBoxContainer

func _ready():
	setup_background()
	setup_ui()
	refresh_display()

func setup_background():
	"""Configurar fondo principal usando BackgroundManager"""
	if BackgroundManager:
		BackgroundManager.setup_main_background(self)
		print("OK Fondo principal configurado en MapView")
	else:
		print("WARNING BackgroundManager no disponible en MapView")

func setup_ui():
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)
	main_vbox.anchor_right = 1.0
	main_vbox.anchor_bottom = 1.0
	main_vbox.offset_left = 10
	main_vbox.offset_right = -10
	main_vbox.offset_top = 10
	main_vbox.offset_bottom = -10

	# Título y zona actual
	var header = VBoxContainer.new()
	main_vbox.add_child(header)

	var title = Label.new()
	title.text = "MAP MAPA DE ZONAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	header.add_child(title)

	current_zone_label = Label.new()
	current_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current_zone_label.add_theme_font_size_override("font_size", 16)
	current_zone_label.add_theme_color_override("font_color", Color.GREEN)
	header.add_child(current_zone_label)

	# Separador
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 20
	main_vbox.add_child(separator)

	# Contenedor principal con dos columnas
	var main_container = HBoxContainer.new()
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(main_container)

	# Columna izquierda: Lista de zonas
	var zones_panel = VBoxContainer.new()
	zones_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zones_panel.size_flags_stretch_ratio = 0.6
	main_container.add_child(zones_panel)

	var zones_title = Label.new()
	zones_title.text = "MAP ZONAS DISPONIBLES"
	zones_title.add_theme_font_size_override("font_size", 18)
	zones_title.add_theme_color_override("font_color", Color.CYAN)
	zones_panel.add_child(zones_title)

	var zones_scroll = ScrollContainer.new()
	zones_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	zones_panel.add_child(zones_scroll)

	zones_container = VBoxContainer.new()
	zones_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zones_scroll.add_child(zones_container)

	# Separador vertical
	var v_separator = VSeparator.new()
	v_separator.custom_minimum_size.x = 20
	main_container.add_child(v_separator)

	# Columna derecha: Información de zona
	zone_info_panel = PanelContainer.new()
	zone_info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_info_panel.size_flags_stretch_ratio = 0.4
	zone_info_panel.add_theme_color_override("bg_color", Color(0.1, 0.1, 0.2, 0.8))
	main_container.add_child(zone_info_panel)

	zone_info_container = VBoxContainer.new()
	zone_info_container.add_theme_constant_override("separation", 10)
	zone_info_panel.add_child(zone_info_container)

	# Título del panel de información
	var info_title = Label.new()
	info_title.text = "CHART LEYENDA DE ZONAS"
	info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_title.add_theme_font_size_override("font_size", 18)
	info_title.add_theme_color_override("font_color", Color.GOLD)
	zone_info_container.add_child(info_title)

func refresh_display():
	if not zones_container or not current_zone_label:
		return

	# Mostrar zona actual con multiplicador
	var current_zone = Save.game_data.get("current_zone", "orilla")
	var zone_def = get_zone_definition(current_zone)
	if zone_def:
		current_zone_label.text = "Zona Actual: %s (x%.1f)" % [
			zone_def.name, zone_def.price_multiplier
		]

	# Limpiar zonas anteriores
	for child in zones_container.get_children():
		child.queue_free()

	# Limpiar información anterior
	for child in zone_info_container.get_children():
		if child.get_class() == "VBoxContainer": # Solo limpiar contenido, no título
			child.queue_free()

	# Crear botones de zonas usando Content system
	create_real_zone_buttons()

	# Crear leyenda de información
	create_zone_legend()

func create_real_zone_buttons():
	"""Crear botones usando el Content system real"""
	if not Content:
		return

	# Lista ordenada de zonas por progresión
	var zone_order = [
		"orilla", "lago", "rio", "costa", "mar",
		"glaciar", "industrial", "abismo", "infernal"
	]

	for zone_id in zone_order:
		var zone_def = Content.get_zone_by_id(zone_id)
		if zone_def:
			create_zone_button_from_def(zone_def)

func create_zone_button_from_def(zone_def: ZoneDef):
	"""Crear botón de zona usando ZoneDef real"""
	var container = VBoxContainer.new()
	container.custom_minimum_size.y = 120
	zones_container.add_child(container)

	var panel = PanelContainer.new()
	container.add_child(panel)

	var zone_vbox = VBoxContainer.new()
	zone_vbox.add_theme_constant_override("separation", 5)
	panel.add_child(zone_vbox)

	# Header con nombre y estado
	var header_hbox = HBoxContainer.new()
	zone_vbox.add_child(header_hbox)

	var name_label = Label.new()
	var zone_icon = get_zone_icon(zone_def.id)
	name_label.text = "%s %s" % [zone_icon, zone_def.name]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 18)
	header_hbox.add_child(name_label)

	var status_label = Label.new()
	header_hbox.add_child(status_label)

	# Información de zona
	var info_label = Label.new()
	info_label.text = "COINS Multiplicador: x%.1f • FISH Peces: %d especies" % [
		zone_def.price_multiplier, zone_def.entries.size()
	]
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	zone_vbox.add_child(info_label)

	# Botón de acción
	var action_button = Button.new()
	action_button.custom_minimum_size.y = 40
	zone_vbox.add_child(action_button)

	var current_zone = Save.game_data.get("current_zone", "orilla")
	var is_current = current_zone == zone_def.id
	var is_unlocked = is_zone_unlocked(zone_def.id)

	if is_current:
		status_label.text = "ACTUAL"
		status_label.add_theme_color_override("font_color", Color.GREEN)
		action_button.text = "OK Ya estás aquí"
		action_button.disabled = true
		panel.add_theme_color_override("bg_color", Color(0, 0.3, 0, 0.3))
	elif is_unlocked:
		status_label.text = "DISPONIBLE"
		status_label.add_theme_color_override("font_color", Color.CYAN)
		action_button.text = "ROCKET VIAJAR"
		action_button.pressed.connect(_on_zone_selected.bind(zone_def.id))
	else:
		status_label.text = "BLOQUEADA"
		status_label.add_theme_color_override("font_color", Color.RED)
		var unlock_cost = get_zone_unlock_cost(zone_def.id)
		action_button.text = "UNLOCKED DESBLOQUEAR (%s)" % format_currency(unlock_cost)

		if Save.get_coins() >= unlock_cost:
			action_button.pressed.connect(_on_zone_unlock.bind(zone_def.id, unlock_cost))
		else:
			action_button.disabled = true
			action_button.add_theme_color_override("font_color", Color.GRAY)

func get_zone_icon(zone_id: String) -> String:
	"""Obtener icono representativo para cada zona"""
	var zone_icons = {
		"orilla": "BEACH",
		"lago": "ZONE",
		"rio": "FOREST",
		"costa": "SUNSET",
		"mar": "ZONE",
		"glaciar": "MOUNTAIN",
		"industrial": "INDUSTRIAL",
		"abismo": "SPACE",
		"infernal": "FIRE"
	}
	return zone_icons.get(zone_id, "MAP")

func create_zone_legend():
	"""Crear leyenda de información de todas las zonas"""
	if not Content:
		return

	var legend_container = VBoxContainer.new()
	legend_container.add_theme_constant_override("separation", 8)
	zone_info_container.add_child(legend_container)

	# Lista de zonas ordenada por multiplicador
	var zone_order = [
		"orilla", "lago", "rio", "costa", "mar",
		"glaciar", "industrial", "abismo", "infernal"
	]

	for zone_id in zone_order:
		var zone_def = Content.get_zone_by_id(zone_id)
		if zone_def:
			create_zone_info_entry(legend_container, zone_def)

	# Separador y resumen
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 5
	legend_container.add_child(separator)

	var summary_label = Label.new()
	summary_label.text = "IDEA Los multiplicadores afectan el valor final " + \
		"de todos los peces capturados en cada zona."
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.add_theme_font_size_override("font_size", 12)
	summary_label.add_theme_color_override("font_color", Color.YELLOW)
	legend_container.add_child(summary_label)

func create_zone_info_entry(parent: VBoxContainer, zone_def: ZoneDef):
	"""Crear entrada de información para una zona"""
	var entry_container = VBoxContainer.new()
	entry_container.add_theme_constant_override("separation", 2)
	parent.add_child(entry_container)

	# Nombre y multiplicador
	var header_label = Label.new()
	var zone_icon = get_zone_icon(zone_def.id)
	header_label.text = "%s %s (x%.1f)" % [
		zone_icon, zone_def.name, zone_def.price_multiplier
	]
	header_label.add_theme_font_size_override("font_size", 14)
	var multiplier_color = get_multiplier_color(zone_def.price_multiplier)
	header_label.add_theme_color_override("font_color", multiplier_color)
	entry_container.add_child(header_label)

	# Lista de peces
	var fish_names = []
	for entry in zone_def.entries:
		if entry.fish:
			fish_names.append(entry.fish.name)

	var fish_label = Label.new()
	fish_label.text = "  FISH %s" % ", ".join(fish_names)
	fish_label.add_theme_font_size_override("font_size", 12)
	fish_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fish_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	entry_container.add_child(fish_label)

func get_multiplier_color(multiplier: float) -> Color:
	"""Obtener color según multiplicador de zona"""
	if multiplier >= 2.5:
		return Color.GOLD # Legendario
	if multiplier >= 2.0:
		return Color.MAGENTA # Épico
	if multiplier >= 1.5:
		return Color.CYAN # Raro
	if multiplier > 1.0:
		return Color.LIME_GREEN # Poco común

	return Color.WHITE # Común

func get_zone_definition(zone_id: String) -> ZoneDef:
	"""Obtener definición de zona desde Content system"""
	if Content:
		return Content.get_zone_by_id(zone_id)
	return null

func _on_zone_selected(zone_id: String):
	var current_zone = Save.game_data.get("current_zone", "orilla")
	if zone_id != current_zone:
		Save.game_data.current_zone = zone_id

		if SFX:
			SFX.play_event("success")

		print("Traveled to zone: ", zone_id)
		refresh_display()

		# Emitir señal para actualizar fondo y TopBar
		emit_signal("zone_changed", zone_id)

func _on_zone_unlock(zone_id: String, cost: int):
	"""Manejar desbloqueo de zona"""
	if Save.spend_coins(cost):
		# Añadir zona a las desbloqueadas
		if not Save.game_data.has("unlocked_zones"):
			Save.game_data.unlocked_zones = ["orilla"]

		if not Save.game_data.unlocked_zones.has(zone_id):
			Save.game_data.unlocked_zones.append(zone_id)

		if SFX:
			SFX.play_event("success")

		print("Zone unlocked: %s for %d coins" % [zone_id, cost])
		refresh_display()
	else:
		if SFX:
			SFX.play_event("error")
		print("Not enough coins to unlock zone: %s" % zone_id)

func is_zone_unlocked(zone_id: String) -> bool:
	"""Verificar si una zona está desbloqueada"""
	# La zona inicial siempre está desbloqueada
	if zone_id == "orilla":
		return true

	var unlocked_zones = Save.game_data.get("unlocked_zones", ["orilla"])
	return unlocked_zones.has(zone_id)

func get_zone_unlock_cost(zone_id: String) -> int:
	"""Obtener costo de desbloqueo exponencial para cada zona"""
	var zone_costs = {
		"orilla": 0, # Gratis
		"lago": 1000, # 1K
		"rio": 5000, # 5K
		"costa": 25000, # 25K
		"mar": 100000, # 100K
		"glaciar": 500000, # 500K
		"industrial": 2000000, # 2M
		"abismo": 10000000, # 10M
		"infernal": 50000000 # 50M
	}
	return zone_costs.get(zone_id, 0)

func format_currency(amount: int) -> String:
	"""Formatear cantidades grandes de dinero"""
	if amount >= 1000000000: # Billones
		return "%.1fB" % (amount / 1000000000.0)
	if amount >= 1000000: # Millones
		return "%.1fM" % (amount / 1000000.0)
	if amount >= 1000: # Miles
		return "%.1fK" % (amount / 1000.0)

	return str(amount)
