class_name UpgradesView
extends Control

var upgrades_container: VBoxContainer
var coins_label: Label

# Datos de mejoras temporales
var available_upgrades = [
	{
		"id": "rod",
		"name": "Caña",
		"description": "Mejora la velocidad de pesca",
		"base_cost": 100,
		"cost_multiplier": 2.0,
		"max_level": 5
	},
	{
		"id": "fridge",
		"name": "Nevera",
		"description": "Aumenta la capacidad de almacenamiento",
		"base_cost": 150,
		"cost_multiplier": 1.8,
		"max_level": 10
	},
	{
		"id": "hook",
		"name": "Anzuelo",
		"description": "Aumenta la probabilidad de peces raros",
		"base_cost": 200,
		"cost_multiplier": 2.2,
		"max_level": 3
	}
]

func _ready():
	setup_background()
	setup_ui()
	refresh_display()

func setup_background():
	"""Configurar fondo principal usando BackgroundManager"""
	if BackgroundManager:
		BackgroundManager.setup_main_background(self)
		print("✅ Fondo principal configurado en UpgradesView")
	else:
		print("⚠️ BackgroundManager no disponible en UpgradesView")

func setup_ui():
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)
	main_vbox.anchor_right = 1.0
	main_vbox.anchor_bottom = 1.0
	main_vbox.offset_left = 10
	main_vbox.offset_right = -10
	main_vbox.offset_top = 10
	main_vbox.offset_bottom = -10

	# Título y monedas
	var header = HBoxContainer.new()
	main_vbox.add_child(header)

	var title = Label.new()
	title.text = "MEJORAS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	header.add_child(title)

	coins_label = Label.new()
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins_label.add_theme_font_size_override("font_size", 20)
	header.add_child(coins_label)

	# Scroll para las mejoras
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	upgrades_container = VBoxContainer.new()
	upgrades_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(upgrades_container)

func refresh_display():
	if not upgrades_container or not coins_label:
		return

	# Actualizar monedas
	coins_label.text = "%dc" % Save.get_coins()

	# Limpiar mejoras anteriores
	for child in upgrades_container.get_children():
		child.queue_free()

	# Crear botones de mejoras
	for upgrade_data in available_upgrades:
		create_upgrade_button(upgrade_data)

func create_upgrade_button(upgrade_data: Dictionary):
	var container = HBoxContainer.new()
	container.custom_minimum_size.y = 80
	upgrades_container.add_child(container)

	# Info de la mejora
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(info_vbox)

	var current_level = Save.game_data.get("upgrades", {}).get(upgrade_data.id, 0)
	var max_level = upgrade_data.max_level

	var name_label = Label.new()
	name_label.text = "%s Lv%d" % [upgrade_data.name, current_level]
	name_label.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = upgrade_data.description
	desc_label.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(desc_label)

	# Botón de compra
	var buy_button = Button.new()
	buy_button.custom_minimum_size = Vector2(100, 60)
	container.add_child(buy_button)

	if current_level >= max_level:
		buy_button.text = "MAX"
		buy_button.disabled = true
	else:
		var cost = calculate_upgrade_cost(upgrade_data, current_level)
		buy_button.text = "COMPRAR\n%dc" % cost

		if Save.get_coins() >= cost:
			buy_button.pressed.connect(_on_upgrade_purchased.bind(upgrade_data, cost))
		else:
			buy_button.disabled = true
			buy_button.modulate = Color.GRAY

func calculate_upgrade_cost(upgrade_data: Dictionary, current_level: int) -> int:
	var base_cost = upgrade_data.base_cost
	var multiplier = upgrade_data.cost_multiplier
	return int(base_cost * pow(multiplier, current_level))

func _on_upgrade_purchased(upgrade_data: Dictionary, cost: int):
	if Save.spend_coins(cost):
		# Asegurarse de que upgrades existe
		if not Save.game_data.has("upgrades"):
			Save.game_data.upgrades = {}

		# Aumentar nivel de mejora
		var current_level = Save.game_data.upgrades.get(upgrade_data.id, 0)
		Save.game_data.upgrades[upgrade_data.id] = current_level + 1

		# Aplicar efecto de la mejora
		apply_upgrade_effect(upgrade_data.id, current_level + 1)

		if SFX:
			SFX.play_event("success")

		print("Purchased upgrade: ", upgrade_data.name, " level ", current_level + 1)
		refresh_display()
	else:
		if SFX:
			SFX.play_event("error")

func apply_upgrade_effect(upgrade_id: String, level: int):
	match upgrade_id:
		"fridge":
			# Aumentar capacidad de la nevera
			Save.game_data.max_inventory = 12 + (level * 3)
			print("Fridge capacity increased to: ", Save.game_data.max_inventory)
		"rod":
			# Por ahora solo mostrar en logs, después afectará QTE
			print("Rod level increased to: ", level)
		"hook":
			# Por ahora solo mostrar en logs, después afectará rareza
			print("Hook level increased to: ", level)
