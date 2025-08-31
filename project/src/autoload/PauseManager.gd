extends Node
## Sistema global de menú de pausa
##
## Maneja inputs globales (ESC, botón atrás Android) y coordina
## la apertura del menú de pausa desde cualquier parte del juego
## Siguiendo la arquitectura UI-BG-GLOBAL con ventanas translúcidas

signal pause_menu_requested()
signal pause_menu_opened()
signal pause_menu_closed()

var is_pause_menu_open: bool = false
var current_pause_window: Control = null

# Referencias para obtener el nodo Main actual
var main_node: Control = null

func _ready() -> void:
	print("[PauseManager] Inicializando sistema de pausa...")

	# Configurar inputs globales
	_setup_input_actions()

	# Conectar señales
	pause_menu_requested.connect(_open_pause_menu)

func _setup_input_actions() -> void:
	"""Configurar acciones de input si no existen"""
	if not InputMap.has_action("ui_pause"):
		InputMap.add_action("ui_pause")

		# ESC para Windows/Linux/Mac
		var key_event = InputEventKey.new()
		key_event.keycode = KEY_ESCAPE
		InputMap.action_add_event("ui_pause", key_event)

		print("[PauseManager] ✓ Acción 'ui_pause' creada (ESC)")

func _unhandled_input(event: InputEvent) -> void:
	"""Capturar inputs globales para pausa"""
	# ESC en PC o botón atrás en Android
	if event.is_action_pressed("ui_pause") or event.is_action_pressed("ui_cancel"):
		if not is_pause_menu_open:
			print("[PauseManager] Input de pausa detectado")
			pause_menu_requested.emit()
			get_viewport().set_input_as_handled()
		else:
			# Si ya está abierto, cerrar
			_close_pause_menu()
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	"""Manejar notificaciones del sistema Android"""
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			# Botón atrás en Android
			if not is_pause_menu_open:
				print("[PauseManager] Botón atrás Android - abriendo menú pausa")
				pause_menu_requested.emit()
			else:
				_close_pause_menu()

func request_pause_menu() -> void:
	"""API pública para solicitar menú de pausa"""
	if not is_pause_menu_open:
		pause_menu_requested.emit()

func _open_pause_menu() -> void:
	"""Abrir menú de pausa"""
	if is_pause_menu_open:
		return

	print("[PauseManager] Abriendo menú de pausa...")

	# Encontrar el nodo Main actual
	_find_main_node()

	if not main_node:
		print("[PauseManager] ❌ No se encontró nodo Main para mostrar menú pausa")
		return

	# Cargar escena del menú de pausa
	var pause_scene = load("res://scenes/ui_new/windows/PauseMenu.tscn")
	if not pause_scene:
		print("[PauseManager] ❌ No se pudo cargar PauseMenu.tscn")
		return

	# Instanciar y mostrar
	var pause_window = pause_scene.instantiate()
	main_node.add_child(pause_window)

	# Conectar señales del menú
	if pause_window.has_signal("menu_closed"):
		pause_window.menu_closed.connect(_on_pause_menu_closed)
	if pause_window.has_signal("options_requested"):
		pause_window.options_requested.connect(_show_options_window)
	if pause_window.has_signal("save_requested"):
		pause_window.save_requested.connect(_show_save_window)

	# Configurar estado
	current_pause_window = pause_window
	is_pause_menu_open = true
	pause_menu_opened.emit()

	print("[PauseManager] ✓ Menú de pausa abierto")

func _close_pause_menu() -> void:
	"""Cerrar menú de pausa"""
	if not is_pause_menu_open or not current_pause_window:
		return

	print("[PauseManager] Cerrando menú de pausa...")

	# Animar cierre si el menú lo soporta
	if current_pause_window.has_method("close_animated"):
		current_pause_window.close_animated()
	else:
		current_pause_window.queue_free()

	# Resetear estado
	current_pause_window = null
	is_pause_menu_open = false
	pause_menu_closed.emit()

	print("[PauseManager] ✓ Menú de pausa cerrado")

func _find_main_node() -> void:
	"""Encontrar el nodo Main en el árbol de escenas"""
	var scene_tree = get_tree()
	if not scene_tree:
		return

	var root = scene_tree.current_scene
	if not root:
		return

	# Buscar por nombre de clase o nombre de nodo
	if root.get_class() == "MainUI" or root.name == "Main":
		main_node = root
		return

	# Buscar en hijos
	for child in root.get_children():
		if child.get_class() == "MainUI" or child.name == "Main":
			main_node = child
			return

func _on_pause_menu_closed() -> void:
	"""Handler cuando el menú de pausa se cierra desde sí mismo"""
	_close_pause_menu()

func _show_options_window() -> void:
	"""Mostrar ventana de opciones"""
	if not main_node:
		return

	var options_scene = load("res://scenes/ui_new/windows/OptionsWindow.tscn")
	if options_scene:
		var options_window = options_scene.instantiate()
		main_node.add_child(options_window)

		if options_window.has_signal("window_closed"):
			options_window.window_closed.connect(func(): print("[PauseManager] Ventana opciones cerrada"))

func _show_save_window() -> void:
	"""Mostrar ventana de guardado"""
	if not main_node:
		return

	var save_scene = load("res://scenes/ui_new/windows/SaveWindow.tscn")
	if save_scene:
		var save_window = save_scene.instantiate()
		main_node.add_child(save_window)

		if save_window.has_signal("window_closed"):
			save_window.window_closed.connect(func(): print("[PauseManager] Ventana guardado cerrada"))

# API pública para integración con TopBar/SplashScreen
func is_menu_open() -> bool:
	"""Verificar si el menú está abierto"""
	return is_pause_menu_open

func close_menu() -> void:
	"""Cerrar menú desde código externo"""
	_close_pause_menu()
