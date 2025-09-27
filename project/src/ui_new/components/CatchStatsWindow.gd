class_name CatchStatsWindow
extends AcceptDialog

# Ventana de estadísticas/historial de capturas

signal window_closed

@onready var catch_list: VBoxContainer = $VBoxContainer/ScrollContainer/CatchList
@onready var empty_state_panel: PanelContainer = $VBoxContainer/ScrollContainer/CatchList/EmptyStatePanel

var catch_item_scene: PackedScene
var recent_catches: Array[Dictionary] = []

func _ready() -> void:
	# Cargar la escena del item de captura
	catch_item_scene = preload("res://scenes/ui_new/components/CatchHistoryItem.tscn")

	# Conectar señales
	close_requested.connect(_on_close_requested)
	confirmed.connect(_on_close_requested)

	# Configurar el diálogo
	get_ok_button().text = "Cerrar"

func show_catch_stats() -> void:
	"""Mostrar la ventana con estadísticas actuales"""
	_load_stats_and_catches()
	_populate_stats_and_catches()
	
	# Configurar input handling
	set_process_input(true)
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	popup_centered()

func _load_stats_and_catches() -> void:
	"""Cargar estadísticas y capturas recientes"""
	recent_catches.clear()

	# Cargar desde StatsTracker si está disponible
	if StatsTracker:
		recent_catches = StatsTracker.get_recent_catches()
		print("📊 [CatchStats] Cargadas %d capturas desde StatsTracker" % recent_catches.size())
		return
	
	# Fallback: cargar desde Save
	if Save:
		var catch_history = Save.get_catch_history(10)
		if catch_history and catch_history.size() > 0:
			recent_catches = catch_history
			print("📊 [CatchStats] Cargadas %d capturas desde Save" % recent_catches.size())
	else:
		print("⚠️ [CatchStats] No hay sistemas de estadísticas disponibles")

func _populate_stats_and_catches() -> void:
	"""Poblar la ventana con estadísticas y capturas"""
	# Limpiar lista actual (excepto el estado vacío)
	for child in catch_list.get_children():
		if child != empty_state_panel:
			child.queue_free()

	# Añadir panel de estadísticas primero
	_add_stats_panel()

	# Si no hay capturas, mostrar estado vacío
	if recent_catches.is_empty():
		empty_state_panel.visible = true
		return

	# Ocultar estado vacío y mostrar capturas
	empty_state_panel.visible = false

	# Añadir separador
	var separator = HSeparator.new()
	catch_list.add_child(separator)
	
	# Añadir título de historial
	var history_title = Label.new()
	history_title.text = "HISTORIAL RECIENTE"
	history_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	history_title.add_theme_font_size_override("font_size", 14)
	catch_list.add_child(history_title)

	# Crear items para cada captura
	for catch_data in recent_catches:
		var catch_item = catch_item_scene.instantiate()
		catch_list.add_child(catch_item)

		# Configurar el item con los datos de la captura
		if catch_item.has_method("setup_catch_data"):
			catch_item.setup_catch_data(catch_data)

func _add_stats_panel() -> void:
	"""Añadir panel de estadísticas"""
	if not StatsTracker:
		return
	
	var stats = StatsTracker.get_formatted_stats()
	
	# Panel contenedor
	var stats_panel = PanelContainer.new()
	stats_panel.add_theme_color_override("background_color", Color(0.2, 0.2, 0.2, 0.8))
	catch_list.add_child(stats_panel)
	
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	stats_panel.add_child(stats_vbox)
	
	# Título
	var title = Label.new()
	title.text = "ESTADÍSTICAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	stats_vbox.add_child(title)
	
	# Estadísticas en grid
	var grid = GridContainer.new()
	grid.columns = 2
	stats_vbox.add_child(grid)
	
	# Datos de hoy
	_add_stat_row(grid, "Hoy:", "%d peces, %d monedas" % [stats.today.fish_caught, stats.today.value_earned])
	_add_stat_row(grid, "Racha:", str(stats.today.current_streak))
	_add_stat_row(grid, "Éxito:", stats.today.success_rate)
	_add_stat_row(grid, "Total:", "%d peces" % stats.total.fish_caught)

func _add_stat_row(grid: GridContainer, label: String, value: String) -> void:
	"""Añadir fila de estadística"""
	var label_node = Label.new()
	label_node.text = label
	label_node.add_theme_font_size_override("font_size", 12)
	grid.add_child(label_node)
	
	var value_node = Label.new()
	value_node.text = value
	value_node.add_theme_font_size_override("font_size", 12)
	value_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(value_node)

func _on_close_requested() -> void:
	"""Manejar cierre de ventana"""
	# Limpiar input capturado
	set_process_input(false)
	set_process_unhandled_input(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	window_closed.emit()
	queue_free()

# Función de utilidad para formatear timestamp
static func format_catch_time(timestamp: Dictionary) -> String:
	"""Formatear timestamp para mostrar en UI"""
	if timestamp.has("hour") and timestamp.has("minute"):
		return "%02d:%02d" % [timestamp.hour, timestamp.minute]
	return "??:??"

# Función de utilidad para formatear valor
static func format_fish_value(value: int) -> String:
	"""Formatear valor del pez"""
	return "%d 💰" % value
