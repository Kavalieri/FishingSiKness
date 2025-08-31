extends Control

signal splash_finished()
signal pause_requested()

# Variables principales
var logo_texture: TextureRect
var subtitle_label: Label
var progress_bar: ProgressBar
var progress_label: Label
var tip_label: Label
var version_label: Label
var license_label: Label

# Botones sociales
var discord_button: Button
var twitter_button: Button
var options_button: Button

# Estado de carga
var loading_progress := 0.0
var loading_complete := false
var can_continue := false
var waiting_for_input := false
var continue_label: Label
var current_tip_index := 0
var loading_steps := [
	"Cargando sistemas de pesca...",
	"Inicializando zonas de pesca...",
	"Preparando especies marinas...",
	"Configurando equipamiento...",
	"Cargando datos de guardado...",
	"Optimizando experiencia...",
	"¡Listo para pescar!"
]
var current_step := 0

# Tips de experto sin emojis (ahora texto limpio)
var expert_tips = [
	"Tip de Experto
Los peces más raros se encuentran en aguas profundas",
	"Consejo Pro
Mejora tu equipo para acceder a nuevas zonas",
	"Experto
Domina el QTE para capturas perfectas",
	"Pro-tip
Los multiplicadores de zona maximizan tus ganancias",
	"Maestro
Las rarezas legendarias pueden valer hasta 10x más",
	"Experto
Cada zona tiene especies únicas que descubrir",
	"Consejo
Las gemas desbloquean mejoras especiales",
	"Pro
Las zonas avanzadas tienen mejores recompensas",
	"Maestro
La zona Infernal es para pescadores expertos",
	"Tip
Tu experiencia crece con cada captura exitosa"
]

func _ready():
	setup_splash_background()
	setup_ui_from_scene()
	start_loading()

func setup_splash_background():
	"""Configurar fondo splash con BackgroundManager"""
	if BackgroundManager:
		BackgroundManager.setup_splash_background(self)
		print("OK Fondo splash configurado con BackgroundManager")
	else:
		print("WARNING BackgroundManager no disponible, usando fallback")
		setup_fallback_background()

func setup_fallback_background():
	"""Fondo fallback si BackgroundManager no está disponible"""
	var background = TextureRect.new()
	background.name = "Background"
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

	var splash_texture = load("res://art/env/splash.png")
	if splash_texture:
		background.texture = splash_texture
	else:
		var color_bg = ColorRect.new()
		color_bg.name = "Background"
		color_bg.anchor_right = 1.0
		color_bg.anchor_bottom = 1.0
		color_bg.color = Color(0.05, 0.15, 0.35)
		add_child(color_bg)
		return

	add_child(background)
	move_child(background, 0) # Mover al fondo

func setup_ui_from_scene():
	"""Configurar UI usando SOLO nodos del .tscn - versión limpia"""
	print("TARGET Configurando Splash Screen desde .tscn...")

	# Obtener contenedores
	var logo_container = $MainContainer/LogoArea/LogoContainer
	var subtitle_container = $MainContainer/ContentArea/SubtitleContainer
	var tips_container = $MainContainer/ContentArea/TipsContainer
	var loading_container = $MainContainer/ContentArea/LoadingContainer
	var social_container = $MainContainer/FooterArea/SocialContainer
	var version_container = $MainContainer/FooterArea/VersionContainer

	# Configurar cada elemento
	setup_logo(logo_container)
	setup_subtitle(subtitle_container)
	setup_tips(tips_container)
	setup_loading(loading_container)
	setup_social_buttons(social_container)
	setup_version(version_container)
	setup_options_button() # Botón de opciones en esquina superior derecha

func setup_logo(container: Control):
	"""Logo configurado SOLO desde .tscn - NO tocar desde código"""
	# Solo obtener referencia, SIN configurar nada
	logo_texture = container.get_node("LogoTexture")
	print("OK Logo referenciado desde .tscn (sin modificaciones)")
	# TODO: Si necesitas animaciones, hacerlas aquí sin tocar stretch_mode

func create_logo_animation():
	"""Animación DESHABILITADA - causaba problemas de escala"""
	# Función deshabilitada para evitar interferencias con el tamaño del logo
	return

func setup_subtitle(container: Control):
	"""Subtítulo del juego"""
	subtitle_label = Label.new()
	subtitle_label.text = "El simulador de pesca más adictivo"
	subtitle_label.anchor_right = 1.0
	subtitle_label.anchor_bottom = 1.0
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 24)
	subtitle_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	subtitle_label.add_theme_constant_override("shadow_offset_x", 2)
	subtitle_label.add_theme_constant_override("shadow_offset_y", 2)
	container.add_child(subtitle_label)

func setup_tips(container: Control):
	"""Tips rotativos"""
	tip_label = Label.new()
	tip_label.text = expert_tips[0]
	tip_label.anchor_right = 1.0
	tip_label.anchor_bottom = 1.0
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip_label.add_theme_font_size_override("font_size", 20) # Aumentado de 16 a 20
	tip_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	tip_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	tip_label.add_theme_constant_override("shadow_offset_x", 1)
	tip_label.add_theme_constant_override("shadow_offset_y", 1)
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(tip_label)

	# Rotar tips cada 3 segundos
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.timeout.connect(_rotate_tip)
	timer.autostart = true
	add_child(timer)

func setup_loading(container: Control):
	"""Barra de carga y progreso"""
	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(vbox)

	# Etiqueta de progreso
	progress_label = Label.new()
	progress_label.text = "Inicializando sistemas..."
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 20) # Aumentado de 16 a 20
	progress_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	vbox.add_child(progress_label)

	# Barra de progreso
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(400, 8)
	progress_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress_bar.value = 0
	progress_bar.max_value = 100
	vbox.add_child(progress_bar)

func setup_social_buttons(container: Control):
	"""Botones sociales - SIN botón de opciones (está en esquina superior)"""
	var hbox = HBoxContainer.new()
	hbox.anchor_left = 0.5
	hbox.anchor_right = 0.5
	hbox.anchor_top = 0.5
	hbox.anchor_bottom = 0.5
	hbox.offset_left = -100 # Reducido porque hay menos botones
	hbox.offset_right = 100
	hbox.offset_top = -20
	hbox.offset_bottom = 20
	hbox.add_theme_constant_override("separation", 20)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(hbox)

	discord_button = Button.new()
	discord_button.text = "Discord"
	discord_button.custom_minimum_size = Vector2(80, 40)
	hbox.add_child(discord_button)

	twitter_button = Button.new()
	twitter_button.text = "Twitter"
	twitter_button.custom_minimum_size = Vector2(80, 40)
	hbox.add_child(twitter_button)

	# Botón de opciones ELIMINADO - solo está en la esquina superior derecha

func setup_version(container: Control):
	"""Información de versión centrada - IGNORANDO contenedor limitado del .tscn"""
	# IGNORAR completamente el contenedor pequeño del .tscn
	# Crear nuestro propio contenedor que ocupe todo el ancho de pantalla

	# Obtener FooterArea (el contenedor padre)
	var footer_area = container.get_parent()

	# Crear contenedor de versión que ocupe TODO el ancho
	var full_width_version_container = Control.new()
	full_width_version_container.anchor_left = 0.0
	full_width_version_container.anchor_right = 1.0
	full_width_version_container.anchor_top = 0.7
	full_width_version_container.anchor_bottom = 1.0
	footer_area.add_child(full_width_version_container)

	# Línea de versión - ocupa todo el ancho disponible
	version_label = Label.new()
	version_label.text = "Fishing SiKness v0.2.5-alpha pre-release"
	version_label.anchor_left = 0.0
	version_label.anchor_right = 1.0
	version_label.anchor_top = 0.0
	version_label.anchor_bottom = 0.5
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	version_label.add_theme_font_size_override("font_size", 16)
	version_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	full_width_version_container.add_child(version_label)

	# Línea de copyright - ocupa todo el ancho disponible
	license_label = Label.new()
	license_label.text = "© 2025 Kava - SiK Studio | Hecho 100% con Agentes IA | GNU GPL v3.0"
	license_label.anchor_left = 0.0
	license_label.anchor_right = 1.0
	license_label.anchor_top = 0.5
	license_label.anchor_bottom = 1.0
	license_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	license_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	license_label.add_theme_font_size_override("font_size", 14)
	license_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7))
	full_width_version_container.add_child(license_label)

func _rotate_tip():
	"""Rotar tip actual"""
	current_tip_index = (current_tip_index + 1) % expert_tips.size()
	if tip_label:
		tip_label.text = expert_tips[current_tip_index]

func start_loading():
	"""Iniciar secuencia de carga"""
	print("REFRESH Iniciando secuencia de carga...")
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(_update_loading)
	timer.autostart = true
	add_child(timer)

func _update_loading():
	"""Actualizar progreso de carga"""
	if current_step < loading_steps.size():
		progress_label.text = loading_steps[current_step]
		progress_bar.value = (current_step + 1) * (100.0 / loading_steps.size())
		current_step += 1
	else:
		# Carga completa - esperar input del usuario
		progress_label.text = "¡Carga completa!"
		progress_bar.value = 100.0
		await get_tree().create_timer(0.5).timeout
		show_continue_prompt()
		waiting_for_input = true
		print("OK Carga completa - esperando input del usuario")

func show_continue_prompt():
	"""Mostrar mensaje para continuar - centrado y estéticamente mejorado"""
	continue_label = Label.new()
	continue_label.text = "Presiona cualquier tecla para continuar"
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	continue_label.add_theme_font_size_override("font_size", 22)
	continue_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.9))
	continue_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	continue_label.add_theme_constant_override("shadow_offset_x", 2)
	continue_label.add_theme_constant_override("shadow_offset_y", 2)

	# Posicionar centrado debajo de la barra de progreso
	var loading_container = $MainContainer/ContentArea/LoadingContainer
	continue_label.anchor_left = 0.0
	continue_label.anchor_right = 1.0
	continue_label.anchor_top = 1.0
	continue_label.anchor_bottom = 1.0
	continue_label.offset_top = 20.0
	continue_label.offset_bottom = 50.0
	loading_container.add_child(continue_label)

	# Animación de parpadeo
	create_continue_animation()

func create_continue_animation():
	"""Animación de parpadeo para el texto de continuar"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(continue_label, "modulate:a", 0.3, 1.0)
	tween.tween_property(continue_label, "modulate:a", 1.0, 1.0)

func _input(event):
	"""Detectar input del usuario"""
	if not waiting_for_input:
		return

	var should_continue = false

	# Detectar cualquier tecla presionada
	if event is InputEventKey and event.pressed:
		should_continue = true

	# Detectar click del mouse (PERO NO en el botón de opciones)
	elif event is InputEventMouseButton and event.pressed:
		# Verificar que no sea un clic en el botón de opciones
		var mouse_pos = event.position
		var options_area = Rect2(get_viewport().size.x - 100, 0, 100, 60)
		if not options_area.has_point(mouse_pos):
			should_continue = true

	# Detectar touch en móvil (PERO NO en el botón de opciones)
	elif event is InputEventScreenTouch and event.pressed:
		var touch_pos = event.position
		var options_area = Rect2(get_viewport().size.x - 100, 0, 100, 60)
		if not options_area.has_point(touch_pos):
			should_continue = true

	if should_continue:
		continue_to_game()

func continue_to_game():
	"""Continuar al juego principal"""
	waiting_for_input = false
	print("TARGET Usuario presionó para continuar - emitiendo splash_finished")
	splash_finished.emit()

func setup_options_button():
	"""Botón de opciones en esquina superior derecha"""
	var options_container = Control.new()
	options_container.name = "OptionsContainer"
	# Posicionar en esquina superior derecha
	options_container.anchor_left = 1.0
	options_container.anchor_right = 1.0
	options_container.anchor_top = 0.0
	options_container.anchor_bottom = 0.0
	options_container.offset_left = -90.0 # Ancho del botón + margen
	options_container.offset_right = -10.0 # Margen derecho
	options_container.offset_top = 10.0 # Margen superior
	options_container.offset_bottom = 50.0 # Alto del botón + margen
	add_child(options_container)

	var top_options_button = Button.new()
	top_options_button.name = "OptionsButton"

	# Configurar icono de pausa con tamaño controlado
	var icon_size = 35 # Aumentado a 35x35 píxeles
	var options_texture = load("res://art/ui/assets/pause-options.png")
	if options_texture:
		var options_image = options_texture.get_image()
		options_image.resize(icon_size, icon_size)
		var options_icon = ImageTexture.new()
		options_icon.set_image(options_image)
		top_options_button.icon = options_icon
		top_options_button.expand_icon = false
		top_options_button.text = "" # Sin texto, solo icono
	else:
		top_options_button.text = "SETTINGS" # Fallback si no se puede cargar el icono

	top_options_button.custom_minimum_size = Vector2(80, 40)
	# El botón llena completamente su container
	top_options_button.anchor_left = 0.0
	top_options_button.anchor_right = 1.0
	top_options_button.anchor_top = 0.0
	top_options_button.anchor_bottom = 1.0
	top_options_button.pressed.connect(_on_options_pressed)
	options_container.add_child(top_options_button)

	print("OK Botón de opciones configurado en esquina superior derecha")

func _on_options_pressed():
	"""
	Manejar clic en botón de opciones.
	En lugar de abrir un menú aquí, solo emitimos una señal.
	Un gestor central se encargará de abrir el menú de pausa correcto.
	"""
	print("WRENCH Pause requested from splash screen.")
	pause_requested.emit()
