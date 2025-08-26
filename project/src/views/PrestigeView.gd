class_name PrestigeView
extends Control

signal prestige_confirmed()

var prestige_button: Button
var prestige_info_label: Label
var prestige_benefits_container: VBoxContainer

func _ready():
	setup_prestige_ui()
	# Diferir update_display para después de que se configuren los elementos UI
	call_deferred("update_display")

func setup_prestige_ui():
	# Configurar fondo de menú usando BackgroundManager
	if BackgroundManager:
		BackgroundManager.setup_main_background(self)
		print("✅ Fondo principal configurado en PrestigeView")
	else:
		setup_fallback_background()

	# Crear la UI independientemente del tipo de fondo
	create_ui_elements()

func setup_fallback_background():
	"""Fondo fallback si BackgroundManager no está disponible"""
	var opaque_bg = ColorRect.new()
	opaque_bg.color = Color.BLACK # Negro puro 100% opaco
	opaque_bg.anchor_right = 1.0
	opaque_bg.anchor_bottom = 1.0
	opaque_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	opaque_bg.z_index = -1
	add_child(opaque_bg)

func create_ui_elements():
	"""Crear elementos de UI del prestigio"""
	# Contenedor principal centrado con margen
	var main_container = MarginContainer.new()
	main_container.anchor_left = 0.1
	main_container.anchor_top = 0.1
	main_container.anchor_right = 0.9
	main_container.anchor_bottom = 0.9
	add_child(main_container)

	# VBoxContainer para organizar todo verticalmente
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	main_container.add_child(vbox)

	# Título
	var title_label = Label.new()
	title_label.text = "⭐ PRESTIGIO"
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# Información del prestigio
	prestige_info_label = Label.new()
	prestige_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prestige_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prestige_info_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(prestige_info_label)

	# Beneficios del prestigio
	prestige_benefits_container = VBoxContainer.new()
	prestige_benefits_container.add_theme_constant_override("separation", 10)
	vbox.add_child(prestige_benefits_container)

	# Spacer para empujar el botón hacia abajo
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Botón de prestigio centrado
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_container)

	prestige_button = Button.new()
	prestige_button.text = "🌟 HACER PRESTIGIO"
	prestige_button.custom_minimum_size = Vector2(400, 80)
	prestige_button.add_theme_font_size_override("font_size", 18)
	prestige_button.pressed.connect(_on_prestige_button_pressed)
	button_container.add_child(prestige_button)

func update_display():
	if not prestige_info_label or not is_instance_valid(prestige_info_label):
		print("⚠️ PrestigeView: UI no inicializada aún")
		return

	if not Save.game_data.prestige_unlocked:
		var current_level = Save.game_data.level
		prestige_info_label.text = "🔒 Prestigio desbloqueado en el nivel 75\n" + \
			"Actual: Nivel %d" % current_level
		if prestige_button and is_instance_valid(prestige_button):
			prestige_button.disabled = true
			prestige_button.text = "🔒 PRESTIGIO BLOQUEADO"
		return

	var prestige_level = Save.game_data.get("prestige_level", 0)
	var prestige_points = Save.game_data.get("prestige_points", 0)
	var potential_points = calculate_prestige_points()

	prestige_info_label.text = """⭐ Prestigio Nivel: %d
🎯 Puntos de Prestigio: %d
💫 Puntos potenciales: +%d

El Prestigio reinicia tu progreso pero otorga:
• Multiplicador permanente de monedas
• Puntos de prestigio para mejoras especiales
• Acceso a contenido exclusivo""" % [prestige_level, prestige_points, potential_points]

	prestige_button.disabled = potential_points == 0
	if potential_points > 0:
		prestige_button.text = "🌟 HACER PRESTIGIO (+%d puntos)" % potential_points
	else:
		prestige_button.text = "❌ Sin puntos suficientes"

	update_prestige_benefits()

func update_prestige_benefits():
	# Limpiar beneficios actuales
	for child in prestige_benefits_container.get_children():
		child.queue_free()

	var prestige_level = Save.game_data.get("prestige_level", 0)

	if prestige_level > 0:
		var benefits_title = Label.new()
		benefits_title.text = "🎁 Beneficios Activos:"
		benefits_title.add_theme_font_size_override("font_size", 16)
		prestige_benefits_container.add_child(benefits_title)

		var multiplier = get_prestige_multiplier()
		var benefit_label = Label.new()
		benefit_label.text = "💰 Multiplicador de monedas: x%.2f" % multiplier
		prestige_benefits_container.add_child(benefit_label)

func calculate_prestige_points() -> int:
	var level = Save.game_data.get("level", 1)
	if level < 75:
		return 0

	# Fórmula: puntos = (nivel - 74) / 25
	return max(0, (level - 74) / 25)

func get_prestige_multiplier() -> float:
	var prestige_level = Save.game_data.get("prestige_level", 0)
	return 1.0 + (prestige_level * 0.5) # +50% por cada nivel de prestigio

func _on_prestige_button_pressed():
	var potential_points = calculate_prestige_points()
	if potential_points <= 0:
		return

	# Mostrar confirmación
	show_prestige_confirmation(potential_points)

func show_prestige_confirmation(points: int):
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.title = "⚠️ Confirmación de Prestigio"
	confirm_dialog.dialog_text = """¿Estás seguro de que quieres hacer Prestigio?

ESTO REINICIARÁ:
• Nivel y experiencia
• Monedas y gemas
• Inventario y mejoras
• Progreso de zona

PERO GANARÁS:
• +%d Puntos de Prestigio
• Multiplicador permanente x%.2f
• Acceso a mejoras especiales

¿Continuar?""" % [points, get_prestige_multiplier() + 0.5]

	add_child(confirm_dialog)
	confirm_dialog.confirmed.connect(_perform_prestige.bind(points))
	confirm_dialog.popup_centered()

func _perform_prestige(points: int):
	# Guardar estado pre-prestigio
	var old_prestige_level = Save.game_data.get("prestige_level", 0)
	var old_prestige_points = Save.game_data.get("prestige_points", 0)

	# Resetear progreso
	Save.game_data.experience = 0
	Save.game_data.level = 1
	Save.game_data.coins = 1000
	Save.game_data.gems = 25
	Save.game_data.inventory = []
	Save.game_data.upgrades = {}
	Save.game_data.current_zone = "lake"
	Save.game_data.unlocked_zones = ["lake"]

	# Aplicar beneficios de prestigio
	Save.game_data.prestige_level = old_prestige_level + 1
	Save.game_data.prestige_points = old_prestige_points + points

	Save.save_game()

	# Notificar sistemas
	emit_signal("prestige_confirmed")

	# Actualizar display
	update_display()

	print("Prestigio completado! Nuevo nivel: ", Save.game_data.prestige_level)
