class_name TopBarUI
extends Control

# TopBar profesional: 2 filas (50/50)
# Fila superior: 3 tercios [dinero+gemas | zona | social+pausa]
# Fila inferior: XP Progress a todo ancho

signal button_pressed(button_type: String)

# Referencias a nodos TopRow (fila superior)
@onready var money_cell: Button = $VBoxContainer/MarginContainer/ContentContainer/TopRow/HBoxContainer/LeftThird/HBoxContainer/MoneyCell
@onready var gems_cell: Button = $VBoxContainer/MarginContainer/ContentContainer/TopRow/HBoxContainer/LeftThird/HBoxContainer/GemsCell
@onready var zone_cell: Button = $VBoxContainer/MarginContainer/ContentContainer/TopRow/HBoxContainer/CenterThird
@onready var social_cell: Button = $VBoxContainer/MarginContainer/ContentContainer/TopRow/HBoxContainer/RightThird/HBoxContainer/SocialBlock/SocialContainer/SocialCell
@onready var pause_cell: Button = $VBoxContainer/MarginContainer/ContentContainer/TopRow/HBoxContainer/RightThird/HBoxContainer/PauseBlock/PauseContainer/PauseCell

# Referencias a nodos BottomRow (fila inferior XP)
@onready var xp_progress: ProgressBar = $VBoxContainer/MarginContainer/ContentContainer/BottomRow/MarginContainer/XPProgress
@onready var xp_icon: TextureRect = $VBoxContainer/MarginContainer/ContentContainer/BottomRow/MarginContainer/XPProgress/XPIcon
@onready var level_label: Label = $VBoxContainer/MarginContainer/ContentContainer/BottomRow/MarginContainer/XPProgress/LevelLabel
@onready var value_label: Label = $VBoxContainer/MarginContainer/ContentContainer/BottomRow/MarginContainer/XPProgress/ValueLabel

func _ready() -> void:
	print("[TopBar] _ready() called")
	_connect_buttons()
	_sync_from_autoloads()
	_set_dynamic_tooltips()
	print("[TopBar] Initialization completed")

func _set_dynamic_tooltips() -> void:
	"""Configurar tooltips profesionales"""
	money_cell.tooltip_text = "Dinero disponible - Click para ir al Mercado"
	gems_cell.tooltip_text = "Gemas premium - Click para la Tienda"
	zone_cell.tooltip_text = "Zona de pesca actual - Click para cambiar zona"
	social_cell.tooltip_text = "Redes sociales - Síguenos y comparte"
	pause_cell.tooltip_text = "Configuración del juego"
	xp_progress.tooltip_text = "Progreso de experiencia - Click para habilidades"

func _connect_buttons() -> void:
	"""Conectar señales de botones"""
	money_cell.pressed.connect(func(): button_pressed.emit("money"))
	gems_cell.pressed.connect(func(): button_pressed.emit("gems"))
	zone_cell.pressed.connect(func(): button_pressed.emit("zone"))
	social_cell.pressed.connect(func(): button_pressed.emit("social"))
	pause_cell.pressed.connect(_on_pause_button_pressed)
	xp_progress.gui_input.connect(_on_xp_progress_input)

func _on_pause_button_pressed() -> void:
	"""Manejar botón de pausa - conectar con PauseManager"""
	print("[TopBar] Botón pausa presionado")

	if PauseManager:
		PauseManager.request_pause_menu()
	else:
		# Fallback: emitir señal tradicional
		button_pressed.emit("pause")

func _on_xp_progress_input(event: InputEvent) -> void:
	"""Manejar click en barra XP (opcional según especificación)"""
	if event is InputEventMouseButton and event.pressed:
		button_pressed.emit("xp")

func _sync_from_autoloads() -> void:
	"""Sincronizar datos desde autoloads"""
	if Save:
		Save.coins_changed.connect(set_money)
		Save.gems_changed.connect(set_gems)
		Save.data_loaded.connect(_on_data_loaded)
		set_money(Save.get_coins())
		set_gems(Save.get_gems())

	if Experience:
		Experience.level_up.connect(_on_level_up)
		if Experience.has_signal("experience_changed"):
			Experience.experience_changed.connect(_on_experience_changed)
		# Actualizar display inicial
		call_deferred("_update_xp_display")

func _on_data_loaded(_slot: int) -> void:
	"""Actualizar cuando se cargan datos"""
	call_deferred("_sync_from_autoloads")
	call_deferred("_update_xp_display")

func set_money(amount: int) -> void:
	"""Actualizar display de dinero con formato abreviado"""
	money_cell.text = _format_currency(amount)

func set_gems(amount: int) -> void:
	"""Actualizar display de gemas"""
	gems_cell.text = str(amount)

func set_zone(zone_name: String) -> void:
	"""Actualizar nombre de zona actual"""
	zone_cell.text = zone_name

func _update_xp_display() -> void:
	"""Actualizar barra de experiencia"""
	if not Save:
		print("[TopBar] Save no disponible")
		return

	# Calcular nivel directamente desde upgrades si no hay XP
	var level = Save.game_data.get("level", 1)
	var experience = Save.game_data.get("experience", 0)
	
	if experience == 0 and Save.game_data.has("upgrades"):
		var total_upgrade_levels = 0
		for upgrade_id in Save.game_data.upgrades:
			total_upgrade_levels += Save.game_data.upgrades[upgrade_id]
		
		if total_upgrade_levels > 0:
			experience = total_upgrade_levels * 10
			level = max(1, int(sqrt(experience / 100.0)) + 1)
			print("[TopBar] Nivel calculado: %d upgrades = %d XP = nivel %d" % [total_upgrade_levels, experience, level])

	# Calcular progreso hacia siguiente nivel
	var next_level_xp = (level * level) * 100
	var current_level_xp = ((level - 1) * (level - 1)) * 100
	var progress_xp = experience - current_level_xp
	var required_xp = next_level_xp - current_level_xp
	
	xp_progress.max_value = required_xp
	xp_progress.value = progress_xp

	level_label.text = "LVL %d" % level
	value_label.text = "%d / %d" % [progress_xp, required_xp]
	
	print("[TopBar] XP actualizada: Nivel %d, Progreso %d/%d" % [level, progress_xp, required_xp])

func _on_level_up(new_level: int) -> void:
	"""Manejar subida de nivel con animación"""
	_update_xp_display()
	# TODO: Añadir animación/efecto visual de level up

func _on_experience_changed(new_xp: int) -> void:
	"""Manejar cambio de experiencia"""
	_update_xp_display()

func _format_currency(amount: int) -> String:
	"""Formatear moneda con abreviaciones (1.2K, 3.4M)"""
	if amount >= 1000000:
		return "%.1fM" % (amount / 1000000.0)
	elif amount >= 1000:
		return "%.1fK" % (amount / 1000.0)
	else:
		return str(amount)

func _format_number(number: int) -> String:
	"""Formatear números con separadores de miles"""
	var num_str = str(number)
	var formatted = ""
	var count = 0

	for i in range(num_str.length() - 1, -1, -1):
		formatted = num_str[i] + formatted
		count += 1
		if count == 3 and i > 0:
			formatted = "," + formatted
			count = 0

	return formatted
