extends Control
# CaptureCard.gd - Tarjeta flotante para mostrar resultados de captura
# Se muestra en esquina y desaparece automáticamente

var fish_icon: TextureRect
var fish_name_label: Label
var xp_label: Label
var coins_label: Label
var auto_close_timer: Timer
var fish_data: Dictionary
var capture_result: Dictionary

# Método estático para crear y mostrar una tarjeta de captura
static func show_capture_in_corner(fish, result: Dictionary, duration: float = 3.0) -> void:
	"""Crear y mostrar una tarjeta de captura en la esquina de la pantalla"""
	var capture_card = load("res://src/windows/CaptureCard.gd").new()
	capture_card.fish_data = fish if fish else {"name": "Pez de Prueba", "icon": null}
	capture_card.capture_result = result

	if FloatingWindowManager:
		# Abrir ventana con datos en un diccionario (ajuste de API)
		var params: Dictionary = {"window_type": FloatingWindowManager.WindowType.CARD}
		FloatingWindowManager.open_window(capture_card, params)

		# Auto-cerrar después del tiempo especificado
		capture_card.setup_auto_close(duration)
	else:
		print("ERROR FloatingWindowManager no disponible para mostrar CaptureCard")

func _ready() -> void:
	# Inicialización mínima
	pass

func setup_content() -> void:
	"""Configurar el contenido específico de la tarjeta - llamado automáticamente"""
	setup_capture_content()

func setup_capture_content() -> void:
	# Crear estructura de contenido simple en self
	var vbox = VBoxContainer.new()
	add_child(vbox)

	# Título "¡Captura!"
	var title = Label.new()
	title.text = "¡CAPTURA!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	# Separador
	var separator1 = HSeparator.new()
	vbox.add_child(separator1)

	# Contenedor horizontal para icono y nombre del pez
	var fish_hbox = HBoxContainer.new()
	vbox.add_child(fish_hbox)

	# Icono del pez (placeholder por ahora)
	fish_icon = TextureRect.new()
	fish_icon.custom_minimum_size = Vector2(32, 32)
	fish_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fish_hbox.add_child(fish_icon)

	# Nombre del pez
	fish_name_label = Label.new()
	fish_name_label.text = fish_data.get("name", "Pez Desconocido")
	fish_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fish_hbox.add_child(fish_name_label)

	# Separador
	var separator2 = HSeparator.new()
	vbox.add_child(separator2)

	# Recompensas
	var rewards_label = Label.new()
	rewards_label.text = "Recompensas:"
	rewards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewards_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(rewards_label)

	# XP ganada
	if capture_result.has("xp") and capture_result.xp > 0:
		xp_label = Label.new()
		xp_label.text = "+%d XP" % capture_result.xp
		xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(xp_label)

	# Monedas ganadas
	if capture_result.has("coins") and capture_result.coins > 0:
		coins_label = Label.new()
		coins_label.text = "COINS +%d" % capture_result.coins
		coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(coins_label)

	# Si hay otros datos en capture_result, mostrarlos también
	for key in capture_result.keys():
		if key not in ["xp", "coins"] and capture_result[key] is int and capture_result[key] > 0:
			var reward_label = Label.new()
			reward_label.text = "+%d %s" % [capture_result[key], key.capitalize()]
			reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(reward_label)

func setup_auto_close(duration: float) -> void:
	"""Configurar el timer para auto-cerrar la tarjeta"""
	auto_close_timer = Timer.new()
	auto_close_timer.wait_time = duration
	auto_close_timer.one_shot = true
	auto_close_timer.timeout.connect(_on_auto_close_timeout)
	add_child(auto_close_timer)
	auto_close_timer.start()

func _on_auto_close_timeout() -> void:
	"""Cerrar automáticamente la tarjeta"""
	if FloatingWindowManager:
		FloatingWindowManager.close_window(self)

func get_window_type() -> int:
	# Valor simbólico, evitar dependencia fuerte
	return 0

func on_window_opened() -> void:
	# Animación de entrada (opcional)
	# Animación simple de escala
	scale = Vector2(0.8, 0.8)
	modulate.a = 0.0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func on_window_closed() -> void:
	# Animación de salida (opcional)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)

# Sobreescribir input para permitir click para cerrar rápidamente
func _gui_input(event) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if auto_close_timer:
			auto_close_timer.stop()
		_on_auto_close_timeout()
