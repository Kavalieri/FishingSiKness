extends VBoxContainer

signal open_requested(alias: String)

@onready var btn_money: Button = $Row1/BtnMoney
@onready var btn_gems: Button = $Row1/BtnGems
@onready var btn_zone: Button = $Row1/BtnZone
@onready var btn_level: Button = $Row2/BtnLevel
@onready var xp_bar: ProgressBar = $Row2/XPBlock/XPBar
@onready var btn_xp: Button = $Row2/XPBlock/BtnXP
@onready var btn_options: Button = $Row1/BtnOptions

func _ready() -> void:
	# Configurar estilos profesionales
	setup_professional_styles()

	# Tooltips (desktop); móvil usa long-press si lo implementas fuera
	btn_money.tooltip_text = tr("Dinero. Toca para ver detalles.")
	btn_gems.tooltip_text = tr("Diamantes. Tienda.")
	btn_zone.tooltip_text = tr("Zona actual.")
	btn_level.tooltip_text = tr("Nivel de jugador.")
	btn_xp.tooltip_text = tr("Progreso hacia el siguiente nivel.")
	btn_options.tooltip_text = tr("Opciones")

	# Botones → solicitud de apertura (WindowManager decide ventana real)
	btn_money.pressed.connect(func(): emit_signal("open_requested", "money"))
	btn_gems.pressed.connect(func(): emit_signal("open_requested", "diamonds"))
	btn_zone.pressed.connect(func(): emit_signal("open_requested", "zone"))
	btn_level.pressed.connect(func(): emit_signal("open_requested", "level"))
	btn_xp.pressed.connect(func(): emit_signal("open_requested", "xp"))
	btn_options.pressed.connect(func(): emit_signal("open_requested", "options"))

	# Connect to Save and Experience autoloads
	if Save:
		Save.coins_changed.connect(set_money)
		Save.gems_changed.connect(set_diamonds)
		Save.data_loaded.connect(func(_slot): sync_from_state(Save, Experience)) # Update on game load
		# Zone updates will be handled by ScreenManager calling set_zone directly
	if Experience:
		Experience.level_up.connect(_on_experience_level_up)
	# Initial sync
	if Save and Experience:
		sync_from_state(Save, Experience)

# ---- setters públicos (para wiring externo si no usas self‑wiring) ----
func set_money(v: int) -> void:
	btn_money.text = "🪙 " + _fmt_money(v)

func set_diamonds(v: int) -> void:
	btn_gems.text = "💎 " + str(v)

func set_zone(name: String) -> void:
	btn_zone.text = "🌊 " + name

func set_level(l: int) -> void:
	btn_level.text = "📊 Nivel " + str(l)

func set_xp(current: int, required: int) -> void:
	var p := float(current) / float(required) if required > 0 else 0.0
	xp_bar.value = clampf(p * 100.0, 0.0, 100.0)
	xp_bar.tooltip_text = "%d / %d XP (%.0f%%)" % [current, required, xp_bar.value]
	btn_xp.text = "⭐ XP"

func sync_from_state(save_data: Node, experience_data: Node) -> void:
	set_money(save_data.get_coins())
	set_diamonds(save_data.get_gems())
	set_zone(save_data._get_zone_display_name(save_data.game_data.current_zone))
	set_level(experience_data.current_level)
	var xp_progress = experience_data.get_xp_progress()
	set_xp(xp_progress.current_xp, xp_progress.required_xp)

func _on_experience_level_up(new_level: int) -> void:
	set_level(new_level)
	var xp_progress = Experience.get_xp_progress()
	set_xp(xp_progress.current_xp, xp_progress.required_xp)

func setup_professional_styles() -> void:
	"""Configurar estilos visuales profesionales para cada botón"""
	# Estilo para botón de dinero (dorado)
	_setup_button_style(btn_money, Color(1.0, 0.84, 0.0), Color(0.8, 0.6, 0.0))

	# Estilo para botón de gemas (azul cristal)
	_setup_button_style(btn_gems, Color(0.4, 0.8, 1.0), Color(0.2, 0.6, 0.8))

	# Estilo para botón de zona (verde agua)
	_setup_button_style(btn_zone, Color(0.2, 0.8, 0.6), Color(0.1, 0.6, 0.4))

	# Estilo para botón de opciones (gris)
	_setup_button_style(btn_options, Color(0.7, 0.7, 0.7), Color(0.5, 0.5, 0.5))

	# Estilo para botón de nivel (violeta)
	_setup_button_style(btn_level, Color(0.8, 0.4, 0.9), Color(0.6, 0.2, 0.7))

	# Estilo para botón de XP (naranja)
	_setup_button_style(btn_xp, Color(1.0, 0.6, 0.2), Color(0.8, 0.4, 0.1))

	# Estilo especial para la barra de XP
	_setup_xp_bar_style()

func _setup_button_style(button: Button, base_color: Color, accent_color: Color) -> void:
	"""Configurar estilo individual para un botón"""
	if not button:
		return

	# Configurar fuente
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	button.add_theme_constant_override("shadow_offset_x", 1)
	button.add_theme_constant_override("shadow_offset_y", 1)

	# Crear estilo de fondo normal
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = base_color
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_color = accent_color
	normal_style.content_margin_left = 12
	normal_style.content_margin_right = 12
	normal_style.content_margin_top = 6
	normal_style.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", normal_style)

	# Crear estilo hover
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(base_color.r * 1.2, base_color.g * 1.2, base_color.b * 1.2)
	hover_style.border_color = Color(accent_color.r * 1.3, accent_color.g * 1.3, accent_color.b * 1.3)
	button.add_theme_stylebox_override("hover", hover_style)

	# Crear estilo pressed
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(base_color.r * 0.8, base_color.g * 0.8, base_color.b * 0.8)
	pressed_style.border_color = accent_color
	pressed_style.content_margin_top = 8
	pressed_style.content_margin_bottom = 4
	button.add_theme_stylebox_override("pressed", pressed_style)

func _setup_xp_bar_style() -> void:
	"""Configurar estilo profesional para la barra de XP"""
	if not xp_bar:
		return

	# Fondo de la barra
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	bg_style.corner_radius_top_left = 6
	bg_style.corner_radius_top_right = 6
	bg_style.corner_radius_bottom_left = 6
	bg_style.corner_radius_bottom_right = 6
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_color = Color(0.4, 0.4, 0.5)
	xp_bar.add_theme_stylebox_override("background", bg_style)

	# Relleno de la barra (gradiente dorado-verde)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0.9, 0.2) # Verde-amarillo experiencia
	fill_style.corner_radius_top_left = 5
	fill_style.corner_radius_top_right = 5
	fill_style.corner_radius_bottom_left = 5
	fill_style.corner_radius_bottom_right = 5
	xp_bar.add_theme_stylebox_override("fill", fill_style)

# ---- utilidades ----
func _fmt_money(n: int) -> String:
	var f := float(n)
	if f >= 1_000_000_000.0: return "%.2fB" % (f / 1_000_000_000.0)
	if f >= 1_000_000.0: return "%.2fM" % (f / 1_000_000.0)
	if f >= 1_000.0: return "%.2fK" % (f / 1_000.0)
	return str(n)
