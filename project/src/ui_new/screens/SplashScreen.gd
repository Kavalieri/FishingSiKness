class_name SplashScreen
extends Control

# Pantalla de splash según especificación

signal splash_finished

var loading_progress: float = 0.0
var is_loading: bool = true
var can_skip: bool = false

# Lista de consejos para mostrar aleatoriamente
var tips: Array[String] = [
	"Los peces más raros aparecen en zonas más profundas",
	"Mejora tu caña para pescar peces más grandes",
	"Algunas zonas solo están disponibles por la noche",
	"Los anzuelos especiales atraen tipos específicos de peces",
	"Completa misiones para obtener recompensas exclusivas"
]

@onready var loading_bar: ProgressBar = $CenterContainer/VBoxContainer/LoadingContainer/LoadingBar
@onready var loading_label: Label = $CenterContainer/VBoxContainer/LoadingContainer/LoadingLabel
@onready var tip_text: Label = $CenterContainer/VBoxContainer/TipContainer/TipText
@onready var tap_to_continue: Label = $TapToContinue
@onready var version_label: Label = $VersionLabel
@onready var pause_button: Button = $TopBarZone/PauseButton

func _ready() -> void:
	_setup_initial_state()
	_show_random_tip()
	_connect_pause_button()
	_start_loading()

func _connect_pause_button() -> void:
	"""Conectar botón de pausa con PauseManager"""
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)

func _on_pause_button_pressed() -> void:
	"""Manejar botón de pausa desde splash screen"""
	print("[SplashScreen] Botón pausa presionado")

	if PauseManager:
		PauseManager.request_pause_menu()
	else:
		print("[SplashScreen] PauseManager no disponible")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and can_skip:
		_complete_splash()

func _setup_initial_state() -> void:
	loading_bar.value = 0.0
	tap_to_continue.visible = false
	_set_version_label()

func _set_version_label() -> void:
	"""Establecer etiqueta de versión"""
	# TODO: Obtener versión desde project settings o autoload
	version_label.text = "v0.1.0-alpha"

func _show_random_tip() -> void:
	"""Mostrar consejo aleatorio"""
	if tips.size() > 0:
		tip_text.text = tips[randi() % tips.size()]

func _start_loading() -> void:
	"""Iniciar proceso de carga simulado"""
	var tween = create_tween()
	tween.tween_method(_update_loading_progress, 0.0, 100.0, 3.0)
	tween.tween_callback(_on_loading_complete)

func _update_loading_progress(progress: float) -> void:
	"""Actualizar progreso de carga"""
	loading_progress = progress
	loading_bar.value = progress

	# Actualizar texto según progreso
	if progress < 30.0:
		loading_label.text = "Inicializando..."
	elif progress < 60.0:
		loading_label.text = "Cargando datos..."
	elif progress < 90.0:
		loading_label.text = "Preparando interfaz..."
	else:
		loading_label.text = "Finalizando..."

func _on_loading_complete() -> void:
	"""Completar proceso de carga"""
	is_loading = false
	can_skip = true
	loading_label.text = "¡Listo!"

	# Mostrar indicador para continuar
	tap_to_continue.visible = true
	_animate_tap_indicator()

func _animate_tap_indicator() -> void:
	"""Animar indicador de toque"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(tap_to_continue, "modulate:a", 0.5, 1.0)
	tween.tween_property(tap_to_continue, "modulate:a", 1.0, 1.0)

func _complete_splash() -> void:
	"""Completar splash screen y cambiar a main"""
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_change_to_main_scene)

func _change_to_main_scene() -> void:
	"""Cambiar a la escena principal"""
	splash_finished.emit()
	get_tree().change_scene_to_file("res://scenes/ui_new/Main.tscn")
