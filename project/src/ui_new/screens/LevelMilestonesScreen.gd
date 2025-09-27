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
	var section = VBoxContainer.new()
	milestones_container.add_child(section)
	
	# Header del nivel
	var header = HBoxContainer.new()
	section.add_child(header)
	
	var status_icon = Label.new()
	status_icon.text = "OK" if unlocked else "LOCK"
	status_icon.add_theme_font_size_override("font_size", 16)
	status_icon.add_theme_color_override("font_color", Color.GREEN if unlocked else Color.GRAY)
	header.add_child(status_icon)
	
	var level_title = Label.new()
	level_title.text = "Nivel %d" % level
	level_title.add_theme_font_size_override("font_size", 18)
	level_title.modulate = Color.WHITE if unlocked else Color.GRAY
	header.add_child(level_title)
	
	# Milestone del nivel (Experience usa un milestone por nivel)
	for milestone in milestones:
		var milestone_item = HBoxContainer.new()
		section.add_child(milestone_item)
		
		var bullet = Label.new()
		bullet.text = "  - "
		bullet.modulate = Color.WHITE if unlocked else Color.GRAY
		milestone_item.add_child(bullet)
		
		var description = Label.new()
		description.text = milestone.get("desc", "Milestone desbloqueado")
		description.modulate = Color.WHITE if unlocked else Color.GRAY
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		milestone_item.add_child(description)
		
		if milestone.has("value"):
			var value_label = Label.new()
			var value_text = "+" + str(milestone.value)
			if milestone.type == "coins_multiplier":
				value_text = "+" + str(milestone.value * 100) + "%"
			value_label.text = value_text
			value_label.modulate = Color.LIGHT_GREEN if unlocked else Color.GRAY
			milestone_item.add_child(value_label)
	
	# Separador
	var separator = HSeparator.new()
	separator.modulate = Color(1, 1, 1, 0.3)
	section.add_child(separator)