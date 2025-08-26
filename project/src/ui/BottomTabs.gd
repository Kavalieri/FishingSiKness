class_name BottomTabs
extends HBoxContainer

signal tab_selected(tab: int)

var tab_buttons := []
var current_tab := 0
var left_handed := false

func _ready():
	# Obtener los botones existentes (orden: Pescar, Mercado, Mejoras, Mapa, Prestigio)
	tab_buttons = [
		$FishingBtn,
		$MarketBtn,
		$UpgradesBtn,
		$MapBtn,
		$PrestigeBtn
	]

	# Conectar las señales de los botones
	print("🔄 BottomTabs: Inicializando conexiones de botones...")
	for i in tab_buttons.size():
		if tab_buttons[i]:
			tab_buttons[i].pressed.connect(_on_tab_pressed.bind(i))
			tab_buttons[i].custom_minimum_size = Vector2(60, 48) # Ajustado para 5 tabs
			print("✅ Connected button ", i, ": ", tab_buttons[i].name)
		else:
			print("❌ Button ", i, " is null!")

	# Accesibilidad: swap para modo zurdo
	if left_handed:
		tab_buttons.reverse()

func set_badge(_tab: int, _show_badge: bool):
	# TODO: Implementar badges cuando sea necesario
	pass

func _on_tab_pressed(tab_idx: int):
	print("🔥 BottomTabs: Button pressed ", tab_idx, " - SIGNAL SHOULD FIRE")
	current_tab = tab_idx

	# Reproducir sonido
	if SFX:
		SFX.play_event("click")

	# Emitir señal
	print("🎯 BottomTabs: Emitting tab_selected signal with ", tab_idx)
	emit_signal("tab_selected", tab_idx)
