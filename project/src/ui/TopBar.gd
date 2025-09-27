extends VBoxContainer

signal open_requested(alias: String)

@onready var btn_money: Button = $MainContainer/ContentVBox/Row1/MoneyGemsBlock/BtnMoney
@onready var btn_gems: Button = $MainContainer/ContentVBox/Row1/MoneyGemsBlock/BtnGems
@onready var btn_zone: Button = $MainContainer/ContentVBox/Row1/ZoneBlock/BtnZone
@onready var btn_social: Button = $MainContainer/ContentVBox/Row1/SocialOptionsBlock/BtnSocial
@onready var btn_options: Button = $MainContainer/ContentVBox/Row1/SocialOptionsBlock/BtnOptions
@onready var xp_progress_button: Button = $MainContainer/ContentVBox/Row2/XPProgressButton

func _ready() -> void:
	# Configurar estilos profesionales mejorados
	setup_professional_styles()

	# Añadir iconos PNG a los botones
	_setup_button_icons()

	# Habilitar tooltips útiles y necesarios
	btn_money.tooltip_text = tr("Dinero disponible - Click para ir al Mercado")
	btn_gems.tooltip_text = tr("Gemas premium - Click para la Tienda")
	btn_zone.tooltip_text = tr("Zona de pesca actual - Click para cambiar zona")
	btn_options.tooltip_text = tr("Configuración del juego")
	btn_social.tooltip_text = tr("Redes sociales - Síguenos y comparte")
	xp_progress_button.tooltip_text = tr("Progreso de experiencia - Click para habilidades")

	# Botones → solicitud de apertura (WindowManager decide ventana real)
	btn_money.pressed.connect(func(): emit_signal("open_requested", "money"))
	btn_gems.pressed.connect(func(): emit_signal("open_requested", "diamonds"))
	btn_zone.pressed.connect(func(): emit_signal("open_requested", "zone"))
	btn_options.pressed.connect(func(): emit_signal("open_requested", "options"))
	btn_social.pressed.connect(func(): emit_signal("open_requested", "social"))
	xp_progress_button.pressed.connect(func(): emit_signal("open_requested", "xp")) # Conectar con autoloads para datos en tiempo real
	if Save:
		Save.coins_changed.connect(set_money)
		Save.gems_changed.connect(set_diamonds)
		Save.data_loaded.connect(func(_slot): sync_from_state(Save, Experience))
		# Zone updates will be handled by ScreenManager calling set_zone directly

	if Experience:
		Experience.level_up.connect(_on_experience_level_up)
		# Conectar a una señal personalizada si es necesaria para cambios de XP
		if Experience.has_signal("experience_changed"):
			Experience.experience_changed.connect(_on_experience_changed)

	# Initial sync
	if Save and Experience:
		sync_from_state(Save, Experience)

func _setup_button_icons() -> void:
	"""Los iconos ahora se configuran directamente en el .tscn - método simplificado"""
	# Configurar solo los iconos que necesitan lógica especial
	btn_options.text = "" # Sin texto, solo icono para el botón de opciones
	btn_social.text = "" # Sin texto, solo icono para el botón social

	# Los iconos principales (coins, diamonds, zones-map, xp) mantienen tanto icono como texto
	# Esto se define directamente en el .tscn para mejor rendimiento y simplicidad

	print("INFO IconOS configurados desde .tscn - TopBar profesionalizada")

# ---- setters públicos (para wiring externo si no usas self‑wiring) ----
func set_money(v: int) -> void:
	btn_money.text = _fmt_money(v)

func set_diamonds(v: int) -> void:
	btn_gems.text = str(v)

func set_zone(name: String) -> void:
	btn_zone.text = name

func set_xp_progress(level: int, current: int, required: int) -> void:
	var text = "Nivel %d - %d / %d XP" % [level, current, required]
	xp_progress_button.text = text

	# Actualizar tooltip con más información (deshabilitado temporalmente)
	var percentage = (float(current) / float(required)) * 100.0 if required > 0 else 0.0
	# xp_progress_button.tooltip_text = tr("Nivel %d\nProgreso: %d / %d XP (%.1f%%)\nClick para ver habilidades y progreso") % [level, current, required, percentage]

func sync_from_state() -> void:
	if Save:
		set_money(Save.get_coins())
		set_diamonds(Save.get_gems())
		set_zone(Save._get_zone_display_name(Save.game_data.current_zone))

	if Experience:
		# Asegurar que Experience esté sincronizado con Save
		Experience.load_experience()
		var level = Experience.current_level
		var xp_progress = Experience.get_xp_progress()
		set_xp_progress(level, xp_progress.current_xp, xp_progress.required_xp)

func _on_level_up(new_level: int) -> void:
	sync_from_state()

func _on_experience_changed(current_xp: int, current_level: int) -> void:
	sync_from_state()

func setup_professional_styles() -> void:
	"""Configurar estilos visuales profesionales mejorados con fuentes más grandes"""
	# Configurar tamaños de fuente más grandes (20px en lugar de 14px)
	var font_size = 20

	# Estilo para botón de dinero (dorado más intenso)
	_setup_button_style(btn_money, Color(1.0, 0.84, 0.0), Color(0.8, 0.6, 0.0), font_size)

	# Estilo para botón de gemas (azul cristal más vibrante)
	_setup_button_style(btn_gems, Color(0.4, 0.8, 1.0), Color(0.2, 0.6, 0.8), font_size)

	# Estilo para botón de zona (verde agua más prominente)
	_setup_button_style(btn_zone, Color(0.2, 0.8, 0.6), Color(0.1, 0.6, 0.4), font_size)

	# Estilo para botón de opciones (gris más definido)
	_setup_button_style(btn_options, Color(0.7, 0.7, 0.7), Color(0.5, 0.5, 0.5), font_size)

	# Estilo especial para el botón de progreso XP (gradiente experiencia)
	_setup_xp_progress_button_style()

func _setup_button_style(button: Button, base_color: Color, accent_color: Color, font_size: int = 20) -> void:
	"""Configurar estilo individual mejorado para un botón con fuentes más grandes"""
	if not button:
		return

	# Configurar fuente más grande y prominente
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)

	# Crear estilo de fondo normal con bordes más gruesos
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = base_color
	normal_style.corner_radius_top_left = 10
	normal_style.corner_radius_top_right = 10
	normal_style.corner_radius_bottom_left = 10
	normal_style.corner_radius_bottom_right = 10
	normal_style.border_width_top = 3
	normal_style.border_width_bottom = 3
	normal_style.border_width_left = 3
	normal_style.border_width_right = 3
	normal_style.border_color = accent_color
	normal_style.content_margin_left = 15
	normal_style.content_margin_right = 15
	normal_style.content_margin_top = 8
	normal_style.content_margin_bottom = 8
	button.add_theme_stylebox_override("normal", normal_style)

	# Crear estilo hover más dramático
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(base_color.r * 1.3, base_color.g * 1.3, base_color.b * 1.3)
	hover_style.border_color = Color(accent_color.r * 1.4, accent_color.g * 1.4, accent_color.b * 1.4)
	button.add_theme_stylebox_override("hover", hover_style)

	# Crear estilo pressed más pronunciado
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(base_color.r * 0.7, base_color.g * 0.7, base_color.b * 0.7)
	pressed_style.border_color = accent_color
	pressed_style.content_margin_top = 10
	pressed_style.content_margin_bottom = 6
	button.add_theme_stylebox_override("pressed", pressed_style)

func _setup_xp_progress_button_style() -> void:
	"""Configurar estilo especial para el botón de progreso XP con barra de progreso visual"""
	if not xp_progress_button:
		return

	# Configurar fuente más grande
	xp_progress_button.add_theme_font_size_override("font_size", 18)
	xp_progress_button.add_theme_color_override("font_color", Color.WHITE)
	xp_progress_button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	xp_progress_button.add_theme_constant_override("shadow_offset_x", 2)
	xp_progress_button.add_theme_constant_override("shadow_offset_y", 2)

	# Crear estilo que simule una barra de progreso
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.15, 0.4) # Fondo púrpura oscuro para experiencia
	normal_style.corner_radius_top_left = 12
	normal_style.corner_radius_top_right = 12
	normal_style.corner_radius_bottom_left = 12
	normal_style.corner_radius_bottom_right = 12
	normal_style.border_width_top = 3
	normal_style.border_width_bottom = 3
	normal_style.border_width_left = 3
	normal_style.border_width_right = 3
	normal_style.border_color = Color(0.6, 0.4, 0.8) # Borde púrpura claro
	normal_style.content_margin_left = 20
	normal_style.content_margin_right = 20
	normal_style.content_margin_top = 10
	normal_style.content_margin_bottom = 10
	xp_progress_button.add_theme_stylebox_override("normal", normal_style)

	# Estilo hover
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.2, 0.5)
	hover_style.border_color = Color(0.7, 0.5, 0.9)
	xp_progress_button.add_theme_stylebox_override("hover", hover_style)

	# Estilo pressed
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.15, 0.1, 0.3)
	pressed_style.content_margin_top = 12
	pressed_style.content_margin_bottom = 8
	xp_progress_button.add_theme_stylebox_override("pressed", pressed_style)

# ---- utilidades ----
func _fmt_money(n: int) -> String:
	var f := float(n)
	if f >= 1_000_000_000.0: return "%.2fB" % (f / 1_000_000_000.0)
	if f >= 1_000_000.0: return "%.2fM" % (f / 1_000_000.0)
	if f >= 1_000.0: return "%.2fK" % (f / 1_000.0)
	return str(n)
