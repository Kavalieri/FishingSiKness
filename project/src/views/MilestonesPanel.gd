class_name MilestonesPanel
extends Control

signal close_requested()

var main_panel: PanelContainer
var milestones_container: VBoxContainer

func _ready():
	setup_ui()
	refresh_display()

func setup_ui():
	# Fondo de menú flotante usando BackgroundManager
	if BackgroundManager:
		BackgroundManager.setup_menu_background(self)
		print("✅ Fondo de menú configurado en MilestonesPanel")
	else:
		setup_fallback_background()

func setup_fallback_background():
	"""Fondo fallback si BackgroundManager no está disponible"""
	var opaque_bg = ColorRect.new()
	opaque_bg.color = Color.BLACK # Negro puro 100% opaco
	opaque_bg.anchor_right = 1.0
	opaque_bg.anchor_bottom = 1.0
	opaque_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	opaque_bg.z_index = -1
	opaque_bg.gui_input.connect(_on_background_clicked)
	add_child(opaque_bg)

	# Panel principal centrado (centrado dinámicamente)
	main_panel = PanelContainer.new()
	main_panel.z_index = 1
	# Asegurar que el panel también tenga fondo opaco
	main_panel.add_theme_color_override("bg_color", Color(0.15, 0.15, 0.15, 1.0))
	add_child(main_panel)

	# Centrado dinámico en _ready
	call_deferred("_center_panel", main_panel)
	call_deferred("_setup_panel_content", main_panel)

func _setup_panel_content(main_panel: PanelContainer):
	"""Configurar el contenido del panel después del centrado"""
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	main_panel.add_child(main_vbox)

	# Título
	var title_hbox = HBoxContainer.new()
	main_vbox.add_child(title_hbox)

	var title = Label.new()
	title.text = "🌟 ÁRBOL DE HABILIDADES"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_hbox.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "❌"
	close_btn.custom_minimum_size = Vector2(48, 48)
	close_btn.pressed.connect(_on_close_pressed)
	title_hbox.add_child(close_btn)

	# Información actual del skill tree
	var current_info = create_current_skill_info()
	main_vbox.add_child(current_info)

	# Separador
	var separator = HSeparator.new()
	main_vbox.add_child(separator)

	# Scroll para skills
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	milestones_container = VBoxContainer.new()
	milestones_container.add_theme_constant_override("separation", 15)
	scroll.add_child(milestones_container)

func create_current_skill_info() -> VBoxContainer:
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 8)

	# Nivel actual y puntos de skill
	var level_hbox = HBoxContainer.new()
	info_vbox.add_child(level_hbox)

	var current_level = Experience.current_level if Experience else Save.game_data.get("level", 1)
	var level_label = Label.new()
	level_label.text = "🎯 Nivel: %d" % current_level
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_hbox.add_child(level_label)

	var available_points = SkillTree.get_available_skill_points()
	var points_label = Label.new()
	points_label.text = "✨ Puntos: %d" % available_points
	points_label.add_theme_font_size_override("font_size", 18)
	if available_points > 0:
		points_label.add_theme_color_override("font_color", Color.GOLD)
	else:
		points_label.add_theme_color_override("font_color", Color.GRAY)
	level_hbox.add_child(points_label)

	# Barra de progreso XP para próximo skill point
	if Experience:
		var progress_info = Experience.get_xp_progress()
		var levels_to_next_point = 5 - (current_level % 5)
		if levels_to_next_point == 5:
			levels_to_next_point = 0

		var next_point_label = Label.new()
		if levels_to_next_point > 0:
			next_point_label.text = "⏳ %d niveles para próximo punto de skill" % levels_to_next_point
		else:
			next_point_label.text = "🎉 ¡Punto de skill disponible!"
		next_point_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		next_point_label.add_theme_font_size_override("font_size", 14)
		if levels_to_next_point == 0:
			next_point_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
		else:
			next_point_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)
		info_vbox.add_child(next_point_label)

		var xp_bar = ProgressBar.new()
		xp_bar.custom_minimum_size.y = 15
		xp_bar.value = progress_info.percentage * 100
		xp_bar.show_percentage = false
		info_vbox.add_child(xp_bar)

	return info_vbox

func refresh_display():
	# Limpiar skills existentes
	for child in milestones_container.get_children():
		child.queue_free()

	# Mostrar skills por tiers
	var skills_by_tier = SkillTree.get_skills_by_tier()
	var sorted_tiers = skills_by_tier.keys()
	sorted_tiers.sort()

	for tier in sorted_tiers:
		# Título del tier
		var tier_title = Label.new()
		tier_title.text = "🏆 Tier %d" % tier
		tier_title.add_theme_font_size_override("font_size", 20)
		tier_title.add_theme_color_override("font_color", get_tier_color(tier))
		tier_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		milestones_container.add_child(tier_title)

		# Grid para las skills del tier
		var tier_grid = GridContainer.new()
		tier_grid.columns = 2
		tier_grid.add_theme_constant_override("h_separation", 15)
		tier_grid.add_theme_constant_override("v_separation", 10)
		milestones_container.add_child(tier_grid)

		# Agregar skills del tier
		for skill_info in skills_by_tier[tier]:
			create_skill_card(tier_grid, skill_info.id, skill_info.data)

		# Separador entre tiers
		if tier < sorted_tiers.max():
			var separator = HSeparator.new()
			separator.custom_minimum_size.y = 15
			milestones_container.add_child(separator)

func get_tier_color(tier: int) -> Color:
	match tier:
		1: return Color.LIGHT_GREEN
		2: return Color.CYAN
		3: return Color.GOLD
		_: return Color.WHITE

func create_skill_card(parent: Control, skill_id: String, skill_data: Dictionary):
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 120)
	parent.add_child(card)

	var is_unlocked = SkillTree.is_skill_unlocked(skill_id)
	var can_unlock = SkillTree.can_unlock_skill(skill_id)

	# Fondo de la carta según estado
	if is_unlocked:
		card.add_theme_color_override("bg_color", Color(0, 0.4, 0, 0.3))
	elif can_unlock:
		card.add_theme_color_override("bg_color", Color(0.4, 0.4, 0, 0.3))
	else:
		card.add_theme_color_override("bg_color", Color(0.2, 0.2, 0.2, 0.3))

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
	cost_label.text = "💎 %d" % skill_data.cost
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

func get_past_milestones(current_level: int, count: int) -> Array:
	var past_milestones = []
	var all_milestones = Experience.milestones

	for milestone_level in all_milestones.keys():
		if milestone_level <= current_level:
			past_milestones.append({
				"level": milestone_level,
				"info": all_milestones[milestone_level]
			})

	past_milestones.sort_custom(func(a, b): return a.level > b.level)
	return past_milestones.slice(0, count)

func create_milestone_card(level: int, info: Dictionary, completed: bool):
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 80)
	milestones_container.add_child(card)

	var card_hbox = HBoxContainer.new()
	card_hbox.add_theme_constant_override("separation", 15)
	card.add_child(card_hbox)

	# Icono y nivel
	var level_vbox = VBoxContainer.new()
	level_vbox.custom_minimum_size.x = 80
	card_hbox.add_child(level_vbox)

	var level_label = Label.new()
	level_label.text = "📈 Nivel %d" % level
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_vbox.add_child(level_label)

	var status_icon = Label.new()
	status_icon.add_theme_font_size_override("font_size", 24)
	status_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if completed:
		status_icon.text = "✅"
		status_icon.add_theme_color_override("font_color", Color.LIGHT_GREEN)
		card.add_theme_color_override("bg_color", Color(0, 0.3, 0, 0.3))
	else:
		status_icon.text = "⏳"
		status_icon.add_theme_color_override("font_color", Color.ORANGE)
		card.add_theme_color_override("bg_color", Color(0.3, 0.3, 0, 0.3))

	level_vbox.add_child(status_icon)

	# Descripción del bonus
	var desc_vbox = VBoxContainer.new()
	desc_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_hbox.add_child(desc_vbox)

	var desc_label = Label.new()
	desc_label.text = info.get("desc", "Sin descripción")
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_vbox.add_child(desc_label)

	var type_label = Label.new()
	type_label.text = "Tipo: %s | Valor: %s" % [info.get("type", ""), str(info.get("value", ""))]
	type_label.add_theme_font_size_override("font_size", 12)
	type_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_vbox.add_child(type_label)

func _on_close_pressed():
	if SFX:
		SFX.play_event("click")
	emit_signal("close_requested")
	queue_free()

func _on_background_clicked(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("close_requested")
		queue_free()

func _input(event):
	# Permitir cerrar con ESC
	if event.is_action_pressed("ui_cancel"):
		emit_signal("close_requested")
		queue_free()

func _center_panel(panel: PanelContainer):
	"""Centrar el panel dinámicamente en la pantalla"""
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_size = Vector2(viewport_size.x * 0.9, viewport_size.y * 0.9)

	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	panel.position = (viewport_size - panel_size) / 2

	# Hacer el panel completamente opaco
	panel.modulate = Color(1, 1, 1, 1.0) # 100% opaco
	# Forzar fondo del panel
	panel.add_theme_color_override("bg_color", Color(0.15, 0.15, 0.15, 1.0))

	# Asegurar que está visible
	panel.show()
