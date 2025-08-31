class_name FishingScreen
extends Control

# Pantalla principal de pesca según especificación

signal fishing_cast_requested
signal auto_cast_toggled(enabled: bool)
signal stats_requested
signal fish_caught(fish_data: Dictionary)

var current_zone: Dictionary = {}
var is_auto_casting: bool = false
var fishing_stats: Dictionary = {}
var is_fishing: bool = false

@onready var background: TextureRect = $Background
@onready var cast_button: Button = $VBoxContainer/MarginContainer/ContentVBox/FishingArea/CastButton
@onready var auto_cast_button: Button = $VBoxContainer/MarginContainer/ContentVBox/BottomButtonsContainer/BottomPanel/AutoCastButton
@onready var stats_button: Button = $VBoxContainer/MarginContainer/ContentVBox/BottomButtonsContainer/BottomPanel/StatsButton
@onready var qte_container = $QTEContainer

# Instancia de la ventana de captura
var capture_window: Control = null
var stats_window: AcceptDialog = null

func _ready() -> void:
	_connect_signals()
	_sync_with_fishing_manager()
	_setup_capture_window()

func _connect_signals() -> void:
	cast_button.pressed.connect(_on_cast_button_pressed)
	auto_cast_button.pressed.connect(_on_auto_cast_toggled)
	stats_button.pressed.connect(_on_stats_button_pressed)

	# Conectar señales del QTE Container (solo si existe y tiene los métodos)
	if qte_container and qte_container.has_signal("qte_success"):
		qte_container.qte_success.connect(_on_qte_success)
		qte_container.qte_failed.connect(_on_qte_failed)
		qte_container.qte_timeout.connect(_on_qte_timeout)
	else:
		print("⚠️ QTEContainer no disponible o sin señales correctas")

func _sync_with_fishing_manager() -> void:
	"""Sincronizar con sistemas de pesca"""
	# Conectar con Content para obtener datos de peces
	if Content:
		print("Content system disponible para datos de peces")

func _setup_capture_window() -> void:
	"""Configurar la ventana de captura"""
	var capture_scene = load("res://scenes/ui_new/components/CaptureWindow.tscn")
	if capture_scene:
		capture_window = capture_scene.instantiate()
		add_child(capture_window)
		capture_window.visible = false

		# Conectar señales de la ventana de captura
		capture_window.fish_kept.connect(_on_fish_kept)
		capture_window.fish_sold.connect(_on_fish_sold)
		capture_window.fish_released.connect(_on_fish_released)
		capture_window.window_closed.connect(_on_capture_window_closed)
	else:
		print("⚠️ No se pudo cargar CaptureWindow.tscn")

	# Configurar ventana de estadísticas
	var stats_scene = load("res://scenes/ui_new/components/CatchStatsWindow.tscn")
	if stats_scene:
		stats_window = stats_scene.instantiate()
		add_child(stats_window)
		stats_window.window_closed.connect(_on_stats_window_closed)
		print("✅ Ventana de estadísticas configurada")
	else:
		print("⚠️ No se pudo cargar CatchStatsWindow.tscn")

	# Conectar con SFX para sonidos
	if SFX:
		print("SFX system disponible para efectos de sonido")

	# TODO: Integrar con FishingSystem cuando esté disponible como autoload

func setup_fishing_screen(zone_def, stats: Dictionary) -> void:
	"""Configurar pantalla de pesca con zona y estadísticas"""
	# Convertir ZoneDef a Dictionary interno para compatibilidad con código existente
	current_zone = {}
	if zone_def:
		current_zone = {
			"id": zone_def.id,
			"name": zone_def.name,
			"price_multiplier": zone_def.price_multiplier,
			"background_path": zone_def.background
		}

	fishing_stats = stats

	_update_zone_background()
	_update_fishing_display()

func _update_zone_background() -> void:
	"""Actualizar fondo según la zona actual (compatible con fondo único global)"""
	# En la nueva arquitectura, el fondo se maneja globalmente en Main.tscn
	# Esta función puede comunicarse con Main para cambiar el fondo
	var zone_background = current_zone.get("background_path", "")
	if zone_background != "":
		# TODO: Comunicar con Main para cambio de fondo
		# Main.set_background(zone_background)
		pass

func _update_fishing_display() -> void:
	"""Actualizar elementos de visualización de pesca"""
	# Actualizar texto del botón según estado
	set_casting_state(is_fishing)

func show_caught_fish(fish_data: Dictionary) -> void:
	"""Mostrar pez capturado (ahora se maneja en QTE y ventana de captura)"""
	# La visualización del pez se maneja ahora en el QTE y la ventana de captura
	# Esta función se mantiene para compatibilidad pero ya no necesita hacer animaciones redundantes
	print("🐟 [UI] Pez capturado: %s" % fish_data.get("name", "desconocido"))

func set_casting_state(is_casting: bool) -> void:
	"""Establecer estado de lanzamiento"""
	cast_button.disabled = is_casting
	if is_casting:
		cast_button.text = "Lanzando..."
	else:
		cast_button.text = "Lanzar Caña"

func update_auto_cast_state(enabled: bool) -> void:
	"""Actualizar estado del auto-cast"""
	is_auto_casting = enabled
	if enabled:
		auto_cast_button.text = "Auto Pesca: ON"
		auto_cast_button.modulate = Color.LIGHT_GREEN
	else:
		auto_cast_button.text = "Auto Pesca: OFF"
		auto_cast_button.modulate = Color.WHITE

func _on_cast_button_pressed() -> void:
	"""Manejar lanzamiento manual"""
	if not is_fishing:
		_start_fishing()
	else:
		fishing_cast_requested.emit()

func _start_fishing() -> void:
	"""Iniciar proceso de pesca con QTE"""
	if is_fishing:
		return

	is_fishing = true
	set_casting_state(true)

	# Simular tiempo de lanzamiento
	await get_tree().create_timer(1.5).timeout

	# Iniciar QTE
	_start_qte_event()

func _start_qte_event() -> void:
	"""Iniciar evento QTE de pesca"""
	var qte_duration = randf_range(2.0, 4.0)
	var qte_type = QTEContainer.QTEType.PRESS_BUTTON

	# Variar tipo de QTE según dificultad
	var rand_type = randi() % 3
	match rand_type:
		0: qte_type = QTEContainer.QTEType.PRESS_BUTTON
		1: qte_type = QTEContainer.QTEType.HOLD_BUTTON
		2: qte_type = QTEContainer.QTEType.RAPID_PRESS

	# Pre-generar datos de pez para mostrar icono correcto
	var preview_fish = _generate_caught_fish()
	var fish_icon_texture = preview_fish.get("icon", null)

	print("🎣 [QTE] Iniciando QTE con pez: %s" % preview_fish.get("name", "desconocido"))
	print("🎣 [QTE] Sprite disponible: %s" % (fish_icon_texture != null))
	if fish_icon_texture:
		print("🎣 [QTE] Tamaño sprite: %dx%d" % [fish_icon_texture.get_width(), fish_icon_texture.get_height()])

	# Mensaje dinámico según tipo de QTE
	var qte_message = ""
	match qte_type:
		QTEContainer.QTEType.PRESS_BUTTON:
			qte_message = "¡Presiona cuando veas el pez!"
		QTEContainer.QTEType.HOLD_BUTTON:
			qte_message = "¡Mantén presionado para atrapar!"
		QTEContainer.QTEType.RAPID_PRESS:
			qte_message = "¡Presiona rápido para luchar!"

	# Reproducir sonido de anzuelo
	if SFX and SFX.has_method("play_event"):
		SFX.play_event("qte")

	qte_container.start_qte(
		qte_type,
		qte_duration,
		3 if qte_type == QTEContainer.QTEType.RAPID_PRESS else 1,
		fish_icon_texture,
		qte_message
	)

	# Guardar datos del pez para cuando se complete el QTE
	set_meta("preview_fish", preview_fish)

func _on_qte_success() -> void:
	"""QTE exitoso - mostrar ventana de captura"""
	is_fishing = false
	set_casting_state(false)

	# Usar datos del pez pregenerado
	var caught_fish = get_meta("preview_fish", {})
	if caught_fish.is_empty():
		caught_fish = _generate_caught_fish() # fallback

	# Reproducir sonido de captura
	if SFX and SFX.has_method("play_event"):
		SFX.play_event("capture")

	# Mostrar ventana de captura con opciones
	if capture_window and capture_window.has_method("show_capture"):
		capture_window.show_capture(caught_fish)
	else:
		# Fallback: procesar automáticamente si no hay ventana
		_process_caught_fish(caught_fish)

	# Limpiar metadata
	remove_meta("preview_fish")

func _on_qte_failed() -> void:
	"""QTE fallido - pez escapó"""
	is_fishing = false
	set_casting_state(false)

	# Reproducir sonido de fallo
	if SFX and SFX.has_method("play_event"):
		SFX.play_event("fail")

	# Mostrar mensaje de escape
	_show_escape_message()

	# Limpiar metadata
	remove_meta("preview_fish")

func _on_qte_timeout() -> void:
	"""QTE timeout - sin actividad"""
	is_fishing = false
	set_casting_state(false)

	# Mostrar mensaje de timeout
	_show_timeout_message()

	# Limpiar metadata
	remove_meta("preview_fish")

func _show_escape_message() -> void:
	"""Mostrar mensaje de pez escapado"""
	# TODO: Implementar notificación visual
	print("¡El pez escapó!")

func _show_timeout_message() -> void:
	"""Mostrar mensaje de timeout"""
	# TODO: Implementar notificación visual
	print("No hubo actividad...")

func _generate_caught_fish() -> Dictionary:
	"""Generar datos de pez capturado usando Content system"""
	print("🐟 [Fish Gen] Generando pez...")

	# Si tenemos Content, usar datos reales
	if Content and Content.has_method("get_random_fish_for_zone"):
		var zone_id = current_zone.get("id", "orilla") # zona por defecto
		print("🐟 [Fish Gen] Usando Content para zona: %s" % zone_id)
		var fish_data = Content.get_random_fish_for_zone(zone_id)
		if fish_data:
			print("🐟 [Fish Gen] Pez desde Content: %s" % fish_data.get("name", "sin nombre"))
			print("🐟 [Fish Gen] Icono incluido: %s" % (fish_data.get("icon") != null))
			return fish_data
		else:
			print("🐟 [Fish Gen] Content no devolvió datos")
	else:
		print("🐟 [Fish Gen] Content no disponible, usando fallback")

	# Fallback: sistema básico de rareza
	var fish_names = ["sardina", "trucha", "salmon", "lubina"]
	var rarities = ["común", "rara", "épica", "legendaria"]
	var weights = [70.0, 20.0, 8.0, 2.0]

	# Selección por peso
	var rand = randf() * 100.0
	var accumulated = 0.0
	var selected_rarity = "común"

	for i in range(weights.size()):
		accumulated += weights[i]
		if rand <= accumulated:
			selected_rarity = rarities[i]
			break

	var fish_name = fish_names[randi() % fish_names.size()]
	var base_value = randi_range(10, 100)
	var rarity_multiplier = 1.0

	match selected_rarity:
		"común": rarity_multiplier = 1.0
		"rara": rarity_multiplier = 1.5
		"épica": rarity_multiplier = 2.5
		"legendaria": rarity_multiplier = 5.0

	# Intentar cargar el icono del pez
	var fish_icon = _load_fish_icon(fish_name)
	print("🐟 [Fish Gen] Fallback pez: %s, icono: %s" % [fish_name, fish_icon != null])

	return {
		"name": fish_name,
		"rarity": selected_rarity,
		"value": int(base_value * rarity_multiplier),
		"icon": fish_icon
	}

func _load_fish_icon(fish_name: String) -> Texture2D:
	"""Cargar icono de pez con fallback usando ResourceLoader"""
	var icon_path = "res://art/fish/%s.png" % fish_name

	# Verificar si el archivo existe antes de cargarlo
	if ResourceLoader.exists(icon_path):
		var texture = ResourceLoader.load(icon_path, "Texture2D")
		if texture:
			return texture

	# Fallback al primer pez disponible
	var fallback_path = "res://art/fish/sardina.png"
	if ResourceLoader.exists(fallback_path):
		return ResourceLoader.load(fallback_path, "Texture2D")

	# Si incluso el fallback falla, devolver null
	print("⚠️ No se pudo cargar ningún sprite de pez para: %s" % fish_name)
	return null

func _on_auto_cast_toggled() -> void:
	"""Manejar toggle del auto-cast"""
	is_auto_casting = not is_auto_casting
	update_auto_cast_state(is_auto_casting)
	auto_cast_toggled.emit(is_auto_casting)

func _on_stats_button_pressed() -> void:
	"""Mostrar estadísticas/historial de capturas"""
	if stats_window:
		stats_window.show_catch_stats()
	else:
		print("⚠️ Ventana de estadísticas no disponible")
	stats_requested.emit()

func _on_stats_window_closed() -> void:
	"""Manejar cierre de ventana de estadísticas"""
	# La ventana se auto-limpia con queue_free()
	pass

# OBSOLETO: Botones removidos para simplificar UI
# func _on_boosters_button_pressed() -> void:
#	"""Mostrar potenciadores disponibles"""
#	boosters_requested.emit()

# Funciones para manejar la ventana de captura
func _on_fish_kept(fish_data: Dictionary) -> void:
	"""Pez mantenido en inventario"""
	_process_caught_fish(fish_data)

func _on_fish_sold(fish_data: Dictionary, value: int) -> void:
	"""Pez vendido"""
	if Save and Save.has_method("add_coins"):
		Save.add_coins(value)

	# Mostrar mensaje de venta
	_show_sale_message(fish_data, value)

func _on_fish_released(fish_data: Dictionary) -> void:
	"""Pez liberado"""
	# Mostrar mensaje de liberación
	_show_release_message(fish_data)

func _on_capture_window_closed() -> void:
	"""Ventana de captura cerrada sin acción"""
	pass

func _process_caught_fish(fish_data: Dictionary) -> void:
	"""Procesar pez capturado (añadir al inventario y historial)"""
	if Save and Save.has_method("add_fish"):
		Save.add_fish(fish_data.name, 1)

	# Agregar al historial de capturas
	if Save and Save.has_method("add_catch_to_history"):
		Save.add_catch_to_history(fish_data)

	show_caught_fish(fish_data)
	fish_caught.emit(fish_data)

func _show_sale_message(fish_data: Dictionary, value: int) -> void:
	"""Mostrar mensaje de venta"""
	print("¡%s vendido por %d monedas!" % [fish_data.get("name", "Pez"), value])

func _show_release_message(fish_data: Dictionary) -> void:
	"""Mostrar mensaje de liberación"""
	print("¡%s liberado!" % fish_data.get("name", "Pez"))
