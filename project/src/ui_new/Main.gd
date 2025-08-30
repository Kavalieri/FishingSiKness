class_name MainUI
extends Control

# UI Principal con fondo único global según especificación

const TOP_MIN := 64
const TOP_MAX := 96
const BOT_MIN := 72
const BOT_MAX := 104

@onready var background: TextureRect = $Background
@onready var vbox := $VBoxContainer
@onready var topbar: Control = vbox.get_node("TopBar")
@onready var central_host: Control = vbox.get_node("CentralHost")
@onready var bottombar: Control = vbox.get_node("BottomBar")

func _ready() -> void:
	_apply_clamps()
	_connect_signals()

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_apply_clamps()

func _apply_clamps() -> void:
	"""Aplicar clamps para mantener dimensiones dentro de rangos óptimos"""
	if not is_inside_tree():
		return

	var h := size.y

	if topbar:
		topbar.custom_minimum_size.y = clamp(h * 0.11, TOP_MIN, TOP_MAX)

	if bottombar:
		bottombar.custom_minimum_size.y = clamp(h * 0.12, BOT_MIN, BOT_MAX)

func set_background(tex_path: String, modulate_color: Color = Color(1, 1, 1, 1)) -> void:
	"""Cambiar fondo en tiempo real según especificación UI-BG-GLOBAL"""
	var tex: Texture2D = load(tex_path)
	if tex and background:
		background.texture = tex
		background.modulate = modulate_color

	# Central se auto-ajusta por los contenedores VBox

func _connect_signals() -> void:
	"""Conectar señales de los componentes UI"""
	# TopBar signals
	if topbar and topbar.has_signal("button_pressed"):
		topbar.button_pressed.connect(_on_topbar_button_pressed)

	# BottomBar signals
	if bottombar and bottombar.has_signal("tab_selected"):
		bottombar.tab_selected.connect(_on_bottombar_tab_selected)

func _on_topbar_button_pressed(button_type: String) -> void:
	"""Manejar pulsaciones de botones en TopBar"""
	match button_type:
		"money":
			_show_economy_screen()
		"gems":
			_show_store_screen()
		"zone":
			_show_zone_select_screen()
		"social":
			_show_social_menu()
		"pause":
			_show_pause_menu()
		"xp":
			_show_experience_screen()

func _on_bottombar_tab_selected(tab_name: String) -> void:
	"""Manejar selección de tabs en BottomBar"""
	match tab_name:
		"fishing":
			central_host.show_screen("res://scenes/screens_new/FishingScreen.tscn")
		"map":
			central_host.show_screen("res://scenes/screens_new/MapScreen.tscn")
		"market":
			central_host.show_screen("res://scenes/screens_new/MarketScreen.tscn")
		"upgrades":
			central_host.show_screen("res://scenes/screens_new/UpgradesScreen.tscn")
		"prestige":
			central_host.show_screen("res://scenes/screens_new/PrestigeScreen.tscn")

# Métodos auxiliares para mostrar pantallas/menús
func _show_economy_screen() -> void:
	# TODO: Implementar pantalla de economía
	pass

func _show_store_screen() -> void:
	# TODO: Implementar tienda
	pass

func _show_zone_select_screen() -> void:
	# TODO: Implementar selector de zona
	pass

func _show_social_menu() -> void:
	# TODO: Implementar menú social
	pass

func _show_pause_menu() -> void:
	# TODO: Implementar menú de pausa
	pass

func _show_experience_screen() -> void:
	# TODO: Implementar pantalla de experiencia
	pass
