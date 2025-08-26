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

# Tips de experto
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
	"""Configurar UI de la splash screen - versión limpia"""
	# Fondo splash
	setup_background()

	# Overlay sutil
	var overlay = ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0, 0, 0, 0.25)
	add_child(overlay)

	# Container principal
	var main_container = Control.new()
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	add_child(main_container)

	# Configurar elementos (sin duplicaciones)
	setup_logo_area(main_container) # Logo 1/3 superior
	setup_subtitle_area(main_container) # Subtítulo debajo del logo
	setup_loading_area(main_container) # Barra de carga central
	setup_tips_area(main_container) # Tips centrados y estéticos
	setup_social_buttons(main_container) # Botones sociales
	setup_footer(main_container) # Footer único

func setup_background():
	"""Configurar fondo splash"""
	var background = TextureRect.new()
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

	var splash_texture = load("res://art/env/splash.png")
	if splash_texture:
		background.texture = splash_texture
		print("✅ Splash background cargado")
	else:
		background = ColorRect.new()
		background.anchor_right = 1.0
		background.anchor_bottom = 1.0
		background.color = Color(0.05, 0.15, 0.35)
		print("⚠️ Usando fallback de fondo")

	add_child(background)

func setup_logo_area(parent: Control):
	"""Logo ocupando 1/3 superior con efectos centrados"""
	var logo_container = Control.new()
	logo_container.anchor_left = 0.5
	logo_container.anchor_right = 0.5
	logo_container.anchor_top = 0.08 # Inicio del tercio superior
	logo_container.anchor_bottom = 0.08

	# Tamaño controlado: 1/3 de pantalla
	var viewport_size = get_viewport().get_visible_rect().size
	var logo_size = Vector2(
		min(500, viewport_size.x * 0.6), # 60% del ancho máximo
		min(200, viewport_size.y * 0.25) # 25% de altura = 1/3 superior aprox
	)

	logo_container.position = Vector2(-logo_size.x / 2, 0)
	logo_container.size = logo_size
	parent.add_child(logo_container)

	# Cargar logo
	var logo_resource = load("res://art/logo/logo.png")
	if logo_resource:
		logo_texture = TextureRect.new()
		logo_texture.anchor_left = 0.5
		logo_texture.anchor_right = 0.5
		logo_texture.anchor_top = 0.5
		logo_texture.anchor_bottom = 0.5
		logo_texture.position = Vector2(-logo_size.x / 2, -logo_size.y / 2)
		logo_texture.size = logo_size
		logo_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo_texture.texture = logo_resource
		logo_texture.modulate.a = 0.0 # Invisible para animación
		logo_texture.pivot_offset = logo_size / 2 # CENTRAR PIVOT para efectos
		logo_container.add_child(logo_texture)
		print("✅ Logo cargado - tamaño:", logo_size)

		# Iniciar animaciones centradas
		create_logo_entrance()
	else:
		create_fallback_logo(logo_container, logo_size)

func setup_subtitle_area(parent: Control):
	"""Subtítulo épico debajo del logo"""
	var subtitle_container = Control.new()
	subtitle_container.anchor_left = 0.5
	subtitle_container.anchor_right = 0.5
	subtitle_container.anchor_top = 0.38 # Debajo del logo (1/3 + margen)
	subtitle_container.anchor_bottom = 0.38

	var subtitle_width = 700
	subtitle_container.position = Vector2(-subtitle_width / 2, 0)
	subtitle_container.size = Vector2(subtitle_width, 50)
	parent.add_child(subtitle_container)

	subtitle_label = Label.new()
	subtitle_label.text = "🌊 ¡PREPÁRATE PARA LA AVENTURA DE PESCA MÁS ÉPICA! 🎣"
	subtitle_label.anchor_right = 1.0
	subtitle_label.anchor_bottom = 1.0
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 20)
	subtitle_label.add_theme_color_override("font_color", Color(1, 1, 0.3, 0.95))
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	subtitle_label.add_theme_constant_override("shadow_offset_x", 2)
	subtitle_label.add_theme_constant_override("shadow_offset_y", 2)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.modulate.a = 0.0
	subtitle_container.add_child(subtitle_label)

	# Animación de entrada
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(func():
		var tween = create_tween()
		tween.tween_property(subtitle_label, "modulate:a", 1.0, 1.0)
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

func setup_loading_area(parent: Control):
	"""Barra de carga dinámica central"""
	var loading_container = Control.new()
	loading_container.anchor_left = 0.5
	loading_container.anchor_right = 0.5
	loading_container.anchor_top = 0.65 # Posición central-inferior
	loading_container.anchor_bottom = 0.65

	var container_width = 600
	loading_container.position = Vector2(-container_width / 2, 0)
	loading_container.size = Vector2(container_width, 100)
	parent.add_child(loading_container)

	# VBox para elementos de carga
	var loading_vbox = VBoxContainer.new()
	loading_vbox.anchor_right = 1.0
	loading_vbox.anchor_bottom = 1.0
	loading_vbox.add_theme_constant_override("separation", 10)
	loading_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	loading_container.add_child(loading_vbox)

	# Etiqueta de progreso
	progress_label = Label.new()
	progress_label.text = "Inicializando sistemas..."
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	progress_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	progress_label.add_theme_constant_override("shadow_offset_x", 1)
	progress_label.add_theme_constant_override("shadow_offset_y", 1)
	loading_vbox.add_child(progress_label)

	# Barra de progreso estilizada
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(500, 8)
	progress_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress_bar.value = 0
	progress_bar.max_value = 100
	loading_vbox.add_child(progress_bar)

	# Porcentaje
	loading_label = Label.new()
	loading_label.text = "0%"
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", 14)
	loading_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	loading_vbox.add_child(loading_label)

func setup_tips_area(parent: Control):
	"""Tips de experto centrados y estéticos"""
	var tips_container = Control.new()
	tips_container.anchor_left = 0.5
	tips_container.anchor_right = 0.5
	tips_container.anchor_top = 0.50 # Posición entre subtítulo y carga
	tips_container.anchor_bottom = 0.50

	var tips_width = 600
	tips_container.position = Vector2(-tips_width / 2, 0)
	tips_container.size = Vector2(tips_width, 80)
	parent.add_child(tips_container)

	# Panel con fondo estético
	var tips_bg = StyleBoxFlat.new()
	tips_bg.bg_color = Color(0, 0, 0, 0.4)
	tips_bg.border_width_left = 1
	tips_bg.border_width_right = 1
	tips_bg.border_width_top = 1
	tips_bg.border_width_bottom = 1
	tips_bg.border_color = Color(0.3, 0.7, 1.0, 0.6)
	tips_bg.corner_radius_top_left = 8
	tips_bg.corner_radius_top_right = 8
	tips_bg.corner_radius_bottom_left = 8
	tips_bg.corner_radius_bottom_right = 8

	var tips_panel = Panel.new()
	tips_panel.anchor_right = 1.0
	tips_panel.anchor_bottom = 1.0
	tips_panel.add_theme_stylebox_override("panel", tips_bg)
	tips_container.add_child(tips_panel)

	# Label de tip centrado
	tip_label = Label.new()
	tip_label.text = expert_tips[0]
	tip_label.anchor_left = 0.05
	tip_label.anchor_right = 0.95
	tip_label.anchor_top = 0.1
	tip_label.anchor_bottom = 0.9
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip_label.add_theme_font_size_override("font_size", 14)
	tip_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	tip_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	tip_label.add_theme_constant_override("shadow_offset_x", 1)
	tip_label.add_theme_constant_override("shadow_offset_y", 1)
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tips_panel.add_child(tip_label)

func setup_social_buttons(parent: Control):
	"""Botones sociales únicos"""
	var social_container = Control.new()
	social_container.anchor_left = 0.5
	social_container.anchor_right = 0.5
	social_container.anchor_top = 0.82
	social_container.anchor_bottom = 0.82

	var social_width = 500
	social_container.position = Vector2(-social_width / 2, 0)
	social_container.size = Vector2(social_width, 40)
	parent.add_child(social_container)

	var buttons_hbox = HBoxContainer.new()
	buttons_hbox.anchor_right = 1.0
	buttons_hbox.anchor_bottom = 1.0
	buttons_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_hbox.add_theme_constant_override("separation", 25)
	social_container.add_child(buttons_hbox)

	# Botón Discord
	discord_button = Button.new()
	discord_button.text = "🎮 Discord"
	discord_button.custom_minimum_size = Vector2(120, 35)
	discord_button.add_theme_font_size_override("font_size", 14)
	discord_button.add_theme_color_override("font_color", Color.WHITE)
	discord_button.flat = true
	discord_button.pressed.connect(_on_discord_pressed)
	buttons_hbox.add_child(discord_button)

	# Botón Twitter
	twitter_button = Button.new()
	twitter_button.text = "🐦 Twitter"
	twitter_button.custom_minimum_size = Vector2(120, 35)
	twitter_button.add_theme_font_size_override("font_size", 14)
	twitter_button.add_theme_color_override("font_color", Color.WHITE)
	twitter_button.flat = true
	twitter_button.pressed.connect(_on_twitter_pressed)
	buttons_hbox.add_child(twitter_button)

	# Botón Opciones
	options_button = Button.new()
	options_button.text = "⚙️ Opciones"
	options_button.custom_minimum_size = Vector2(120, 35)
	options_button.add_theme_font_size_override("font_size", 14)
	options_button.add_theme_color_override("font_color", Color.WHITE)
	options_button.flat = true
	options_button.pressed.connect(_on_options_pressed)
	buttons_hbox.add_child(options_button)

func setup_footer(parent: Control):
	"""Footer único con versión y licencia"""
	var footer_container = Control.new()
	footer_container.anchor_left = 0.5
	footer_container.anchor_right = 0.5
	footer_container.anchor_top = 0.92
	footer_container.anchor_bottom = 0.92

	var footer_width = 700
	footer_container.position = Vector2(-footer_width / 2, 0)
	footer_container.size = Vector2(footer_width, 50)
	parent.add_child(footer_container)

	var footer_vbox = VBoxContainer.new()
	footer_vbox.anchor_right = 1.0
	footer_vbox.anchor_bottom = 1.0
	footer_vbox.add_theme_constant_override("separation", 3)
	footer_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_container.add_child(footer_vbox)

	# Versión
	version_label = Label.new()
	version_label.text = "Fishing SiKness v0.1.0 - Pre-Alpha | © 2025 Hecho con ❤️ y Godot 4.4"
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.add_theme_font_size_override("font_size", 11)
	version_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.9))
	footer_vbox.add_child(version_label)

	# Licencia
	license_label = Label.new()
	license_label.text = "📜 GNU General Public License v3.0 - Software Libre"
	license_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	license_label.add_theme_font_size_override("font_size", 9)
	license_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 0.8))
	footer_vbox.add_child(license_label)

# === SISTEMA DE CARGA ===

func start_loading():
	"""Sistema de carga progresiva"""
	# Timer para tips cada 4 segundos
	var tip_timer = Timer.new()
	tip_timer.timeout.connect(_on_tip_timeout)
	tip_timer.wait_time = 4.0
	tip_timer.autostart = true
	add_child(tip_timer)

	# Timer para progreso de carga
	var loading_timer = Timer.new()
	loading_timer.timeout.connect(_on_loading_timeout)
	loading_timer.wait_time = 0.8
	loading_timer.autostart = true
	add_child(loading_timer)

	# Iniciar primera etapa
	advance_loading_step()

func advance_loading_step():
	"""Avanzar paso de carga"""
	if current_step < loading_steps.size():
		if progress_label:
			progress_label.text = loading_steps[current_step]

		var target_progress = (current_step + 1.0) / loading_steps.size() * 100.0
		animate_progress_bar(target_progress)

		if loading_label:
			loading_label.text = str(int(target_progress)) + "%"

		current_step += 1
		loading_progress = target_progress

		if current_step >= loading_steps.size():
			loading_complete = true
			can_continue = true
			show_continue_prompt()

func animate_progress_bar(target_value: float):
	"""Animar barra de progreso"""
	if not progress_bar:
		return

	var tween = create_tween()
	tween.tween_property(progress_bar, "value", target_value, 0.5)

func show_continue_prompt():
	"""Mostrar prompt de continuación"""
	if progress_label:
		progress_label.text = "¡Sistema listo! Presiona cualquier tecla para continuar..."
		progress_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))

	if loading_label:
		loading_label.text = "100% ✓"
		loading_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))

# === CALLBACKS ===

func _on_tip_timeout():
	"""Cambiar tips de experto"""
	if not tip_label:
		return

	current_tip_index = (current_tip_index + 1) % expert_tips.size()

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(tip_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): tip_label.text = expert_tips[current_tip_index])
	tween.tween_property(tip_label, "modulate:a", 1.0, 0.3)

func _on_loading_timeout():
	"""Timeout de carga progresiva"""
	if not loading_complete:
		advance_loading_step()

# === ANIMACIONES DEL LOGO CENTRADAS ===

func create_logo_entrance():
	"""Animación de entrada con efectos centrados en el pivot"""
	if not logo_texture:
		return

	var tween = create_tween()
	tween.set_parallel(true)

	# Fade in
	tween.tween_property(logo_texture, "modulate:a", 1.0, 1.5)

	# Escala desde el centro (pivot ya está configurado)
	logo_texture.scale = Vector2(0.3, 0.3)
	tween.tween_property(logo_texture, "scale", Vector2(1.0, 1.0), 1.5)

	# Iniciar respiración después de la entrada
	tween.tween_callback(start_logo_breathing)

func start_logo_breathing():
	"""Efecto de respiración continuo centrado"""
	if not logo_texture:
		return

	var breathing_tween = create_tween()
	breathing_tween.set_loops()
	breathing_tween.tween_property(logo_texture, "scale", Vector2(1.02, 1.02), 2.5)
	breathing_tween.tween_property(logo_texture, "scale", Vector2(1.0, 1.0), 2.5)

func create_fallback_logo(parent: Control, size: Vector2):
	"""Logo de fallback"""
	var fallback_label = Label.new()
	fallback_label.text = "FISHING\nSIKNESS"
	fallback_label.anchor_right = 1.0
	fallback_label.anchor_bottom = 1.0
	fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback_label.add_theme_font_size_override("font_size", int(size.y / 6))
	fallback_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	fallback_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	fallback_label.add_theme_constant_override("shadow_offset_x", 3)
	fallback_label.add_theme_constant_override("shadow_offset_y", 3)
	parent.add_child(fallback_label)
	logo_texture = fallback_label

# === BOTONES SOCIALES ===

func _on_discord_pressed():
	"""Abrir Discord"""
	print("🎮 Abriendo Discord...")
	OS.shell_open("https://discord.gg/fishingsikness")

func _on_twitter_pressed():
	"""Abrir Twitter"""
	print("🐦 Abriendo Twitter...")
	OS.shell_open("https://twitter.com/fishingsikness")

func _on_options_pressed():
	"""Opciones durante splash"""
	print("⚙️ Abriendo opciones...")
	if progress_label:
		var original_text = progress_label.text
		progress_label.text = "⚙️ CONFIGURACIONES PRÓXIMAMENTE..."
		var timer = Timer.new()
		timer.wait_time = 2.0
		timer.one_shot = true
		timer.timeout.connect(func():
			progress_label.text = original_text
			timer.queue_free()
		)
		add_child(timer)
		timer.start()

# === ENTRADA DE USUARIO ===

func _input(event):
	"""Manejar entrada del usuario"""
	if loading_complete and can_continue and event.is_pressed():
		if event is InputEventKey or event is InputEventMouseButton:
			emit_signal("splash_finished")
