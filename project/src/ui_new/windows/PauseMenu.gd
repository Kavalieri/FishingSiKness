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

	# Mostrar con animación
	_animate_show()

	print("[PauseMenu] ✓ Menú de pausa listo")

func _setup_translucent_style() -> void:
	"""Configurar estilo translúcido siguiendo UI-BG-GLOBAL"""
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

	# Permitir cerrar haciendo clic en el overlay
	overlay.gui_input.connect(_on_overlay_input)

func _setup_tooltips() -> void:
	"""Configurar tooltips de botones"""
	resume_button.tooltip_text = "Continuar el juego (ESC)"
	options_button.tooltip_text = "Configurar audio, gráficos y controles"
	save_button.tooltip_text = "Guardar progreso o cargar partida"
	exit_button.tooltip_text = "Volver al menú principal"

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
	"""Salir al menú principal"""
	print("[PauseMenu] Salir al menú principal")
	_confirm_exit()

func _on_overlay_input(event: InputEvent) -> void:
	"""Cerrar al hacer clic en el overlay"""
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("[PauseMenu] Clic en overlay - cerrando menú")
			menu_closed.emit()

func _confirm_exit() -> void:
	"""Confirmar salida al menú principal"""
	# TODO: Mostrar diálogo de confirmación
	# Por ahora simplemente salir
	print("[PauseMenu] Confirmando salida...")

	if Save:
		Save.save_game() # Guardar automáticamente

	# Cambiar a escena del menú principal
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# Input handling
func _unhandled_input(event: InputEvent) -> void:
	"""Manejar inputs mientras el menú está abierto"""
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause"):
		print("[PauseMenu] ESC presionado - cerrando menú")
		menu_closed.emit()
		get_viewport().set_input_as_handled()
