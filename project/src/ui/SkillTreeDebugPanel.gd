class_name SkillTreeDebugPanel
extends Control

# Panel de debug para testing del Skill Tree
# Accesible desde el juego para probar funcionamiento

var debug_container: VBoxContainer

func _ready():
	visible = false
	setup_debug_ui()

func setup_debug_ui():
	# Fondo semi-transparente
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.9)
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)

	# Panel principal
	var main_panel = PanelContainer.new()
	main_panel.anchor_left = 0.1
	main_panel.anchor_right = 0.9
	main_panel.anchor_top = 0.1
	main_panel.anchor_bottom = 0.9
	add_child(main_panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	main_panel.add_child(main_vbox)

	# Título
	var title = Label.new()
	title.text = "🔧 DEBUG SKILL TREE"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)

	# Información actual
	var info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(info_label)
	update_info_display()

	# Separador
	var separator = HSeparator.new()
	main_vbox.add_child(separator)

	# Controles de debug
	debug_container = VBoxContainer.new()
	debug_container.add_theme_constant_override("separation", 5)
	main_vbox.add_child(debug_container)

	create_debug_controls()

	# Botón cerrar
	var close_btn = Button.new()
	close_btn.text = "CERRAR"
	close_btn.pressed.connect(_on_close_pressed)
	main_vbox.add_child(close_btn)

func create_debug_controls():
	# Controles de nivel
	var level_hbox = HBoxContainer.new()
	debug_container.add_child(level_hbox)

	level_hbox.add_child(Label.new())
	level_hbox.get_child(-1).text = "Nivel:"

	var level_btn_minus = Button.new()
	level_btn_minus.text = "-"
	level_btn_minus.custom_minimum_size = Vector2(40, 40)
	level_btn_minus.pressed.connect(_on_level_changed.bind(-1))
	level_hbox.add_child(level_btn_minus)

	var level_btn_plus = Button.new()
	level_btn_plus.text = "+"
	level_btn_plus.custom_minimum_size = Vector2(40, 40)
	level_btn_plus.pressed.connect(_on_level_changed.bind(1))
	level_hbox.add_child(level_btn_plus)

	var level_btn_plus5 = Button.new()
	level_btn_plus5.text = "+5"
	level_btn_plus5.custom_minimum_size = Vector2(50, 40)
	level_btn_plus5.pressed.connect(_on_level_changed.bind(5))
	level_hbox.add_child(level_btn_plus5)

	# Reset skills
	var reset_btn = Button.new()
	reset_btn.text = "RESETEAR TODAS LAS SKILLS"
	reset_btn.pressed.connect(_on_reset_skills)
	debug_container.add_child(reset_btn)

	# === SECCIÓN NUEVO SISTEMA DE VENTANAS ===
	var separator2 = HSeparator.new()
	debug_container.add_child(separator2)

	var windows_title = Label.new()
	windows_title.text = "🪟 NUEVO SISTEMA DE VENTANAS (TESTING)"
	windows_title.add_theme_font_size_override("font_size", 16)
	windows_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debug_container.add_child(windows_title)

	

	

	# Estado del FloatingWindowManager
	var manager_status = Label.new()
	manager_status.name = "ManagerStatus"
	manager_status.add_theme_font_size_override("font_size", 12)
	manager_status.modulate = Color.YELLOW
	update_manager_status(manager_status)
	debug_container.add_child(manager_status)

	# Desbloquear todas las skills tier 1
	var unlock_t1_btn = Button.new()
	unlock_t1_btn.text = "DESBLOQUEAR TIER 1"
	unlock_t1_btn.pressed.connect(_on_unlock_tier.bind(1))
	debug_container.add_child(unlock_t1_btn)

	# Test de bonificaciones
	var test_bonuses_btn = Button.new()
	test_bonuses_btn.text = "MOSTRAR BONIFICACIONES ACTIVAS"
	test_bonuses_btn.pressed.connect(_on_test_bonuses)
	debug_container.add_child(test_bonuses_btn)

func _on_level_changed(delta: int):
	var current_level = Save.game_data.get("level", 1)
	var new_level = max(1, current_level + delta)
	Save.game_data["level"] = new_level
	Save.save_game()

	# También actualizar Experience si existe
	if Experience:
		Experience.current_level = new_level
		Experience.calculate_experience_for_level(new_level)

	update_info_display()
	print("Level changed to: ", new_level)

func _on_reset_skills():
	if SkillTree:
		SkillTree.reset_all_skills()
	update_info_display()
	print("All skills reset")

func _on_unlock_tier(tier: int):
	if not SkillTree:
		return

	var skills_by_tier = SkillTree.get_skills_by_tier()
	if not skills_by_tier.has(tier):
		return

	for skill_info in skills_by_tier[tier]:
		if SkillTree.can_unlock_skill(skill_info.id):
			SkillTree.unlock_skill(skill_info.id)

	update_info_display()
	print("Tier %d skills unlocked" % tier)

func _on_test_bonuses():
	if not SkillTree:
		print("SkillTree not available")
		return

	print("=== BONIFICACIONES ACTIVAS ===")
	print("Velocidad de pesca: x", SkillTree.get_active_bonus("fishing_speed"))
	print("Probabilidad de raros: x", SkillTree.get_active_bonus("rare_chance"))
	print("Valor de venta: x", SkillTree.get_active_bonus("sell_bonus"))
	print("Inventario máximo: ", SkillTree.get_max_inventory_with_bonus())
	print("===")

	print("=== BONIFICACIONES DESDE SAVE ===")
	print("Multiplicador de monedas: x", Save.get_coins_multiplier())
	print("Inventario total: ", Save.get_total_inventory_capacity())
	print("Velocidad de pesca: x", Save.get_fishing_speed_multiplier())
	print("Probabilidad de raros: x", Save.get_rare_fish_chance_multiplier())
	print("===")

func update_info_display():
	var info_label = get_node_or_null("PanelContainer/VBoxContainer/InfoLabel")
	if not info_label:
		info_label = get_node_or_null("InfoLabel") # Búsqueda alternativa

	if not info_label:
		return

	var current_level = Save.game_data.get("level", 1)
	var available_points = 0
	var spent_points = 0
	var unlocked_count = 0

	if SkillTree:
		available_points = SkillTree.get_available_skill_points()
		spent_points = SkillTree.get_spent_skill_points()
		var unlocked_skills = Save.game_data.get("unlocked_skills", {})
		for skill_id in unlocked_skills:
			if unlocked_skills[skill_id]:
				unlocked_count += 1

	info_label.text = "Nivel: %d | Puntos: %d/%d | Skills: %d" % [
		current_level, available_points, available_points + spent_points, unlocked_count
	]

func _on_close_pressed():
	visible = false

func _input(event):
	# F2 para toggle debug
	if event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		visible = not visible
		if visible:
			update_info_display()
		get_viewport().set_input_as_handled()



func update_manager_status(status_label: Label):
	"""Actualizar estado del FloatingWindowManager"""
	if FloatingWindowManager:
		var window_count = FloatingWindowManager.window_stack.size()
		status_label.text = "✅ FloatingWindowManager OK | Ventanas: %d" % window_count
		status_label.modulate = Color.GREEN
	else:
		status_label.text = "❌ FloatingWindowManager NO DISPONIBLE"
		status_label.modulate = Color.RED
