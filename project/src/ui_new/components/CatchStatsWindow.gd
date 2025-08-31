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
	_load_recent_catches()
	_populate_catch_list()
	popup_centered()

func _load_recent_catches() -> void:
	"""Cargar capturas recientes desde el sistema de guardado"""
	recent_catches.clear()

	if not Save:
		print("⚠️ [CatchStats] Save system no disponible")
		return

	# Obtener historial de capturas del sistema Save
	var catch_history = Save.get_catch_history(20) # Últimas 20 capturas
	if catch_history and catch_history.size() > 0:
		recent_catches = catch_history
		print("📊 [CatchStats] Cargadas %d capturas" % recent_catches.size())
	else:
		print("📊 [CatchStats] No hay capturas disponibles")

func _populate_catch_list() -> void:
	"""Poblar la lista con las capturas"""
	# Limpiar lista actual (excepto el estado vacío)
	for child in catch_list.get_children():
		if child != empty_state_panel:
			child.queue_free()

	# Si no hay capturas, mostrar estado vacío
	if recent_catches.is_empty():
		empty_state_panel.visible = true
		return

	# Ocultar estado vacío y mostrar capturas
	empty_state_panel.visible = false

	# Crear items para cada captura
	for catch_data in recent_catches:
		var catch_item = catch_item_scene.instantiate()
		catch_list.add_child(catch_item)

		# Configurar el item con los datos de la captura
		if catch_item.has_method("setup_catch_data"):
			catch_item.setup_catch_data(catch_data)

func _on_close_requested() -> void:
	"""Manejar cierre de ventana"""
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
