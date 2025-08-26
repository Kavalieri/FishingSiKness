class_name TopBar
extends HBoxContainer

signal gems_button_clicked()
signal settings_button_clicked()
signal level_button_clicked()

# Referencias a nodos
var coins_label: Label
var gems_label: Label
var gems_button: Button
var level_button: Button
var level_label: Label
var xp_bar: ProgressBar
var zone_label: Label
var settings_button: Button

func _ready():
	# Obtener referencias a los nodos
	coins_label = $CoinsLabel
	gems_label = $GemsContainer/GemsLabel
	gems_button = $GemsContainer/GemsButton
	zone_label = $ZoneContainer/ZoneLabel
	settings_button = $ZoneContainer/SettingsButton

	# Crear elementos de nivel dinámicamente si no existen
	setup_level_display()

	# Conectar señales
	if gems_button:
		gems_button.pressed.connect(_on_gems_button_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_button_pressed)
	if level_button:
		level_button.pressed.connect(_on_level_button_pressed)

	# Configurar tamaños mínimos para accesibilidad
	if gems_button:
		gems_button.custom_minimum_size = Vector2(48, 48)
	if settings_button:
		settings_button.custom_minimum_size = Vector2(48, 48)
	if level_button:
		level_button.custom_minimum_size = Vector2(80, 48)

	# Actualizar con datos iniciales
	update_display()

func setup_level_display():
	# Buscar si ya existe el contenedor de nivel
	var level_container = get_node_or_null("LevelContainer")
	if not level_container:
		level_container = VBoxContainer.new()
		level_container.name = "LevelContainer"
		add_child(level_container)
		move_child(level_container, 2) # Posición entre gemas y zona

	# Crear botón de nivel
	if not level_button:
		level_button = Button.new()
		level_button.flat = true
		level_container.add_child(level_button)

	# Crear barra de XP
	if not xp_bar:
		xp_bar = ProgressBar.new()
		xp_bar.custom_minimum_size = Vector2(100, 8)
		xp_bar.show_percentage = false
		level_container.add_child(xp_bar)

func update_display():
	# Obtener datos del sistema de economía
	if Save and coins_label:
		coins_label.text = "Monedas: " + str(Save.get_coins())
	if Save and gems_label:
		gems_label.text = "💎 " + str(Save.get_gems())
	if zone_label:
		zone_label.text = "Zona: Orilla"

	# Actualizar nivel y experiencia
	update_level_display()

func update_level_display():
	if not Save or not level_button or not xp_bar:
		return

	var level = Save.game_data.get("level", 1)
	var experience = Save.game_data.get("experience", 0)

	# Calcular progreso de XP
	var current_level_xp = Experience.get_xp_for_level(level) if Experience else 0
	var next_level_xp = Experience.get_xp_for_level(level + 1) if Experience else 100
	var progress_xp = experience - current_level_xp
	var required_xp = next_level_xp - current_level_xp

	# Actualizar botón de nivel
	level_button.text = "📈 Nvl %d" % level

	# Actualizar barra de XP
	if required_xp > 0:
		xp_bar.value = float(progress_xp) / float(required_xp) * 100.0
	else:
		xp_bar.value = 0.0

func _on_gems_button_pressed():
	if SFX:
		SFX.play_event("click")
	emit_signal("gems_button_clicked")
	print("TopBar: Gems button pressed")

func _on_level_button_pressed():
	if SFX:
		SFX.play_event("click")
	emit_signal("level_button_clicked")
	print("TopBar: Level button pressed")

func _on_settings_button_pressed():
	if SFX:
		SFX.play_event("click")
	emit_signal("settings_button_clicked")
	print("TopBar: Settings button pressed")
