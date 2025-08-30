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

	# Configurar iconos PNG para los botones
	_setup_tab_icons()

	# Conectar las señales de los botones
	print("INIT BottomTabs: Inicializando conexiones de botones...")
	for i in tab_buttons.size():
		if tab_buttons[i]:
			tab_buttons[i].pressed.connect(_on_tab_pressed.bind(i))
			tab_buttons[i].custom_minimum_size = Vector2(60, 48) # Ajustado para 5 tabs
			print("Connected button ", i, ": ", tab_buttons[i].name)
		else:
			print("ERROR Button ", i, " is null!")

	# Accesibilidad: swap para modo zurdo
	if left_handed:
		tab_buttons.reverse()

func _setup_tab_icons() -> void:
	"""Configurar iconos PNG para los botones de pestañas"""
	var tab_icons = [
		"res://art/ui/tabs/tab_fishing.png", # Pesca
		"res://art/ui/tabs/tab_market.png", # Mercado
		"res://art/ui/tabs/tab_upgrades.png", # Mejoras
		"res://art/ui/tabs/tab_zones.png", # Mapa/Zonas
		"res://art/ui/tabs/tab_prestige.png" # Prestigio
	]

	for i in range(min(tab_buttons.size(), tab_icons.size())):
		if tab_buttons[i]:
			var texture = load(tab_icons[i])
			if texture:
				# Crear ImageTexture redimensionada si es necesario
				if texture is Texture2D:
					tab_buttons[i].icon = texture
					# Configurar el botón para mostrar solo el icono
					tab_buttons[i].text = ""
					tab_buttons[i].expand_icon = true
					# Forzar un tamaño de icono adecuado
					tab_buttons[i].custom_minimum_size = Vector2(64, 48)
				else:
					push_warning("El recurso no es una Texture2D: " + str(texture))
			else:
				push_warning("No se pudo cargar icono para tab " + str(i) + ": " + tab_icons[i])

func set_badge(_tab: int, _show_badge: bool):
	# TODO: Implementar badges cuando sea necesario
	pass

func _on_tab_pressed(tab_idx: int):
	print("FIRE BottomTabs: Button pressed ", tab_idx, " - SIGNAL SHOULD FIRE")
	current_tab = tab_idx

	# Reproducir sonido
	if SFX:
		SFX.play_event("click")

	# Emitir señal
	print("EMIT BottomTabs: Emitting tab_selected signal with ", tab_idx)
	emit_signal("tab_selected", tab_idx)
