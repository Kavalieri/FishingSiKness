extends Control
class_name PauseMenu
## Menú principal de pausa
##
## Ventana emergente translúcida que se muestra sobre el juego
## siguiendo la arquitectura UI-BG-GLOBAL establecida

signal menu_closed()
signal options_requested()
signal save_requested()

# Referencias a nodos UI
@onready var overlay: ColorRect = $Overlay
@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer
@onready var resume_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/ResumeButton
@onready var options_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/OptionsButton
@onready var save_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/SaveButton
@onready var exit_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/ExitButton

# Tweens para animaciones
var fade_tween: Tween
var scale_tween: Tween

func _ready() -> void:
	print("[PauseMenu] Inicializando menú de pausa...")

	# Configurar estilos translúcidos
	_setup_translucent_style()

	# Conectar señales de botones
	_connect_button_signals()

	# Configurar tooltips
	_setup_tooltips()

	# Configurar overlay para recibir input
	_setup_overlay_input()

	# Mostrar con animación
	_animate_show()

	print("[PauseMenu] ✓ Menú de pausa listo")

func _setup_overlay_input() -> void:
	"""Configurar el overlay para manejar input"""
	print("[PauseMenu] Configurando overlay input...")

	# Hacer que el overlay sea clickeable
	overlay.gui_input.connect(_on_overlay_input)

	# Configurar mouse filter para que pueda recibir input
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS

	# NO usar z-index negativo - eso puede causar problemas de input
	# El overlay debe estar en el mismo nivel que el panel
	overlay.z_index = 0
	panel_container.z_index = 1 # Panel al frente para que los botones funcionen

	# CRÍTICO: Hacer que el CenterContainer no bloquee el input del overlay
	var center_container = $CenterContainer
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	print("[PauseMenu] Overlay configurado - mouse_filter: %s" % overlay.mouse_filter)

func _setup_translucent_style() -> void:
	"""Configurar estilo translúcido siguiendo UI-BG-GLOBAL"""
	# Configurar overlay para recibir input
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS

	# El overlay ya tiene color semitransparente en el .tscn

	# Aplicar estilo translúcido al panel principal
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.8) # Fondo oscuro translúcido
	style_box.corner_radius_top_left = 12
	style_box.corner_radius_top_right = 12
	style_box.corner_radius_bottom_left = 12
	style_box.corner_radius_bottom_right = 12
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.3, 0.3, 0.3, 0.6)

	panel_container.add_theme_stylebox_override("panel", style_box)

func _connect_button_signals() -> void:
	"""Conectar señales de los botones"""
	resume_button.pressed.connect(_on_resume_pressed)
	options_button.pressed.connect(_on_options_pressed)
	save_button.pressed.connect(_on_save_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _setup_tooltips() -> void:
	"""Configurar tooltips de botones"""
	resume_button.tooltip_text = "Continuar el juego (ESC)"
	options_button.tooltip_text = "Configurar audio, gráficos y controles"
	save_button.tooltip_text = "Guardar progreso o cargar partida"
	exit_button.tooltip_text = "Guardar y salir al escritorio"

func _animate_show() -> void:
	"""Animar entrada del menú"""
	# Empezar invisible
	modulate.a = 0.0
	panel_container.scale = Vector2(0.8, 0.8)

	# Fade in del overlay
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.3)

	# Scale up del panel
	scale_tween = create_tween()
	scale_tween.tween_property(panel_container, "scale", Vector2(1.0, 1.0), 0.3)
	scale_tween.tween_property(panel_container, "scale", Vector2(1.05, 1.05), 0.1)
	scale_tween.tween_property(panel_container, "scale", Vector2(1.0, 1.0), 0.1)

func close_animated() -> void:
	"""Cerrar con animación"""
	print("[PauseMenu] Cerrando con animación...")

	# Animar salida
	if fade_tween:
		fade_tween.kill()
	if scale_tween:
		scale_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.2)

	scale_tween = create_tween()
	scale_tween.tween_property(panel_container, "scale", Vector2(0.8, 0.8), 0.2)

	# Eliminar cuando termine la animación
	fade_tween.tween_callback(queue_free)

# Handlers de botones
func _on_resume_pressed() -> void:
	"""Continuar el juego"""
	print("[PauseMenu] Continuar presionado")
	menu_closed.emit()

func _on_options_pressed() -> void:
	"""Abrir ventana de opciones"""
	print("[PauseMenu] Opciones presionado")
	options_requested.emit()
	# No cerrar el menú principal, mantenerlo abierto

func _on_save_pressed() -> void:
	"""Abrir ventana de guardado"""
	print("[PauseMenu] Guardar/Cargar presionado")
	save_requested.emit()

func _on_exit_pressed() -> void:
	"""Guardar y salir al escritorio"""
	print("[PauseMenu] Guardar y salir al escritorio")
	_confirm_exit()

func _on_overlay_input(event: InputEvent) -> void:
	"""Cerrar al hacer clic en el overlay"""
	print("[PauseMenu] Overlay input recibido: %s" % event)
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("[PauseMenu] Clic en overlay - cerrando menú")
			menu_closed.emit()

func _confirm_exit() -> void:
	"""Confirmar salida al escritorio"""
	# TODO: Mostrar diálogo de confirmación
	# Por ahora simplemente salir
	print("[PauseMenu] Confirmando salida al escritorio...")

	# Auto-guardar en el slot actual antes de salir del juego
	if Save and Save.has_valid_game_data():
		print("💾 Auto-guardando partida en slot %d antes de salir..." % Save.current_save_slot)
		Save.save_to_slot(Save.current_save_slot)
		Save.save_last_used_slot()
		print("✅ Partida guardada automáticamente en slot %d" % Save.current_save_slot)
	else:
		print("⚠️ No hay datos válidos para guardar")

	# Salir al escritorio
	get_tree().quit()

func _input(event: InputEvent) -> void:
	"""Manejar input local del menú de pausa"""
	# Solo procesar ESC si este menú está visible y activo
	if visible and event.is_action_pressed("ui_cancel"):
		print("[PauseMenu] ESC detectado - cerrando menú")
		menu_closed.emit()
		get_viewport().set_input_as_handled()
