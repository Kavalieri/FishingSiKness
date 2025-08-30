class_name FishingScreen
extends Control

# Pantalla principal de pesca según especificación

signal fishing_cast_requested
signal auto_cast_toggled(enabled: bool)
signal stats_requested
signal boosters_requested
signal inventory_requested

var current_zone: Dictionary = {}
var is_auto_casting: bool = false
var fishing_stats: Dictionary = {}

@onready var background: TextureRect = $Background
@onready var fish_icon: TextureRect = $VBoxContainer/FishingArea/FishContainer/FishIcon
@onready var cast_button: Button = $VBoxContainer/FishingArea/CastButton
@onready var auto_cast_button: Button = $VBoxContainer/BottomPanel/LeftActions/AutoCastButton
@onready var stats_button: Button = $VBoxContainer/BottomPanel/LeftActions/StatsButton
@onready var boosters_button: Button = $VBoxContainer/BottomPanel/RightActions/BoostersButton
@onready var inventory_button: Button = $VBoxContainer/BottomPanel/RightActions/InventoryButton

func _ready() -> void:
	_connect_signals()

func _connect_signals() -> void:
	cast_button.pressed.connect(_on_cast_button_pressed)
	auto_cast_button.pressed.connect(_on_auto_cast_toggled)
	stats_button.pressed.connect(_on_stats_button_pressed)
	boosters_button.pressed.connect(_on_boosters_button_pressed)
	inventory_button.pressed.connect(_on_inventory_button_pressed)

func setup_fishing_screen(zone_data: Dictionary, stats: Dictionary) -> void:
	"""Configurar pantalla de pesca con zona y estadísticas"""
	current_zone = zone_data
	fishing_stats = stats

	_update_zone_background()
	_update_fishing_display()

func _update_zone_background() -> void:
	"""Actualizar fondo según la zona actual"""
	var zone_background = current_zone.get("background", null)
	if zone_background and zone_background is Texture2D:
		background.texture = zone_background

func _update_fishing_display() -> void:
	"""Actualizar elementos de visualización de pesca"""
	# Por ahora, limpiar icono de pez hasta que se capture algo
	fish_icon.texture = null
	fish_icon.visible = false

func show_caught_fish(fish_data: Dictionary) -> void:
	"""Mostrar pez capturado con animación"""
	var fish_texture = fish_data.get("icon", null)
	if fish_texture:
		fish_icon.texture = fish_texture
		fish_icon.visible = true
		_animate_fish_catch()

func _animate_fish_catch() -> void:
	"""Animar captura de pez"""
	var tween = create_tween()

	# Animación de aparición
	fish_icon.scale = Vector2.ZERO
	fish_icon.modulate.a = 0.0

	tween.parallel().tween_property(fish_icon, "scale", Vector2.ONE, 0.5)
	tween.parallel().tween_property(fish_icon, "modulate:a", 1.0, 0.3)

	# Pequeño rebote
	tween.tween_property(fish_icon, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(fish_icon, "scale", Vector2.ONE, 0.1)

func set_casting_state(is_casting: bool) -> void:
	"""Establecer estado de lanzamiento"""
	cast_button.disabled = is_casting
	if is_casting:
		cast_button.text = "Lanzando..."
	else:
		cast_button.text = "Lanzar Caña"

func update_auto_cast_state(enabled: bool) -> void:
	"""Actualizar estado del auto-cast"""
	is_auto_casting = enabled
	if enabled:
		auto_cast_button.text = "Auto Pesca: ON"
		auto_cast_button.modulate = Color.LIGHT_GREEN
	else:
		auto_cast_button.text = "Auto Pesca: OFF"
		auto_cast_button.modulate = Color.WHITE

func _on_cast_button_pressed() -> void:
	"""Manejar lanzamiento manual"""
	fishing_cast_requested.emit()

func _on_auto_cast_toggled() -> void:
	"""Manejar toggle del auto-cast"""
	is_auto_casting = not is_auto_casting
	update_auto_cast_state(is_auto_casting)
	auto_cast_toggled.emit(is_auto_casting)

func _on_stats_button_pressed() -> void:
	"""Mostrar estadísticas de pesca"""
	stats_requested.emit()

func _on_boosters_button_pressed() -> void:
	"""Mostrar potenciadores disponibles"""
	boosters_requested.emit()

func _on_inventory_button_pressed() -> void:
	"""Mostrar inventario de pesca"""
	inventory_requested.emit()
