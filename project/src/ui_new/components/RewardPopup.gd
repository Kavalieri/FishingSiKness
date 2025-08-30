class_name RewardPopup
extends Control

# Popup para mostrar recompensas según especificación

signal reward_collected

@onready var title_label: Label = $CenterContainer/RewardPanel/VBoxContainer/Header/Title
@onready var close_button: Button = $CenterContainer/RewardPanel/VBoxContainer/Header/CloseButton
@onready var reward_icon: TextureRect = $CenterContainer/RewardPanel/VBoxContainer / \
	Content / RewardIcon
@onready var reward_text: Label = $CenterContainer/RewardPanel/VBoxContainer/Content/RewardText
@onready var reward_amount: Label = $CenterContainer/RewardPanel/VBoxContainer/Content / \
	RewardAmount
@onready var collect_button: Button = $CenterContainer/RewardPanel/VBoxContainer/Footer / \
	CollectButton
@onready var overlay: ColorRect = $Overlay

func _ready() -> void:
	_connect_signals()
	_setup_initial_state()

func _connect_signals() -> void:
	close_button.pressed.connect(_on_close_pressed)
	collect_button.pressed.connect(_on_collect_pressed)
	overlay.gui_input.connect(_on_overlay_input)

func _setup_initial_state() -> void:
	modulate.a = 0.0
	show_animated()

func show_animated() -> void:
	"""Mostrar popup con animación"""
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.3)

	# Animación de entrada del panel
	var panel = $CenterContainer/RewardPanel
	panel.scale = Vector2(0.8, 0.8)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.3)

func hide_animated() -> void:
	"""Ocultar popup con animación"""
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)

func setup_reward(reward_type: String, amount: int, icon_texture: Texture2D = null) -> void:
	"""Configurar recompensa"""
	match reward_type:
		"money":
			title_label.text = "¡Dinero!"
			reward_text.text = "Has ganado dinero"
		"gems":
			title_label.text = "¡Gemas!"
			reward_text.text = "Has ganado gemas"
		"fish":
			title_label.text = "¡Pez capturado!"
			reward_text.text = "Has capturado un pez"
		"item":
			title_label.text = "¡Objeto obtenido!"
			reward_text.text = "Has obtenido un objeto"
		_:
			title_label.text = "¡Recompensa!"
			reward_text.text = "Has recibido una recompensa"

	reward_amount.text = "x%d" % amount

	if icon_texture:
		reward_icon.texture = icon_texture
		reward_icon.visible = true
	else:
		reward_icon.visible = false

func _on_close_pressed() -> void:
	reward_collected.emit()
	hide_animated()

func _on_collect_pressed() -> void:
	reward_collected.emit()
	hide_animated()

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_collect_pressed()
