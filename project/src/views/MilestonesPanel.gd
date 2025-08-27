class_name MilestonesPanel
extends BaseWindow

@onready var level_label: Label = %LevelLabel
@onready var points_label: Label = %PointsLabel
@onready var next_point_label: Label = %NextPointLabel
@onready var xp_progress_bar: ProgressBar = %XPProgressBar
@onready var scroll_container: ScrollContainer = %ScrollContainer

func _ready():
	super._ready()
	refresh_display()

func refresh_display():
	_update_header_info()
	_populate_milestones_grid()

func _update_header_info():
	var current_level = Experience.current_level
	var available_points = SkillTree.get_available_skill_points()
	var progress_info = Experience.get_xp_progress()
	var levels_to_next_point = 5 - (current_level % 5)
	if levels_to_next_point == 5: levels_to_next_point = 0

	level_label.text = "🎯 Nivel: %d" % current_level
	points_label.text = "✨ Puntos: %d" % available_points
	points_label.modulate = Color.GOLD if available_points > 0 else Color.GRAY

	if levels_to_next_point > 0:
		next_point_label.text = "⏳ %d niveles para próximo punto de skill" % levels_to_next_point
		next_point_label.modulate = Color.LIGHT_BLUE
	else:
		next_point_label.text = "🎉 ¡Punto de skill disponible!"
		next_point_label.modulate = Color.LIGHT_GREEN

	xp_progress_bar.value = progress_info.percentage * 100

func _populate_milestones_grid():
	# Limpiar el contenedor principal
	for child in scroll_container.get_children():
		child.queue_free()

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(main_vbox)

	# Mostrar skills por tiers
	var skills_by_tier = SkillTree.get_skills_by_tier()
	print("--- SKILLS BY TIER ---")
	for tier in skills_by_tier:
		print("Tier %d:" % tier)
		for skill in skills_by_tier[tier]:
			print("  - %s" % skill.id)
	print("----------------------")

	var sorted_tiers = skills_by_tier.keys()
	sorted_tiers.sort()

	for tier in sorted_tiers:
		# Título del tier
		var tier_title = Label.new()
		tier_title.text = "🏆 Tier %d" % tier
		tier_title.add_theme_font_size_override("font_size", 20)
		tier_title.add_theme_color_override("font_color", get_tier_color(tier))
		tier_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		main_vbox.add_child(tier_title)

		# VBox para las skills del tier (una sola columna)
		var tier_vbox = VBoxContainer.new()
		tier_vbox.add_theme_constant_override("separation", 10)
		tier_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_vbox.add_child(tier_vbox)

		# Agregar skills del tier
		for skill_info in skills_by_tier[tier]:
			create_skill_card(tier_vbox, skill_info.id, skill_info.data)

		# Separador entre tiers
		if tier < sorted_tiers.max():
			var separator = HSeparator.new()
			separator.custom_minimum_size.y = 15
			main_vbox.add_child(separator)

func get_tier_color(tier: int) -> Color:
	match tier:
		1: return Color.LIGHT_GREEN
		2: return Color.CYAN
		3: return Color.GOLD
		_: return Color.WHITE

func create_skill_card(parent: Control, skill_id: String, skill_data: Dictionary):
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 120) # Solo altura mínima, ancho flexible
	parent.add_child(card)

	var is_unlocked = SkillTree.is_skill_unlocked(skill_id)
	var can_unlock = SkillTree.can_unlock_skill(skill_id)

	# Fondo de la carta según estado
	if is_unlocked:
		card.add_theme_stylebox_override("panel", preload("res://art/ui/panel_skill_unlocked.tres"))
	elif can_unlock:
		card.add_theme_stylebox_override("panel", preload("res://art/ui/panel_skill_available.tres"))
	else:
		card.add_theme_stylebox_override("panel", preload("res://art/ui/panel_skill_locked.tres"))

	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 5)
	card.add_child(card_vbox)

	# Header con icono y nombre
	var header_hbox = HBoxContainer.new()
	card_vbox.add_child(header_hbox)

	var icon_label = Label.new()
	icon_label.text = skill_data.icon
	icon_label.add_theme_font_size_override("font_size", 24)
	header_hbox.add_child(icon_label)

	var name_label = Label.new()
	name_label.text = skill_data.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_unlocked:
		name_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	elif can_unlock:
		name_label.add_theme_color_override("font_color", Color.GOLD)
	header_hbox.add_child(name_label)

	var cost_label = Label.new()
	cost_label.text = "✨ %d" % skill_data.cost # Mostrar coste en puntos de skill
	cost_label.add_theme_font_size_override("font_size", 14)
	if is_unlocked:
		cost_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	elif can_unlock:
		cost_label.add_theme_color_override("font_color", Color.GOLD)
	else:
		cost_label.add_theme_color_override("font_color", Color.GRAY)
	header_hbox.add_child(cost_label)

	# Descripción
	var desc_label = Label.new()
	desc_label.text = skill_data.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not is_unlocked and not can_unlock:
		desc_label.add_theme_color_override("font_color", Color.GRAY)
	card_vbox.add_child(desc_label)

	# Estado y botón
	var bottom_hbox = HBoxContainer.new()
	card_vbox.add_child(bottom_hbox)

	var status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(status_label)

	if is_unlocked:
		status_label.text = "✅ Desbloqueada"
		status_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	elif can_unlock:
		status_label.text = "⚡ Disponible"
		status_label.add_theme_color_override("font_color", Color.GOLD)

		# Botón para desbloquear
		var unlock_btn = Button.new()
		unlock_btn.text = "DESBLOQUEAR"
		unlock_btn.custom_minimum_size = Vector2(120, 30)
		unlock_btn.pressed.connect(_on_skill_unlock_pressed.bind(skill_id))
		bottom_hbox.add_child(unlock_btn)
	else:
		# Verificar prerequisitos
		var prereq_text = ""
		for prereq in skill_data.prerequisites:
			if not SkillTree.is_skill_unlocked(prereq):
				var prereq_info = SkillTree.get_skill_info(prereq)
				prereq_text += prereq_info.get("name", prereq) + ", "

		if prereq_text != "":
			prereq_text = prereq_text.trim_suffix(", ")
			status_label.text = "🔒 Requiere: " + prereq_text
		else:
			status_label.text = "🔒 Sin puntos disponibles"
		status_label.add_theme_color_override("font_color", Color.GRAY)

func _on_skill_unlock_pressed(skill_id: String):
	if SkillTree.unlock_skill(skill_id):
		if SFX:
			SFX.play_event("skill_unlock")
		refresh_display()
		print("Skill unlocked: ", skill_id)
