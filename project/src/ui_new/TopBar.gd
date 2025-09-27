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
	"""Manejar click en barra XP - abrir ventana de milestones"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_milestones_window()

func _show_milestones_window() -> void:
	"""Mostrar ventana de milestones simple"""
	var dialog = AcceptDialog.new()
	dialog.title = "Milestones de Nivel"
	dialog.size = Vector2i(500, 600)
	
	# Crear contenido
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	
	# Info actual
	if Experience:
		var info_label = Label.new()
		var progress = Experience.get_xp_progress()
		info_label.text = "Nivel Actual: %d\nXP: %d / %d para siguiente nivel" % [
			Experience.current_level,
			progress.current_xp,
			progress.required_xp
		]
		info_label.add_theme_font_size_override("font_size", 16)
		vbox.add_child(info_label)
		
		var separator = HSeparator.new()
		vbox.add_child(separator)
		
		# Milestones
		var scroll = ScrollContainer.new()
		scroll.custom_minimum_size.y = 400
		vbox.add_child(scroll)
		
		var milestones_vbox = VBoxContainer.new()
		scroll.add_child(milestones_vbox)
		
		# Mostrar milestones
		var milestone_levels = Experience.milestones.keys()
		milestone_levels.sort()
		
		for level in milestone_levels:
			var milestone = Experience.milestones[level]
			var unlocked = level <= Experience.current_level
			
			var panel = PanelContainer.new()
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.1, 0.1, 0.1, 0.8) if unlocked else Color(0.05, 0.05, 0.05, 0.6)
			style.border_width_left = 2
			style.border_color = Color.GREEN if unlocked else Color.GRAY
			style.corner_radius_top_left = 4
			style.corner_radius_top_right = 4
			style.corner_radius_bottom_left = 4
			style.corner_radius_bottom_right = 4
			panel.add_theme_stylebox_override("panel", style)
			
			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 12)
			panel.add_child(hbox)
			
			var icon = Label.new()
			icon.text = "✓" if unlocked else "🔒"
			icon.add_theme_font_size_override("font_size", 20)
			icon.add_theme_color_override("font_color", Color.GREEN if unlocked else Color.GRAY)
			hbox.add_child(icon)
			
			var info = VBoxContainer.new()
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(info)
			
			var title = Label.new()
			var required_xp = Experience.get_xp_for_level(level)
			title.text = "Nivel %d (XP necesaria: %d)" % [level, required_xp]
			title.add_theme_font_size_override("font_size", 16)
			title.add_theme_color_override("font_color", Color.WHITE if unlocked else Color.GRAY)
			info.add_child(title)
			
			var desc = Label.new()
			desc.text = milestone.get("desc", "Milestone")
			desc.add_theme_font_size_override("font_size", 14)
			desc.add_theme_color_override("font_color", Color.LIGHT_GRAY if unlocked else Color.GRAY)
			info.add_child(desc)
			
			milestones_vbox.add_child(panel)
			
			# Espaciado
			var spacer = Control.new()
			spacer.custom_minimum_size.y = 4
			milestones_vbox.add_child(spacer)
	
	# Agregar contenido a la ventana
	dialog.add_child(vbox)
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 8
	vbox.offset_top = 8
	vbox.offset_right = -8
	vbox.offset_bottom = -50
	
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

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
		Experience.experience_changed.connect(_on_experience_changed)
		print("[TopBar] Conectado a Experience system")
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
	if not Experience:
		print("[TopBar] Experience no disponible")
		return

	var level = Experience.current_level
	var experience = Experience.current_xp
	
	# Obtener progreso desde Experience
	var progress_data = Experience.get_xp_progress()
	var progress_xp = progress_data.current_xp
	var required_xp = progress_data.required_xp
	
	xp_progress.max_value = required_xp
	xp_progress.value = progress_xp

	level_label.text = "LVL %d" % level
	value_label.text = "%d / %d" % [progress_xp, required_xp]
	
	print("[TopBar] XP actualizada: Nivel %d, XP total %d, Progreso %d/%d" % [level, experience, progress_xp, required_xp])

func _on_level_up(new_level: int) -> void:
	"""Manejar subida de nivel con animación"""
	_update_xp_display()
	# TODO: Añadir animación/efecto visual de level up

func _on_experience_changed(new_xp: int, new_level: int) -> void:
	"""Manejar cambio de experiencia"""
	print("[TopBar] Experience changed: XP=%d, Level=%d" % [new_xp, new_level])
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
