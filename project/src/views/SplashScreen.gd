class_name SplashScreen
extends Control

signal splash_finished()

# Variables principales
var logo_texture: Control # Cambiado de TextureRect a Control para flexibilidad
var progress_bar: ProgressBar
var tip_label: Label
var version_label: Label
var press_key_label: Label
var loading_label: Label

# Botones de redes sociales y opciones
var discord_button: Button
var twitter_button: Button
var settings_button: Button

# Estado de carga
var loading_progress := 0.0
var loading_complete := false
var can_continue := false
var current_tip_index := 0

# Tips aleatorios
var loading_tips = [
	"💡 Los peces más raros se encuentran en zonas avanzadas",
	"⚡ Mejora tu equipo para acceder a nuevas zonas",
	"🎯 Practica el QTE para capturas más exitosas",
	"💰 Los multiplicadores de zona afectan todos tus ingresos",
	"🌟 Las rarezas legendarias valen hasta 5x más",
	"🎣 Cada zona tiene peces únicos esperando ser descubiertos",
	"💎 Las gemas te permiten comprar mejoras especiales",
	"🚀 Viaja a zonas más caras para obtener mejores recompensas",
	"🔥 La zona Infernal tiene los multiplicadores más altos",
	"⭐ Tu experiencia crece con cada pez capturado"
]

func _ready():
	setup_ui()
	start_loading()

func setup_ui():
	# Fondo splash.png con escalado perfecto
	var background = TextureRect.new()
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	var splash_texture = load("res://art/env/splash.png")
	if splash_texture:
		background.texture = splash_texture
		print("✅ Splash background loaded successfully")
	else:
		print("⚠️ Splash background not found, using fallback")
		# Fallback a color sólido
		var fallback_bg = ColorRect.new()
		fallback_bg.anchor_right = 1.0
		fallback_bg.anchor_bottom = 1.0
		fallback_bg.color = Color(0.05, 0.15, 0.35) # Azul marino oscuro
		add_child(fallback_bg)
		background = fallback_bg

	if background is TextureRect:
		add_child(background)

	# Crear efectos dinámicos de fondo
	create_dynamic_background_effects()

	# Overlay sutil para mejor contraste
	var overlay = ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0, 0, 0, 0.3) # Overlay sutil
	add_child(overlay)

	# Container principal perfectamente centrado
	var main_container = Control.new()
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	add_child(main_container)

	# Área del logo (centrado en la pantalla)
	setup_logo_area(main_container)

	# Área de consejos (justo debajo del logo)
	setup_logo_tips_area(main_container)

	# Área de carga (parte inferior)
	setup_loading_area(main_container)

	# Área de tips adicionales (centro inferior)
	setup_tips_area(main_container)

	# Footer con información
	setup_footer_area(main_container)

func setup_logo_area(parent: Control):
	"""Configurar área del logo más grande y posicionado más arriba"""
	var logo_wrapper = Control.new()
	logo_wrapper.anchor_left = 0.5
	logo_wrapper.anchor_right = 0.5
	logo_wrapper.anchor_top = 0.25 # Más arriba (era 0.4)
	logo_wrapper.anchor_bottom = 0.25

	# Tamaño del logo mucho más grande e impactante
	var viewport_size = get_viewport().get_visible_rect().size
	var logo_size = Vector2(
		min(800, viewport_size.x * 0.85), # 85% del ancho o 800px máximo (era 70%)
		min(320, viewport_size.y * 0.35) # 35% de la altura o 320px máximo (era 20%)
	)

	logo_wrapper.position = Vector2(-logo_size.x / 2, -logo_size.y / 2)
	logo_wrapper.size = logo_size
	parent.add_child(logo_wrapper)

	# Logo principal (inicialmente invisible para animación)
	logo_texture = TextureRect.new()
	logo_texture.anchor_right = 1.0
	logo_texture.anchor_bottom = 1.0
	logo_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo_texture.modulate.a = 0.0 # Invisible al inicio

	# Cargar el logo usando load dinámico
	var logo_loaded = false

	# Intentar cargar directamente el nuevo logo mejorado
	var logo_resource = load("res://art/logo/logo.png")
	if logo_resource:
		logo_texture.texture = logo_resource
		logo_wrapper.add_child(logo_texture)
		logo_loaded = true
		print("✅ Logo mejorado cargado exitosamente")

	if not logo_loaded:
		print("⚠️ Logo image not found, creating stylized text fallback")
		# Crear fallback de texto estilizado
		create_stylized_text_logo(logo_wrapper, logo_size)

	# Efecto de resplandor detrás del logo
	create_logo_glow_effect(logo_wrapper)

func setup_logo_tips_area(parent: Control):
	"""Configurar área de consejos justo debajo del logo"""
	var tips_container = Control.new()
	tips_container.anchor_left = 0.5
	tips_container.anchor_right = 0.5
	tips_container.anchor_top = 0.46 # Ajustado para logo más grande (era 0.52)
	tips_container.anchor_bottom = 0.46

	var tips_width = 700
	tips_container.position = Vector2(-tips_width / 2, 0)
	tips_container.size = Vector2(tips_width, 80)
	parent.add_child(tips_container)

	# Contenedor vertical para los consejos
	var tips_vbox = VBoxContainer.new()
	tips_vbox.anchor_right = 1.0
	tips_vbox.anchor_bottom = 1.0
	tips_vbox.add_theme_constant_override("separation", 15)
	tips_container.add_child(tips_vbox)

	# Título de consejos
	var tips_title = Label.new()
	tips_title.text = "💡 CONSEJOS DE EXPERTO"
	tips_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tips_title.add_theme_font_size_override("font_size", 16)
	tips_title.add_theme_color_override("font_color", Color.GOLD)
	tips_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	tips_title.add_theme_constant_override("shadow_offset_x", 1)
	tips_title.add_theme_constant_override("shadow_offset_y", 1)
	tips_vbox.add_child(tips_title)

	# Consejo actual (usar la primera variable tip_label para los consejos principales)
	var main_tip_label = Label.new()
	main_tip_label.text = loading_tips[0]
	main_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_tip_label.add_theme_font_size_override("font_size", 15)
	main_tip_label.add_theme_color_override("font_color", Color.WHITE)
	main_tip_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	main_tip_label.add_theme_constant_override("shadow_offset_x", 1)
	main_tip_label.add_theme_constant_override("shadow_offset_y", 1)
	main_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tips_vbox.add_child(main_tip_label)

	# Asignar a la variable global para que las animaciones funcionen
	tip_label = main_tip_label

func setup_loading_area(parent: Control):
	"""Configurar área de carga en la parte inferior"""
	var loading_container = Control.new()
	loading_container.anchor_left = 0.5
	loading_container.anchor_right = 0.5
	loading_container.anchor_top = 0.70 # Ajustado para logo más grande (era 0.75)
	loading_container.anchor_bottom = 0.70

	var container_width = 600
	loading_container.position = Vector2(-container_width / 2, 0)
	loading_container.size = Vector2(container_width, 100)
	parent.add_child(loading_container)

	var loading_vbox = VBoxContainer.new()
	loading_vbox.anchor_right = 1.0
	loading_vbox.anchor_bottom = 1.0
	loading_vbox.add_theme_constant_override("separation", 20)
	loading_container.add_child(loading_vbox)

	# Etiqueta de carga
	loading_label = Label.new()
	loading_label.text = "⚡ PREPARANDO EXPERIENCIA..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", 20)
	loading_label.add_theme_color_override("font_color", Color.WHITE)
	loading_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	loading_label.add_theme_constant_override("shadow_offset_x", 2)
	loading_label.add_theme_constant_override("shadow_offset_y", 2)
	loading_vbox.add_child(loading_label)

	# Barra de progreso estilizada
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(500, 8)
	progress_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	loading_vbox.add_child(progress_bar)

	# Mensaje de continuar (oculto inicialmente)
	press_key_label = Label.new()
	press_key_label.text = "🎮 PRESIONA CUALQUIER TECLA PARA CONTINUAR"
	press_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	press_key_label.add_theme_font_size_override("font_size", 16)
	press_key_label.add_theme_color_override("font_color", Color.YELLOW)
	press_key_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	press_key_label.add_theme_constant_override("shadow_offset_x", 1)
	press_key_label.add_theme_constant_override("shadow_offset_y", 1)
	press_key_label.visible = false
	loading_vbox.add_child(press_key_label)

func setup_tips_area(parent: Control):
	"""Configurar área de información adicional"""
	var tips_container = Control.new()
	tips_container.anchor_left = 0.5
	tips_container.anchor_right = 0.5
	tips_container.anchor_top = 0.88 # Más abajo para dar espacio
	tips_container.anchor_bottom = 0.88

	var tips_width = 700
	tips_container.position = Vector2(-tips_width / 2, 0)
	tips_container.size = Vector2(tips_width, 60)
	parent.add_child(tips_container)

	# Contenedor vertical para información adicional
	var tips_vbox = VBoxContainer.new()
	tips_vbox.anchor_right = 1.0
	tips_vbox.anchor_bottom = 1.0
	tips_vbox.add_theme_constant_override("separation", 5)
	tips_container.add_child(tips_vbox)

	# Solo mostrar información adicional sutil
	var info_label = Label.new()
	info_label.text = "🌊 Prepárate para la aventura de pesca más épica 🌊"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	info_label.add_theme_constant_override("shadow_offset_x", 1)
	info_label.add_theme_constant_override("shadow_offset_y", 1)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tips_vbox.add_child(info_label)

func setup_footer_area(parent: Control):
	"""Configurar footer con información de versión y enlaces sociales"""
	var footer_container = Control.new()
	footer_container.anchor_left = 0.5
	footer_container.anchor_right = 0.5
	footer_container.anchor_top = 0.88 # Ajustado para dar más espacio (era 0.95)
	footer_container.anchor_bottom = 0.88

	var footer_width = 700
	footer_container.position = Vector2(-footer_width / 2, 0)
	footer_container.size = Vector2(footer_width, 120) # Más alto para incluir botones
	parent.add_child(footer_container)

	# VBox principal para organizar elementos del footer
	var footer_vbox = VBoxContainer.new()
	footer_vbox.anchor_right = 1.0
	footer_vbox.anchor_bottom = 1.0
	footer_vbox.add_theme_constant_override("separation", 10)
	footer_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_container.add_child(footer_vbox)

	# Información de versión (más pequeña)
	version_label = Label.new()
	version_label.text = "Fishing SiKness v0.1.0 - Pre-Alpha | © 2025 Hecho con ❤️ y Godot 4.4"
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.add_theme_font_size_override("font_size", 14) # Más pequeño (era 10)
	version_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.9))
	version_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	version_label.add_theme_constant_override("shadow_offset_x", 1)
	version_label.add_theme_constant_override("shadow_offset_y", 1)
	footer_vbox.add_child(version_label)

	# Contenedor horizontal para botones sociales
	var social_buttons_container = HBoxContainer.new()
	social_buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	social_buttons_container.add_theme_constant_override("separation", 25)
	footer_vbox.add_child(social_buttons_container)

	# Botón Discord
	var discord_button = Button.new()
	discord_button.text = "🎮 Discord"
	discord_button.custom_minimum_size = Vector2(120, 35)
	discord_button.add_theme_font_size_override("font_size", 16)
	discord_button.add_theme_color_override("font_color", Color.WHITE)
	discord_button.flat = true
	discord_button.pressed.connect(_on_discord_pressed)
	social_buttons_container.add_child(discord_button)

	# Botón Twitter
	var twitter_button = Button.new()
	twitter_button.text = "🐦 Twitter"
	twitter_button.custom_minimum_size = Vector2(120, 35)
	twitter_button.add_theme_font_size_override("font_size", 16)
	twitter_button.add_theme_color_override("font_color", Color.WHITE)
	twitter_button.flat = true
	twitter_button.pressed.connect(_on_twitter_pressed)
	social_buttons_container.add_child(twitter_button)

	# Botón Opciones
	var options_button = Button.new()
	options_button.text = "⚙️ Opciones"
	options_button.custom_minimum_size = Vector2(120, 35)
	options_button.add_theme_font_size_override("font_size", 16)
	options_button.add_theme_color_override("font_color", Color.WHITE)
	options_button.flat = true
	options_button.pressed.connect(_on_options_pressed)
	social_buttons_container.add_child(options_button)

func start_loading():
	"""Iniciar proceso de carga con logo que aparece durante la carga"""
	# Cambiar tips cada 3 segundos (más lento para mejor lectura)
	var tip_timer = Timer.new()
	tip_timer.timeout.connect(_on_tip_timer_timeout)
	tip_timer.wait_time = 3.0
	tip_timer.autostart = true
	add_child(tip_timer)

	# Progreso de carga simulado
	var loading_timer = Timer.new()
	loading_timer.timeout.connect(_on_loading_timer_timeout)
	loading_timer.wait_time = 0.05 # Más fluido
	loading_timer.autostart = true
	add_child(loading_timer)

	# Logo aparece después de un breve momento
	var logo_timer = Timer.new()
	logo_timer.timeout.connect(_on_logo_reveal_timer)
	logo_timer.wait_time = 0.8 # 800ms antes de mostrar el logo
	logo_timer.one_shot = true
	logo_timer.autostart = true
	add_child(logo_timer)

func _on_tip_timer_timeout():
	"""Cambiar tip mostrado"""
	if not loading_complete:
		current_tip_index = (current_tip_index + 1) % loading_tips.size()
		tip_label.text = loading_tips[current_tip_index]

func _on_loading_timer_timeout():
	"""Actualizar progreso de carga"""
	if loading_complete:
		return

	loading_progress += randf_range(0.015, 0.045) # Progreso más gradual
	progress_bar.value = loading_progress

	# Actualizar mensaje de carga
	if loading_progress < 0.2:
		loading_label.text = "🚀 INICIANDO SISTEMAS..."
	elif loading_progress < 0.4:
		loading_label.text = "⚡ CARGANDO RECURSOS..."
	elif loading_progress < 0.6:
		loading_label.text = "🎣 PREPARANDO EQUIPOS..."
	elif loading_progress < 0.8:
		loading_label.text = "🌊 CONECTANDO OCÉANOS..."
	else:
		loading_label.text = "✅ ¡LISTO PARA PESCAR!"

	# Completar carga
	if loading_progress >= 1.0:
		loading_progress = 1.0
		progress_bar.value = 1.0
		loading_complete = true
		can_continue = true

		# Mostrar mensaje de continuación con efecto
		loading_label.text = "✅ ¡EXPERIENCIA LISTA!"
		press_key_label.visible = true

		# Animación de parpadeo más elegante
		create_continue_animation()

func create_continue_animation():
	"""Crear animación elegante para el mensaje de continuar"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(press_key_label, "modulate:a", 0.4, 1.2)
	tween.tween_property(press_key_label, "modulate:a", 1.0, 1.2)

func _on_logo_reveal_timer():
	"""Mostrar el logo con animación espectacular"""
	if logo_texture:
		create_spectacular_logo_entrance()

func create_spectacular_logo_entrance():
	"""Crear animación de entrada espectacular para el logo"""
	# Configurar estado inicial
	logo_texture.modulate.a = 0.0
	logo_texture.scale = Vector2(0.3, 0.3)
	logo_texture.rotation = 0.2

	# Efecto de aparición con múltiples animaciones paralelas
	var entrance_tween = create_tween()
	entrance_tween.set_parallel(true)

	# Fade in
	entrance_tween.tween_property(logo_texture, "modulate:a", 1.0, 1.8)

	# Scale con rebote
	var scale_tween = entrance_tween.tween_property(logo_texture, "scale", Vector2(1.1, 1.1), 1.5)
	scale_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Rotación suave
	entrance_tween.tween_property(logo_texture, "rotation", 0.0, 1.2)

	# Esperar y luego hacer el ajuste final
	await entrance_tween.finished
	create_final_logo_settle()

func create_final_logo_settle():
	"""Finalizar la animación del logo con asentamiento suave"""
	var settle_tween = create_tween()
	settle_tween.tween_property(logo_texture, "scale", Vector2(1.0, 1.0), 0.3)
	settle_tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Comenzar respiración continua
	settle_tween.tween_callback(create_logo_breathing)

func create_logo_breathing():
	"""Crear animación de respiración continua para el logo"""
	var breathing_tween = create_tween()
	breathing_tween.set_loops()
	breathing_tween.tween_property(logo_texture, "scale", Vector2(1.02, 1.02), 2.5)
	breathing_tween.tween_property(logo_texture, "scale", Vector2(1.0, 1.0), 2.5)

func _input(event):
	"""Detectar entrada del usuario para continuar"""
	if not can_continue:
		return

	var should_continue = false

	# Detectar tecla en PC
	if event is InputEventKey and event.pressed:
		should_continue = true

	# Detectar toque en móvil
	elif event is InputEventScreenTouch and event.pressed:
		should_continue = true

	# Detectar clic del ratón
	elif event is InputEventMouseButton and event.pressed:
		should_continue = true

	if should_continue:
		_finish_splash()

func create_logo_glow_effect(parent: Control):
	"""Crear efecto de resplandor elegante detrás del logo"""
	var glow = ColorRect.new()
	glow.anchor_left = 0.5
	glow.anchor_right = 0.5
	glow.anchor_top = 0.5
	glow.anchor_bottom = 0.5
	glow.size = parent.size * 1.8
	glow.position = Vector2(-glow.size.x / 2, -glow.size.y / 2)
	glow.color = Color(0.2, 0.6, 1.0, 0.15)
	parent.add_child(glow)

	# Pulso suave del resplandor
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(glow, "modulate:a", 0.1, 3.0)
	glow_tween.tween_property(glow, "modulate:a", 0.4, 3.0)

func create_stylized_text_logo(parent: Control, _size: Vector2):
	"""Crear un logo de texto estilizado como fallback"""
	var text_logo = Label.new()
	text_logo.text = "🎣 FISHING SIKNESS 🎣"
	text_logo.anchor_right = 1.0
	text_logo.anchor_bottom = 1.0
	text_logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_logo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_logo.add_theme_font_size_override("font_size", 40)
	text_logo.add_theme_color_override("font_color", Color.WHITE)
	text_logo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	text_logo.add_theme_constant_override("shadow_offset_x", 3)
	text_logo.add_theme_constant_override("shadow_offset_y", 3)
	text_logo.add_theme_color_override("font_outline_color", Color(0.2, 0.6, 1.0))
	text_logo.add_theme_constant_override("outline_size", 4)
	text_logo.modulate.a = 0.0 # Invisible para animación
	parent.add_child(text_logo)

	# Usar como logo_texture para las animaciones
	logo_texture = text_logo

func _finish_splash():
	"""Finalizar splash screen y continuar al juego"""
	if SFX:
		SFX.play_event("success")

	print("Splash screen finished - transitioning to main game")
	emit_signal("splash_finished")

func create_dynamic_background_effects():
	"""Crear efectos dinámicos de fondo"""
	# Partículas flotantes
	create_floating_particles()

	# Ondas de agua animadas
	create_water_waves()

	# Efecto de luz suave
	create_ambient_light_effect()

func create_floating_particles():
	"""Crear partículas flotantes más sofisticadas en el fondo"""
	# Partículas principales más visibles
	for i in range(12):
		var particle = ColorRect.new()
		particle.size = Vector2(6, 6)
		particle.color = Color(0.8, 0.9, 1.0, randf_range(0.2, 0.5))
		particle.anchor_left = randf()
		particle.anchor_top = randf()
		add_child(particle)

		# Animación de movimiento flotante
		var tween = create_tween()
		tween.set_loops()
		var offset = Vector2(randf_range(-80, 80), randf_range(-50, 50))
		tween.tween_property(particle, "position",
			particle.position + offset,
			randf_range(4.0, 8.0))
		tween.tween_property(particle, "position",
			particle.position,
			randf_range(4.0, 8.0))

		# Animación de opacidad más suave
		var opacity_tween = create_tween()
		opacity_tween.set_loops()
		opacity_tween.tween_property(particle, "modulate:a", 0.1, randf_range(3.0, 5.0))
		opacity_tween.tween_property(particle, "modulate:a", 0.6, randf_range(3.0, 5.0))

	# Partículas menores de fondo
	for i in range(20):
		var mini_particle = ColorRect.new()
		mini_particle.size = Vector2(2, 2)
		mini_particle.color = Color(1, 1, 1, randf_range(0.1, 0.2))
		mini_particle.anchor_left = randf()
		mini_particle.anchor_top = randf()
		add_child(mini_particle)

		# Movimiento más lento y sutil
		var mini_tween = create_tween()
		mini_tween.set_loops()
		var mini_offset = Vector2(randf_range(-30, 30), randf_range(-20, 20))
		mini_tween.tween_property(mini_particle, "position",
			mini_particle.position + mini_offset,
			randf_range(8.0, 12.0))
		mini_tween.tween_property(mini_particle, "position",
			mini_particle.position,
			randf_range(8.0, 12.0))

func create_water_waves():
	"""Crear efecto de ondas de agua en la parte inferior"""
	var wave_container = Control.new()
	wave_container.anchor_right = 1.0
	wave_container.anchor_top = 0.8
	wave_container.anchor_bottom = 1.0
	add_child(wave_container)

	for i in range(3):
		var wave = ColorRect.new()
		wave.anchor_right = 1.0
		wave.anchor_bottom = 1.0
		wave.anchor_top = float(i) * 0.3
		# Gradiente simple para las ondas
		wave.color = Color(0.2, 0.6, 1.0, 0.1 + i * 0.05)
		wave_container.add_child(wave)

		# Animación de las ondas
		var wave_tween = create_tween()
		wave_tween.set_loops()
		wave_tween.tween_property(wave, "modulate:a", 0.1, 2.0 + i * 0.5)
		wave_tween.tween_property(wave, "modulate:a", 0.3, 2.0 + i * 0.5)

func create_ambient_light_effect():
	"""Crear efecto de luz ambiente suave"""
	var light_overlay = ColorRect.new()
	light_overlay.anchor_right = 1.0
	light_overlay.anchor_bottom = 1.0
	light_overlay.color = Color(1.0, 0.9, 0.7, 0.1)
	add_child(light_overlay)

	# Animación suave de la luz
	var light_tween = create_tween()
	light_tween.set_loops()
	light_tween.tween_property(light_overlay, "modulate:a", 0.3, 4.0)
	light_tween.tween_property(light_overlay, "modulate:a", 0.7, 4.0)

func create_glow_effect(parent: Control):
	"""Crear efecto de resplandor detrás del logo"""
	var glow = ColorRect.new()
	glow.anchor_left = 0.5
	glow.anchor_right = 0.5
	glow.anchor_top = 0.5
	glow.anchor_bottom = 0.5
	glow.size = parent.custom_minimum_size * 1.5
	glow.position = Vector2(-glow.size.x / 2, -glow.size.y / 2)
	glow.color = Color(0.3, 0.7, 1.0, 0.2)
	parent.add_child(glow)

	# Animación de pulso para el resplandor
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(glow, "modulate:a", 0.2, 2.0)
	glow_tween.tween_property(glow, "modulate:a", 0.6, 2.0)

func create_logo_entrance_animation():
	"""Crear animación de entrada espectacular para el logo"""
	# Empezar invisible y escalado
	logo_texture.modulate.a = 0.0
	logo_texture.scale = Vector2(0.5, 0.5)

	# Animación de entrada con rebote
	var entrance_tween = create_tween()
	entrance_tween.parallel().tween_property(logo_texture, "modulate:a", 1.0, 1.5)
	var scale_tween = entrance_tween.parallel().tween_method(scale_bounce, 0.5, 1.0, 1.5)
	scale_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Después de la entrada, animación de respiración suave
	entrance_tween.tween_callback(create_logo_breathing_animation)

func scale_bounce(value: float):
	"""Función auxiliar para la animación de rebote del logo"""
	if logo_texture:
		logo_texture.scale = Vector2(value, value)

func create_logo_breathing_animation():
	"""Crear animación de respiración continua para el logo"""
	var breathing_tween = create_tween()
	breathing_tween.set_loops()
	breathing_tween.tween_property(logo_texture, "scale", Vector2(1.05, 1.05), 3.0)
	breathing_tween.tween_property(logo_texture, "scale", Vector2(1.0, 1.0), 3.0)

func create_title_animation(title: Label):
	"""Crear animación para el título"""
	# Empezar desde abajo y transparente
	title.position.y += 50
	title.modulate.a = 0.0

	# Animación de entrada
	var title_tween = create_tween()
	var new_y = title.position.y - 50
	var pos_tween = title_tween.parallel().tween_property(title, "position:y", new_y, 1.0)
	pos_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	title_tween.parallel().tween_property(title, "modulate:a", 1.0, 1.0)

	# Animación de brillo sutil
	title_tween.tween_callback(func(): create_title_glow_animation(title))

func create_title_glow_animation(title: Label):
	"""Crear animación de brillo para el título"""
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(title, "modulate", Color.WHITE, 4.0)
	glow_tween.tween_property(title, "modulate", Color(1.2, 1.2, 1.2, 1.0), 4.0)

func create_text_logo_fallback(parent: Control, size: Vector2):
	"""Crear un logo de texto como fallback si no existe la imagen"""
	var fallback_label = Label.new()
	fallback_label.text = "🎣 FISHING SIKNNESS 🎣"
	fallback_label.anchor_left = 0.5
	fallback_label.anchor_right = 0.5
	fallback_label.anchor_top = 0.5
	fallback_label.anchor_bottom = 0.5
	fallback_label.position = Vector2(-size.x / 2, -size.y / 2)
	fallback_label.size = size
	fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback_label.add_theme_font_size_override("font_size", 48)
	fallback_label.add_theme_color_override("font_color", Color.WHITE)
	fallback_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	fallback_label.add_theme_constant_override("shadow_offset_x", 3)
	fallback_label.add_theme_constant_override("shadow_offset_y", 3)
	fallback_label.add_theme_color_override("font_outline_color", Color(0.2, 0.6, 1.0))
	fallback_label.add_theme_constant_override("outline_size", 4)
	parent.add_child(fallback_label)

	# Usar el fallback como logo_texture para las animaciones
	logo_texture = fallback_label

# === FUNCIONES DE BOTONES SOCIALES ===

func _on_discord_pressed():
	"""Abrir Discord o mostrar información"""
	print("🎮 Abriendo Discord...")
	OS.shell_open("https://discord.gg/fishingsikness")

func _on_twitter_pressed():
	"""Abrir Twitter o mostrar información"""
	print("🐦 Abriendo Twitter...")
	OS.shell_open("https://twitter.com/fishingsikness")

func _on_options_pressed():
	"""Mostrar menú de opciones"""
	print("⚙️ Abriendo opciones...")
	# TODO: Implementar menú de opciones durante splash
	# Por ahora, solo mostrar un mensaje
	if loading_label:
		loading_label.text = "⚙️ CONFIGURACIONES DISPONIBLES PRONTO..."
		var timer = Timer.new()
		timer.wait_time = 2.0
		timer.one_shot = true
		timer.timeout.connect(func(): loading_label.text = "⚡ PREPARANDO EXPERIENCIA...")
		add_child(timer)
		timer.start()
