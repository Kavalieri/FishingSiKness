class_name QTEContainer
extends Control

# Contenedor cuadrado especializado para Quick Time Events

signal qte_success
signal qte_failed
signal qte_timeout
signal fish_kept
signal fish_released

# QTE clásico de pesca con barra en movimiento
var qte_duration: float = 8.0
var is_active: bool = false
var timer: float = 0.0
var needle_position: float = 0.0
var needle_speed: float = 0.6  # Más lento
var needle_direction: int = 1
var target_start: float = 0.4
var target_end: float = 0.6

@onready var qte_icon: TextureRect = $AspectRatioContainer/QTEPanel/MarginContainer / \
	VBoxContainer / QTEIcon
@onready var qte_text: Label = $AspectRatioContainer/QTEPanel/MarginContainer / \
	VBoxContainer / QTEText
@onready var qte_progress: ProgressBar = $AspectRatioContainer/QTEPanel/MarginContainer / \
	VBoxContainer / QTEProgress

# Elementos para QTE clásico
var needle_rect: ColorRect
var target_zone: ColorRect

# Elementos para ventana de resultado
var result_container: VBoxContainer
var action_buttons: HBoxContainer
var is_showing_result: bool = false

func _ready() -> void:
	visible = false
	_setup_initial_state()

func _process(delta: float) -> void:
	if not is_active:
		return

	timer += delta
	_update_classic_qte(delta)

	# Verificar timeout
	if timer >= qte_duration:
		_end_qte(false)

func _input(event: InputEvent) -> void:
	if not is_active:
		return

	_handle_classic_input(event)

func _setup_initial_state() -> void:
	"""Configurar estado inicial del QTE clásico"""
	timer = 0.0
	needle_position = 0.0
	needle_direction = 1
	qte_progress.value = 1.0
	
	# Generar zona objetivo aleatoria más grande
	var target_width = 0.2  # 20% de ancho para mejor jugabilidad
	var max_start = 1.0 - target_width
	target_start = randf() * max_start
	target_end = target_start + target_width

func start_qte(type = null, duration: float = 8.0, presses: int = 1,
	icon: Texture2D = null, text: String = "") -> void:
	"""Iniciar QTE clásico de pesca con barra en movimiento"""
	is_showing_result = false
	qte_duration = duration

	# Configurar UI
	if icon:
		qte_icon.texture = icon
		qte_icon.visible = true
		qte_icon.custom_minimum_size = Vector2(80, 80)
	else:
		qte_icon.visible = false

	qte_text.text = "¡Presiona cuando la aguja esté en la zona verde!"

	# Configurar barra clásica
	_setup_classic_bar()

	# Activar QTE
	_setup_initial_state()
	is_active = true
	visible = true

	# Animación de entrada
	_animate_entrance()

func _setup_classic_bar() -> void:
	"""Configurar barra clásica de QTE estilo juegos de pesca"""
	# Limpiar elementos existentes
	if needle_rect:
		needle_rect.queue_free()
	if target_zone:
		target_zone.queue_free()
	
	# Hacer la barra más alta y visible
	qte_progress.custom_minimum_size.y = 40
	qte_progress.add_theme_color_override("fill", Color(0.1, 0.1, 0.1))  # Fondo oscuro
	qte_progress.add_theme_color_override("background", Color(0.3, 0.3, 0.3))  # Borde gris
	
	# Crear zona objetivo (verde clásico)
	target_zone = ColorRect.new()
	target_zone.color = Color(0.2, 0.8, 0.2, 0.9)  # Verde clásico
	target_zone.layout_mode = 1
	target_zone.z_index = 1
	qte_progress.add_child(target_zone)
	
	# Crear aguja (amarilla brillante como juegos clásicos)
	needle_rect = ColorRect.new()
	needle_rect.color = Color(1.0, 1.0, 0.0, 1.0)  # Amarillo brillante
	needle_rect.layout_mode = 1
	needle_rect.z_index = 2
	qte_progress.add_child(needle_rect)

func _update_classic_qte(delta: float) -> void:
	"""Actualizar QTE clásico estilo juegos de pesca"""
	# Mover la aguja más lentamente
	needle_position += needle_speed * needle_direction * delta
	
	# Rebotar en los extremos
	if needle_position >= 1.0:
		needle_position = 1.0
		needle_direction = -1
	elif needle_position <= 0.0:
		needle_position = 0.0
		needle_direction = 1
	
	# Actualizar posiciones visuales
	if target_zone and qte_progress and qte_progress.size.x > 0:
		var bar_width = qte_progress.size.x
		var bar_height = qte_progress.size.y
		
		# Zona objetivo más ancha para mejor jugabilidad
		target_zone.position.x = target_start * bar_width
		target_zone.position.y = 2  # Pequeño margen
		target_zone.size.x = (target_end - target_start) * bar_width
		target_zone.size.y = bar_height - 4  # Margen arriba y abajo
	
	if needle_rect and qte_progress and qte_progress.size.x > 0:
		var bar_width = qte_progress.size.x
		var bar_height = qte_progress.size.y
		var needle_width = max(8, bar_width * 0.025)  # Aguja más ancha
		
		# Aguja bien visible
		needle_rect.position.x = (needle_position * bar_width) - (needle_width / 2)
		needle_rect.position.y = 1
		needle_rect.size.x = needle_width
		needle_rect.size.y = bar_height - 2
	
	# Solo mostrar progreso del tiempo sin cambiar colores
	var time_progress = 1.0 - (timer / qte_duration)
	qte_progress.value = 1.0  # Barra siempre llena, solo para mostrar elementos

func _handle_classic_input(event: InputEvent) -> void:
	"""Manejar input del QTE clásico sin cambios de color"""
	if is_showing_result:
		return  # No procesar input durante resultado
		
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("click"):
		# Verificar si la aguja está en la zona objetivo
		var success = needle_position >= target_start and needle_position <= target_end
		
		# Detener QTE
		is_active = false
		
		# Emitir señal inmediatamente
		if success:
			qte_success.emit()
		else:
			qte_failed.emit()

func _end_qte(success: bool) -> void:
	"""Finalizar QTE por timeout"""
	is_active = false
	visible = false

	# Resetear colores
	_reset_colors()

	# Emitir señal de timeout/fallo
	qte_failed.emit()

func _reset_colors() -> void:
	"""Resetear todos los colores a su estado inicial"""
	if qte_text:
		qte_text.remove_theme_color_override("font_color")
	# NO cambiar colores de la tarjeta principal
	modulate = Color.WHITE
	scale = Vector2.ONE

func _animate_entrance() -> void:
	"""Animar entrada del QTE"""
	scale = Vector2(0.5, 0.5)
	modulate.a = 0.0

	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.3)

func _animate_exit(success: bool) -> void:
	"""Animar salida del QTE sin cambios de color"""
	var tween = create_tween()

	if success:
		# Animación de éxito - solo escala
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)
		tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	else:
		# Animación de fallo - solo shake
		tween.tween_property(self, "position:x", position.x + 8, 0.1)
		tween.tween_property(self, "position:x", position.x - 8, 0.1)
		tween.tween_property(self, "position:x", position.x, 0.1)

	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): visible = false)

func show_result(fish_data: Dictionary) -> void:
	"""Transformar la tarjeta QTE en ventana de resultado"""
	is_showing_result = true
	is_active = false
	
	# Ocultar elementos del QTE
	_hide_qte_elements()
	
	# Mostrar resultado del pez
	_setup_result_display(fish_data)
	
	# Asegurar que la tarjeta esté visible
	visible = true

func _hide_qte_elements() -> void:
	"""Ocultar elementos del QTE"""
	if qte_progress:
		qte_progress.visible = false
	if needle_rect:
		needle_rect.visible = false
	if target_zone:
		target_zone.visible = false

func _setup_result_display(fish_data: Dictionary) -> void:
	"""Configurar display de resultado del pez"""
	# Actualizar icono del pez
	if qte_icon and fish_data.has("icon"):
		qte_icon.texture = fish_data.icon
		qte_icon.visible = true
	
	# Actualizar texto con información del pez
	if qte_text:
		var fish_name = fish_data.get("name", "Pez desconocido")
		var fish_size = fish_data.get("size", 0.0)
		var fish_value = fish_data.get("value", 0)
		
		qte_text.text = "%s\n%.1f cm - %d monedas" % [fish_name, fish_size, fish_value]
		qte_text.add_theme_color_override("font_color", Color.WHITE)
	
	# Crear botones de acción
	_create_action_buttons()

func _create_action_buttons() -> void:
	"""Crear botones de acción para el resultado"""
	# Buscar el contenedor principal
	var main_container = qte_text.get_parent()
	if not main_container:
		return
	
	# Crear contenedor de botones
	action_buttons = HBoxContainer.new()
	action_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	action_buttons.add_theme_constant_override("separation", 20)
	main_container.add_child(action_buttons)
	
	# Botón Guardar
	var keep_button = Button.new()
	keep_button.text = "Guardar"
	keep_button.custom_minimum_size = Vector2(100, 40)
	keep_button.add_theme_color_override("font_color", Color.WHITE)
	keep_button.pressed.connect(_on_keep_pressed)
	action_buttons.add_child(keep_button)
	
	# Botón Liberar
	var release_button = Button.new()
	release_button.text = "Liberar"
	release_button.custom_minimum_size = Vector2(100, 40)
	release_button.add_theme_color_override("font_color", Color.WHITE)
	release_button.pressed.connect(_on_release_pressed)
	action_buttons.add_child(release_button)

func _on_keep_pressed() -> void:
	"""Manejar botón guardar"""
	fish_kept.emit()
	_close_result()

func _on_release_pressed() -> void:
	"""Manejar botón liberar"""
	fish_released.emit()
	_close_result()

func _close_result() -> void:
	"""Cerrar ventana de resultado"""
	is_showing_result = false
	visible = false
	
	# Limpiar botones
	if action_buttons:
		action_buttons.queue_free()
		action_buttons = null
	
	# Resetear para próximo uso
	_reset_for_next_use()

func _reset_for_next_use() -> void:
	"""Resetear tarjeta para próximo uso"""
	_reset_colors()
	if qte_progress:
		qte_progress.visible = true
	if qte_icon:
		qte_icon.visible = true

func force_end() -> void:
	"""Forzar fin del QTE (para casos especiales)"""
	if is_active:
		is_active = false
		qte_timeout.emit()
		visible = false
