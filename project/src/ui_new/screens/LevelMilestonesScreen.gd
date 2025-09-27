class_name LevelMilestonesScreen
extends BaseWindow

# Pantalla de milestones de nivel del jugador

@onready var level_label: Label = %LevelLabel
@onready var xp_progress: ProgressBar = %XPProgress
@onready var xp_label: Label = %XPLabel
@onready var milestones_container: VBoxContainer = %MilestonesContainer

func _setup_content() -> void:
	"""Configurar contenido de la ventana (llamado por BaseWindow)"""
	_setup_screen_content()

func _setup_screen_content() -> void:
	"""Configurar pantalla con datos actuales"""
	if not Experience:
		return
	
	# Sincronizar Experience con Save
	Experience.load_experience()
	
	var current_level = Experience.current_level
	var current_xp = Experience.current_xp
	var xp_progress_data = Experience.get_xp_progress()
	
	level_label.text = "Nivel %d" % current_level
	if xp_progress:
		xp_progress.value = xp_progress_data.percentage * 100
	xp_label.text = "%d XP (-%d para siguiente nivel)" % [xp_progress_data.current_xp, xp_progress_data.required_xp - xp_progress_data.current_xp]
	
	_populate_milestones()

func _populate_milestones() -> void:
	"""Poblar lista de milestones"""
	# Limpiar contenido anterior
	for child in milestones_container.get_children():
		child.queue_free()
	
	var current_level = Experience.current_level
	
	# Mostrar todos los milestones del sistema Experience
	var milestone_levels = Experience.milestones.keys()
	milestone_levels.sort()
	
	for level in milestone_levels:
		var milestone_info = Experience.milestones[level]
		_create_milestone_section(level, [milestone_info], level <= current_level)

func _create_milestone_section(level: int, milestones: Array, unlocked: bool) -> void:
	"""Crear sección de milestone para un nivel"""
	# Panel con fondo
	var panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.8) if unlocked else Color(0.05, 0.05, 0.05, 0.6)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color.GREEN if unlocked else Color.GRAY
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.custom_minimum_size.y = 60
	milestones_container.add_child(panel)
	
	var content = HBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	
	# Icono de estado
	var status_icon = Label.new()
	status_icon.text = "✓" if unlocked else "🔒"
	status_icon.add_theme_font_size_override("font_size", 24)
	status_icon.add_theme_color_override("font_color", Color.GREEN if unlocked else Color.GRAY)
	content.add_child(status_icon)
	
	# Información del milestone
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(info_vbox)
	
	var level_title = Label.new()
	level_title.text = "Nivel %d" % level
	level_title.add_theme_font_size_override("font_size", 18)
	level_title.add_theme_color_override("font_color", Color.WHITE if unlocked else Color.GRAY)
	info_vbox.add_child(level_title)
	
	# Descripción del milestone
	for milestone in milestones:
		var description = Label.new()
		description.text = milestone.get("desc", "Milestone desbloqueado")
		description.add_theme_font_size_override("font_size", 14)
		description.add_theme_color_override("font_color", Color.LIGHT_GRAY if unlocked else Color.GRAY)
		info_vbox.add_child(description)
	
	# Espaciado
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 8
	milestones_container.add_child(spacer)