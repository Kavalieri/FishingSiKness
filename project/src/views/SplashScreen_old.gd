class_name SplashScreen
extends Control

signal splash_finished()

# Variables principales
var logo_texture: Control
var subtitle_label: Label
var progress_bar: ProgressBar
var progress_label: Label
var tip_label: Label
var version_label: Label
var license_label: Label
var loading_label: Label
var press_key_label: Label

# Botones sociales
var discord_button: Button
var twitter_button: Button
var options_button: Button

# Estado de carga
var loading_progress := 0.0
var loading_complete := false
var can_continue := false
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

# Tips de experto (reubicados)
var expert_tips = [
	"💡 Tip de Experto: Los peces más raros se encuentran en aguas profundas",
	"⚡ Consejo Pro: Mejora tu equipo para acceder a nuevas zonas",
	"🎯 Experto: Domina el QTE para capturas perfectas",
	"💰 Pro-tip: Los multiplicadores de zona maximizan tus ganancias",
	"🌟 Maestro: Las rarezas legendarias pueden valer hasta 10x más",
	"🎣 Experto: Cada zona tiene especies únicas que descubrir",
	"💎 Consejo: Las gemas desbloquean mejoras especiales",
	"🚀 Pro: Las zonas avanzadas tienen mejores recompensas",
	"🔥 Maestro: La zona Infernal es para pescadores expertos",
	"⭐ Tip: Tu experiencia crece con cada captura exitosa"
]

func _ready():
	setup_ui()
	start_loading()

func setup_ui():
	"""Configurar UI de la splash screen con nuevo diseño épico"""
	# Fondo splash con escalado perfecto
	setup_background()

	# Overlay sutil para contraste
	var overlay = ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0, 0, 0, 0.25) # Overlay más sutil
	add_child(overlay)

	# Container principal
	var main_container = Control.new()
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	add_child(main_container)

	# 1. Logo gigante en mitad superior
	setup_main_logo_area(main_container)

	# 2. Subtítulo épico debajo del logo
	setup_subtitle_area(main_container)

	# 3. Barra de carga atractiva y central
	setup_dynamic_loading_area(main_container)

	# 4. Tips de experto reubicados estéticamente
	setup_expert_tips_area(main_container)

	# 5. Botones sociales sobre copyright
	setup_social_buttons_area(main_container)

	# 6. Footer con versión y licencia GNU3
	setup_enhanced_footer_area(main_container)

func setup_background():
	"""Configurar el fondo splash optimizado"""
	var background = TextureRect.new()
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

	var splash_texture = load("res://art/env/splash.png")
	if splash_texture:
		background.texture = splash_texture
		print("✅ Splash background cargado exitosamente")
	else:
		print("⚠️ Fondo splash no encontrado, usando fallback")
		var fallback_bg = ColorRect.new()
		fallback_bg.anchor_right = 1.0
		fallback_bg.anchor_bottom = 1.0
		fallback_bg.color = Color(0.05, 0.15, 0.35)
		add_child(fallback_bg)
		return

	add_child(background)

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
	main_tip_label.text = expert_tips[0]
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
	"""Sistema de carga progresiva e informativa"""
	# Timer para tips de experto cada 4 segundos
	var tip_timer = Timer.new()
	tip_timer.timeout.connect(_on_expert_tip_timeout)
	tip_timer.wait_time = 4.0
	tip_timer.autostart = true
	add_child(tip_timer)

	# Timer para progreso de carga realista por etapas
	var loading_timer = Timer.new()
	loading_timer.timeout.connect(_on_progressive_loading_timeout)
	loading_timer.wait_time = 0.8 # Cada etapa dura ~800ms
	loading_timer.autostart = true
	add_child(loading_timer)

	# Iniciar primera etapa
	advance_loading_step()

func advance_loading_step():
	"""Avanzar al siguiente paso de carga"""
	if current_step < loading_steps.size():
		if progress_label:
			progress_label.text = loading_steps[current_step]

		# Calcular progreso
		var target_progress = (current_step + 1.0) / loading_steps.size() * 100.0
		animate_progress_bar(target_progress)

		if loading_label:
			loading_label.text = str(int(target_progress)) + "%"

		current_step += 1
		loading_progress = target_progress

		# Cuando termine la carga, permitir continuar
		if current_step >= loading_steps.size():
			loading_complete = true
			can_continue = true
			show_continue_prompt()

func animate_progress_bar(target_value: float):
	"""Animar la barra de progreso suavemente"""
	if not progress_bar:
		return

	var tween = create_tween()
	tween.tween_property(progress_bar, "value", target_value, 0.6)

func show_continue_prompt():
	"""Mostrar prompt para continuar"""
	if progress_label:
		progress_label.text = "¡Sistema listo! Presiona cualquier tecla para continuar..."
		progress_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))

	if loading_label:
		loading_label.text = "100% ✓"
		loading_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))

	# Logo aparece después de un breve momento
	var logo_timer = Timer.new()
	logo_timer.timeout.connect(_on_logo_reveal_timer)
	logo_timer.wait_time = 0.8 # 800ms antes de mostrar el logo
	logo_timer.one_shot = true
	logo_timer.autostart = true
	add_child(logo_timer)

func _on_expert_tip_timeout():
	"""Cambiar tips de experto cada 4 segundos"""
	if not tip_label:
		return

	current_tip_index = (current_tip_index + 1) % expert_tips.size()

	# Animación de cambio de tip
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(tip_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): tip_label.text = expert_tips[current_tip_index]).set_delay(0.3)
	tween.tween_property(tip_label, "modulate:a", 1.0, 0.3).set_delay(0.3)

func _on_progressive_loading_timeout():
	"""Avanzar carga progresiva"""
	if not loading_complete:
		advance_loading_step()

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

# === NUEVAS FUNCIONES DE LA SPLASH SCREEN ÉPICA ===

func setup_main_logo_area(parent: Control):
	"""Logo GIGANTE ocupando la mitad superior"""
	var logo_container = Control.new()
	logo_container.anchor_left = 0.5
	logo_container.anchor_right = 0.5
	logo_container.anchor_top = 0.05 # Muy arriba
	logo_container.anchor_bottom = 0.05

	# Tamaño ÉPICO para el logo - ocupa mitad superior
	var viewport_size = get_viewport().get_visible_rect().size
	var logo_size = Vector2(
		min(1000, viewport_size.x * 0.98), # 98% del ancho máximo
		min(500, viewport_size.y * 0.45) # 45% de altura = casi mitad superior
	)

	logo_container.position = Vector2(-logo_size.x / 2, 0)
	logo_container.size = logo_size
	parent.add_child(logo_container)

	# Cargar y mostrar el logo
	var logo_resource = load("res://art/logo/logo.png")
	if logo_resource:
		logo_texture = TextureRect.new()
		logo_texture.anchor_right = 1.0
		logo_texture.anchor_bottom = 1.0
		logo_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo_texture.texture = logo_resource
		logo_texture.modulate.a = 0.0 # Invisible para animación
		logo_container.add_child(logo_texture)
		print("✅ Logo épico cargado - tamaño:", logo_size)
	else:
		print("⚠️ Logo no encontrado")
		create_fallback_logo(logo_container, logo_size)

	# Efecto de entrada dramática
	create_epic_logo_entrance()

func setup_subtitle_area(parent: Control):
	"""Subtítulo épico justo debajo del logo"""
	var subtitle_container = Control.new()
	subtitle_container.anchor_left = 0.5
	subtitle_container.anchor_right = 0.5
	subtitle_container.anchor_top = 0.52 # Justo después del logo
	subtitle_container.anchor_bottom = 0.52

	var subtitle_width = 800
	subtitle_container.position = Vector2(-subtitle_width / 2, 0)
	subtitle_container.size = Vector2(subtitle_width, 60)
	parent.add_child(subtitle_container)

	subtitle_label = Label.new()
	subtitle_label.text = "🌊 ¡PREPÁRATE PARA LA AVENTURA DE PESCA MÁS ÉPICA! 🎣"
	subtitle_label.anchor_right = 1.0
	subtitle_label.anchor_bottom = 1.0
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 24)
	subtitle_label.add_theme_color_override("font_color", Color(1, 1, 0.3, 0.95)) # Dorado épico
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	subtitle_label.add_theme_constant_override("shadow_offset_x", 3)
	subtitle_label.add_theme_constant_override("shadow_offset_y", 3)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.modulate.a = 0.0 # Invisible para animación
	subtitle_container.add_child(subtitle_label)

	# Animación de entrada del subtítulo
	create_subtitle_entrance()

func setup_dynamic_loading_area(parent: Control):
	"""Barra de carga atractiva y dinámica en posición central"""
	var loading_container = Control.new()
	loading_container.anchor_left = 0.5
	loading_container.anchor_right = 0.5
	loading_container.anchor_top = 0.65 # Posición central-inferior
	loading_container.anchor_bottom = 0.65

	var container_width = 700
	loading_container.position = Vector2(-container_width / 2, 0)
	loading_container.size = Vector2(container_width, 120)
	parent.add_child(loading_container)

	# VBox para organizar elementos de carga
	var loading_vbox = VBoxContainer.new()
	loading_vbox.anchor_right = 1.0
	loading_vbox.anchor_bottom = 1.0
	loading_vbox.add_theme_constant_override("separation", 15)
	loading_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	loading_container.add_child(loading_vbox)

	# Etiqueta de estado de carga
	progress_label = Label.new()
	progress_label.text = "Inicializando sistemas..."
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 18)
	progress_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	progress_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	progress_label.add_theme_constant_override("shadow_offset_x", 2)
	progress_label.add_theme_constant_override("shadow_offset_y", 2)
	loading_vbox.add_child(progress_label)

	# Barra de progreso ÉPICA y atractiva
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(600, 12)
	progress_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress_bar.value = 0
	progress_bar.max_value = 100

	# Estilo épico para la barra
	var progress_stylebox = StyleBoxFlat.new()
	progress_stylebox.bg_color = Color(0.2, 0.3, 0.6, 0.8)
	progress_stylebox.border_width_left = 2
	progress_stylebox.border_width_right = 2
	progress_stylebox.border_width_top = 2
	progress_stylebox.border_width_bottom = 2
	progress_stylebox.border_color = Color(0.4, 0.6, 1.0)
	progress_stylebox.corner_radius_top_left = 8
	progress_stylebox.corner_radius_top_right = 8
	progress_stylebox.corner_radius_bottom_left = 8
	progress_stylebox.corner_radius_bottom_right = 8

	loading_vbox.add_child(progress_bar)

	# Porcentaje de carga
	loading_label = Label.new()
	loading_label.text = "0%"
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", 16)
	loading_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	loading_vbox.add_child(loading_label)

func setup_expert_tips_area(parent: Control):
	"""Tips de experto en posición estética lateral"""
	var tips_container = Control.new()
	tips_container.anchor_left = 0.02 # Lateral izquierdo
	tips_container.anchor_right = 0.02
	tips_container.anchor_top = 0.30 # Medio lateral
	tips_container.anchor_bottom = 0.30

	var tips_width = 350
	tips_container.position = Vector2(0, 0)
	tips_container.size = Vector2(tips_width, 200)
	parent.add_child(tips_container)

	# Fondo sutil para los tips
	var tips_bg = StyleBoxFlat.new()
	tips_bg.bg_color = Color(0, 0, 0, 0.4)
	tips_bg.border_width_left = 2
	tips_bg.border_width_right = 2
	tips_bg.border_width_top = 2
	tips_bg.border_width_bottom = 2
	tips_bg.border_color = Color(0.3, 0.7, 1.0, 0.6)
	tips_bg.corner_radius_top_left = 10
	tips_bg.corner_radius_top_right = 10
	tips_bg.corner_radius_bottom_left = 10
	tips_bg.corner_radius_bottom_right = 10

	var tips_panel = Panel.new()
	tips_panel.anchor_right = 1.0
	tips_panel.anchor_bottom = 1.0
	tips_panel.add_theme_stylebox_override("panel", tips_bg)
	tips_container.add_child(tips_panel)

	# Label para tips de experto
	tip_label = Label.new()
	tip_label.text = expert_tips[0]
	tip_label.anchor_left = 0.05
	tip_label.anchor_right = 0.95
	tip_label.anchor_top = 0.1
	tip_label.anchor_bottom = 0.9
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip_label.add_theme_font_size_override("font_size", 14)
	tip_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	tip_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	tip_label.add_theme_constant_override("shadow_offset_x", 1)
	tip_label.add_theme_constant_override("shadow_offset_y", 1)
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tips_panel.add_child(tip_label)

func setup_social_buttons_area(parent: Control):
	"""Botones sociales sobre la línea de copyright"""
	var social_container = Control.new()
	social_container.anchor_left = 0.5
	social_container.anchor_right = 0.5
	social_container.anchor_top = 0.85 # Sobre el copyright
	social_container.anchor_bottom = 0.85

	var social_width = 600
	social_container.position = Vector2(-social_width / 2, 0)
	social_container.size = Vector2(social_width, 50)
	parent.add_child(social_container)

	# HBox para botones
	var buttons_hbox = HBoxContainer.new()
	buttons_hbox.anchor_right = 1.0
	buttons_hbox.anchor_bottom = 1.0
	buttons_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_hbox.add_theme_constant_override("separation", 30)
	social_container.add_child(buttons_hbox)

	# Botón Discord
	discord_button = Button.new()
	discord_button.text = "🎮 Discord"
	discord_button.custom_minimum_size = Vector2(140, 40)
	discord_button.add_theme_font_size_override("font_size", 16)
	discord_button.add_theme_color_override("font_color", Color.WHITE)
	discord_button.flat = true
	discord_button.pressed.connect(_on_discord_pressed)
	buttons_hbox.add_child(discord_button)

	# Botón Twitter
	twitter_button = Button.new()
	twitter_button.text = "🐦 Twitter"
	twitter_button.custom_minimum_size = Vector2(140, 40)
	twitter_button.add_theme_font_size_override("font_size", 16)
	twitter_button.add_theme_color_override("font_color", Color.WHITE)
	twitter_button.flat = true
	twitter_button.pressed.connect(_on_twitter_pressed)
	buttons_hbox.add_child(twitter_button)

	# Botón Opciones
	options_button = Button.new()
	options_button.text = "⚙️ Opciones"
	options_button.custom_minimum_size = Vector2(140, 40)
	options_button.add_theme_font_size_override("font_size", 16)
	options_button.add_theme_color_override("font_color", Color.WHITE)
	options_button.flat = true
	options_button.pressed.connect(_on_options_pressed)
	buttons_hbox.add_child(options_button)

func setup_enhanced_footer_area(parent: Control):
	"""Footer mejorado con versión y licencia GNU GPL v3"""
	var footer_container = Control.new()
	footer_container.anchor_left = 0.5
	footer_container.anchor_right = 0.5
	footer_container.anchor_top = 0.92 # Muy abajo
	footer_container.anchor_bottom = 0.92

	var footer_width = 800
	footer_container.position = Vector2(-footer_width / 2, 0)
	footer_container.size = Vector2(footer_width, 60)
	parent.add_child(footer_container)

	# VBox para organizar footer
	var footer_vbox = VBoxContainer.new()
	footer_vbox.anchor_right = 1.0
	footer_vbox.anchor_bottom = 1.0
	footer_vbox.add_theme_constant_override("separation", 5)
	footer_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_container.add_child(footer_vbox)

	# Versión
	version_label = Label.new()
	version_label.text = "Fishing SiKness v0.1.0 - Pre-Alpha | © 2025 Hecho con ❤️ y Godot 4.4"
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.add_theme_font_size_override("font_size", 12)
	version_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.9))
	version_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	version_label.add_theme_constant_override("shadow_offset_x", 1)
	version_label.add_theme_constant_override("shadow_offset_y", 1)
	footer_vbox.add_child(version_label)

	# Licencia GNU GPL v3
	license_label = Label.new()
	license_label.text = "📜 Licencia: GNU General Public License v3.0 - Software Libre y de Código Abierto"
	license_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	license_label.add_theme_font_size_override("font_size", 10)
	license_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 0.8))
	license_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	license_label.add_theme_constant_override("shadow_offset_x", 1)
	license_label.add_theme_constant_override("shadow_offset_y", 1)
	footer_vbox.add_child(license_label)

# === ANIMACIONES ÉPICAS ===

func create_epic_logo_entrance():
	"""Animación de entrada épica para el logo"""
	if not logo_texture:
		return

	var tween = create_tween()
	tween.set_parallel(true)

	# Fade in
	tween.tween_property(logo_texture, "modulate:a", 1.0, 1.5)

	# Escala épica desde pequeño
	logo_texture.scale = Vector2(0.3, 0.3)
	tween.tween_property(logo_texture, "scale", Vector2(1.0, 1.0), 1.5)
	tween.tween_callback(start_logo_breathing).set_delay(1.5)

func create_subtitle_entrance():
	"""Animación de entrada del subtítulo"""
	if not subtitle_label:
		return

	# Usar timer para delay en lugar de tween_delay
	var timer = Timer.new()
	timer.wait_time = 0.8
	timer.one_shot = true
	timer.timeout.connect(func():
		var tween = create_tween()
		tween.tween_property(subtitle_label, "modulate:a", 1.0, 1.0)
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

func start_logo_breathing():
	"""Efecto de respiración continuo del logo"""
	if not logo_texture:
		return

	var breathing_tween = create_tween()
	breathing_tween.set_loops()
	breathing_tween.tween_property(logo_texture, "scale", Vector2(1.02, 1.02), 2.5)
	breathing_tween.tween_property(logo_texture, "scale", Vector2(1.0, 1.0), 2.5)

func create_typing_effect():
	"""Efecto de escritura para el subtítulo"""
	# Implementación futura si se desea
	return

func create_fallback_logo(parent: Control, size: Vector2):
	"""Logo de fallback en caso de no encontrar la imagen"""
	var fallback_label = Label.new()
	fallback_label.text = "FISHING\nSIKNESS"
	fallback_label.anchor_right = 1.0
	fallback_label.anchor_bottom = 1.0
	fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback_label.add_theme_font_size_override("font_size", int(size.y / 6))
	fallback_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	fallback_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	fallback_label.add_theme_constant_override("shadow_offset_x", 4)
	fallback_label.add_theme_constant_override("shadow_offset_y", 4)
	parent.add_child(fallback_label)
	logo_texture = fallback_label
