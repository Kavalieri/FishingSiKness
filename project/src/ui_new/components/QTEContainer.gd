class_name QTEContainer
extends Control

# Contenedor cuadrado especializado para Quick Time Events

signal qte_success
signal qte_failed
signal qte_timeout

enum QTEType {
	PRESS_BUTTON,
	HOLD_BUTTON,
	RAPID_PRESS,
	SEQUENCE_PRESS,
	TIMING_PRESS
}

var qte_type: QTEType = QTEType.PRESS_BUTTON
var qte_duration: float = 3.0
var success_window: float = 0.5
var is_active: bool = false
var timer: float = 0.0
var required_presses: int = 1
var current_presses: int = 0

@onready var qte_icon: TextureRect = $AspectRatioContainer/QTEPanel/MarginContainer / \
	VBoxContainer / QTEIcon
@onready var qte_text: Label = $AspectRatioContainer/QTEPanel/MarginContainer / \
	VBoxContainer / QTEText
@onready var qte_progress: ProgressBar = $AspectRatioContainer/QTEPanel/MarginContainer / \
	VBoxContainer / QTEProgress

func _ready() -> void:
	visible = false
	_setup_initial_state()

func _process(delta: float) -> void:
	if not is_active:
		return

	timer += delta
	_update_progress()

	# Verificar timeout
	if timer >= qte_duration:
		_end_qte(false)

func _input(event: InputEvent) -> void:
	if not is_active:
		return

	match qte_type:
		QTEType.PRESS_BUTTON:
			_handle_press_button(event)
		QTEType.HOLD_BUTTON:
			_handle_hold_button(event)
		QTEType.RAPID_PRESS:
			_handle_rapid_press(event)

func _setup_initial_state() -> void:
	"""Configurar estado inicial del QTE"""
	timer = 0.0
	current_presses = 0
	qte_progress.value = 0.0

func start_qte(type: QTEType, duration: float = 3.0, presses: int = 1,
	icon: Texture2D = null, text: String = "") -> void:
	"""Iniciar Quick Time Event"""
	qte_type = type
	qte_duration = duration
	required_presses = presses

	# Configurar UI
	if icon:
		qte_icon.texture = icon
		qte_icon.visible = true
		qte_icon.custom_minimum_size = Vector2(80, 80) # Tamaño mínimo para mejor visibilidad
	else:
		qte_icon.visible = false

	if text != "":
		qte_text.text = text
	else:
		qte_text.text = _get_default_text(type)

	# Activar QTE
	_setup_initial_state()
	is_active = true
	visible = true

	# Animación de entrada
	_animate_entrance()

func _get_default_text(type: QTEType) -> String:
	"""Obtener texto por defecto según tipo de QTE"""
	match type:
		QTEType.PRESS_BUTTON:
			return "¡Presiona!"
		QTEType.HOLD_BUTTON:
			return "¡Mantén presionado!"
		QTEType.RAPID_PRESS:
			return "¡Presiona rápido! (%d)" % required_presses
		QTEType.SEQUENCE_PRESS:
			return "¡Secuencia!"
		QTEType.TIMING_PRESS:
			return "¡Momento perfecto!"
		_:
			return "¡Acción!"

func _update_progress() -> void:
	"""Actualizar barra de progreso"""
	var progress = timer / qte_duration
	qte_progress.value = progress

func _handle_press_button(event: InputEvent) -> void:
	"""Manejar QTE de presionar botón"""
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("click"):
		if _is_in_success_window():
			_end_qte(true)
		else:
			_end_qte(false)

func _handle_hold_button(event: InputEvent) -> void:
	"""Manejar QTE de mantener presionado"""
	if event.is_action_released("ui_accept") or event.is_action_released("click"):
		if timer >= (qte_duration - success_window):
			_end_qte(true)
		else:
			_end_qte(false)

func _handle_rapid_press(event: InputEvent) -> void:
	"""Manejar QTE de presionar rápidamente"""
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("click"):
		current_presses += 1
		qte_text.text = "¡Presiona rápido! (%d/%d)" % [current_presses, required_presses]

		if current_presses >= required_presses:
			_end_qte(true)

func _is_in_success_window() -> bool:
	"""Verificar si estamos en la ventana de éxito"""
	var target_time = qte_duration * 0.7 # 70% del tiempo
	return abs(timer - target_time) <= success_window

func _end_qte(success: bool) -> void:
	"""Finalizar QTE"""
	is_active = false

	# Animación de salida
	_animate_exit(success)

	# Emitir señal apropiada
	if success:
		qte_success.emit()
	else:
		qte_failed.emit()

func _animate_entrance() -> void:
	"""Animar entrada del QTE"""
	scale = Vector2(0.5, 0.5)
	modulate.a = 0.0

	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.3)

func _animate_exit(success: bool) -> void:
	"""Animar salida del QTE"""
	var tween = create_tween()

	if success:
		# Animación de éxito - pulso verde
		modulate = Color.GREEN
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
		tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	else:
		# Animación de fallo - shake rojo
		modulate = Color.RED
		tween.tween_property(self, "position:x", position.x + 10, 0.1)
		tween.tween_property(self, "position:x", position.x - 10, 0.1)
		tween.tween_property(self, "position:x", position.x, 0.1)

	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): visible = false)

func force_end() -> void:
	"""Forzar fin del QTE (para casos especiales)"""
	if is_active:
		is_active = false
		qte_timeout.emit()
		visible = false
