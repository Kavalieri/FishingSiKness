extends Node
## FloatingWindowManager - Gestor centralizado de ventanas flotantes
##
## Responsabilidades:
## - Gestionar stack de ventanas (z-index, modal, etc.)
## - Transiciones de entrada/salida
## - Cierre automático con ESC
## - Evitar conflictos entre ventanas

signal window_opened(window: Control)
signal window_closed(window: Control)
signal all_windows_closed()

enum WindowType {
	MODAL, # Ventana modal que bloquea interacción
	CARD, # Tarjeta de información (no modal)
	MENU, # Menu flotante (modal)
	OPTIONS, # Ventana de opciones (modal)
	INVENTORY # Ventana de inventario (modal)
}

# Stack de ventanas abiertas (la última es la que está encima)
var window_stack: Array[Control] = []

# Referencias a ventanas activas por tipo
var active_windows: Dictionary = {}

# Configuración de tipos de ventana
var window_configs = {
	WindowType.MODAL: {
		"background_dim": true,
		"close_on_escape": true,
		"modal": true,
		"animation": "fade_scale"
	},
	WindowType.CARD: {
		"background_dim": false,
		"close_on_escape": false,
		"modal": false,
		"animation": "slide_up",
		"corner": "top_right",
		"offset_x": 20,
		"offset_y": 20,
		"min_width": 250,
		"min_height": 150
	},
	WindowType.MENU: {
		"background_dim": true,
		"close_on_escape": true,
		"modal": true,
		"animation": "fade_scale"
	},
	WindowType.OPTIONS: {
		"background_dim": true,
		"close_on_escape": true,
		"modal": true,
		"animation": "fade_scale"
	},
	WindowType.INVENTORY: {
		"background_dim": true,
		"close_on_escape": true,
		"modal": true,
		"animation": "slide_from_right"
	}
}

func _ready():
	print("🪟 FloatingWindowManager inicializado")

func _input(event):
	"""Manejar teclas globales para ventanas flotantes"""
	if event.is_action_pressed("ui_cancel") and not window_stack.is_empty():
		var top_window = window_stack.back()
		if top_window and top_window.has_method("get_window_type"):
			var window_type = top_window.get_window_type()
			var config = window_configs.get(window_type, {})

			if config.get("close_on_escape", false):
				close_window(top_window)
				get_viewport().set_input_as_handled()

func open_window(window: Control, window_type: WindowType = WindowType.MODAL) -> bool:
	"""Abrir una ventana flotante"""
	if not window or not is_instance_valid(window):
		print("⚠️ FloatingWindowManager: Ventana inválida")
		return false

	# Verificar si ya existe una ventana de este tipo
	if active_windows.has(window_type):
		print("⚠️ FloatingWindowManager: Ya existe una ventana de tipo %s" % WindowType.keys()[window_type])
		return false

	# Obtener configuración del tipo de ventana
	var config = window_configs.get(window_type, {})

	# Configurar propiedades de la ventana
	setup_window_properties(window, config)

	# Añadir al stack y referencias
	window_stack.push_back(window)
	active_windows[window_type] = window

	# Añadir al árbol de escena
	var root = get_tree().root
	root.add_child(window)

	# Configurar z-index
	window.z_index = 1000 + window_stack.size()

	# Animar entrada
	animate_window_in(window, config)

	# Emitir señal
	window_opened.emit(window)

	print("✅ FloatingWindowManager: Ventana abierta (%s)" % WindowType.keys()[window_type])
	return true

func close_window(window: Control) -> bool:
	"""Cerrar una ventana flotante específica"""
	if not window or not is_instance_valid(window):
		print("⚠️ FloatingWindowManager: Ventana inválida para cerrar")
		return false

	# Buscar y remover del stack
	var index = window_stack.find(window)
	if index == -1:
		print("⚠️ FloatingWindowManager: Ventana no encontrada en stack")
		return false

	window_stack.remove_at(index)

	# Remover de ventanas activas
	for window_type in active_windows.keys():
		if active_windows[window_type] == window:
			active_windows.erase(window_type)
			break

	# Animar salida y luego remover
	animate_window_out(window, func(): _remove_window_from_tree(window))

	# Emitir señal
	window_closed.emit(window)

	if window_stack.is_empty():
		all_windows_closed.emit()

	print("✅ FloatingWindowManager: Ventana cerrada")
	return true

func close_all_windows():
	"""Cerrar todas las ventanas flotantes"""
	var windows_to_close = window_stack.duplicate()
	for window in windows_to_close:
		close_window(window)

func get_top_window() -> Control:
	"""Obtener la ventana que está encima del stack"""
	if window_stack.is_empty():
		return null
	return window_stack.back()

func is_window_type_open(window_type: WindowType) -> bool:
	"""Verificar si hay una ventana de cierto tipo abierta"""
	return active_windows.has(window_type)

func setup_window_properties(window: Control, config: Dictionary):
	"""Configurar propiedades básicas de la ventana"""
	# Hacer que ocupe toda la pantalla
	window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Configurar como modal si es necesario
	if config.get("modal", false):
		window.mouse_filter = Control.MOUSE_FILTER_STOP

		# Crear fondo semi-transparente si es necesario
		if config.get("background_dim", false):
			create_dim_background(window)

func create_dim_background(window: Control):
	"""Crear fondo semi-transparente para ventanas modales"""
	var dim_bg = ColorRect.new()
	dim_bg.name = "DimBackground"
	dim_bg.color = Color(0, 0, 0, 0.5) # Negro semi-transparente
	dim_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim_bg.z_index = -1
	dim_bg.mouse_filter = Control.MOUSE_FILTER_STOP

	# Permitir cerrar haciendo clic en el fondo
	dim_bg.gui_input.connect(_on_dim_background_clicked.bind(window))

	window.add_child(dim_bg)

func _on_dim_background_clicked(event: InputEvent, window: Control):
	"""Cerrar ventana al hacer clic en el fondo"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_window(window)

func animate_window_in(window: Control, config: Dictionary):
	"""Animar entrada de ventana"""
	var animation_type = config.get("animation", "fade_scale")

	match animation_type:
		"fade_scale":
			window.modulate.a = 0.0
			window.scale = Vector2(0.8, 0.8)

			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(window, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
			tween.tween_property(window, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		"slide_up":
			window.position.y += 100
			window.modulate.a = 0.8

			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(window, "position:y", window.position.y - 100, 0.25).set_ease(Tween.EASE_OUT)
			tween.tween_property(window, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)

		"slide_from_right":
			window.position.x += 300

			var tween = create_tween()
			tween.tween_property(window, "position:x", window.position.x - 300, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)

func animate_window_out(window: Control, callback: Callable):
	"""Animar salida de ventana"""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(window, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(window, "scale", Vector2(0.8, 0.8), 0.2).set_ease(Tween.EASE_IN)

	tween.tween_callback(callback).set_delay(0.2)

func _remove_window_from_tree(window: Control):
	"""Remover ventana del árbol de escena"""
	if window and is_instance_valid(window):
		window.queue_free()

func get_window_config(window_type: WindowType) -> Dictionary:
	"""Obtener configuración para un tipo de ventana específico"""
	return window_configs.get(window_type, {})
