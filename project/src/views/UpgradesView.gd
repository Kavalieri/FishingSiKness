class_name UpgradesView
extends Control

var upgrades_container: VBoxContainer
var coins_label: Label

# Datos de mejoras mejoradas
var available_upgrades = [
	{
		"id": "fridge",
		"name": "Nevera",
		"description": "Aumenta la capacidad de almacenamiento",
		"base_cost": 150,
		"cost_multiplier": 1.8,
		"max_level": 10,
		"bonus_per_level": 3,
		"bonus_type": "capacidad"
	},
	{
		"id": "hook",
		"name": "Anzuelo",
		"description": "Aumenta la probabilidad de peces raros",
		"base_cost": 200,
		"cost_multiplier": 2.2,
		"max_level": 3,
		"bonus_per_level": 15.0,
		"bonus_type": "rareza"
	},
	{
		"id": "bait_quality",
		"name": "Calidad del Cebo",
		"description": "Aumenta el valor de los peces capturados",
		"base_cost": 250,
		"cost_multiplier": 2.0,
		"max_level": 5,
		"bonus_per_level": 20.0,
		"bonus_type": "valor"
	},
	{
		"id": "fishing_speed",
		"name": "Velocidad de Pesca",
		"description": "Reduce el tiempo entre capturas",
		"base_cost": 180,
		"cost_multiplier": 1.9,
		"max_level": 4,
		"bonus_per_level": 0.5,
		"bonus_type": "velocidad"
	},
	{
		"id": "zone_multiplier",
		"name": "Conocimiento Local",
		"description": "Aumenta el multiplicador de zona",
		"base_cost": 300,
		"cost_multiplier": 2.5,
		"max_level": 3,
		"bonus_per_level": 0.25,
		"bonus_type": "multiplicador"
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
		print("OK Fondo principal configurado en UpgradesView")
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

	# Mostrar bonus actual y próximo
	if current_level > 0:
		var bonus_label = Label.new()
		bonus_label.text = get_bonus_text(upgrade_data, current_level)
		bonus_label.add_theme_font_size_override("font_size", 12)
		bonus_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
		info_vbox.add_child(bonus_label)

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

func get_bonus_text(upgrade_data: Dictionary, level: int) -> String:
	var bonus_per_level = upgrade_data.get("bonus_per_level", 0)
	var bonus_type = upgrade_data.get("bonus_type", "")
	var total_bonus = bonus_per_level * level

	match bonus_type:
		"capacidad":
			return "BOX Bonus actual: +%d espacios" % total_bonus
		"rareza":
			return "SPARKLE Bonus actual: +%.1f%% rareza" % total_bonus
		"valor":
			return "COINS Bonus actual: +%.1f%% valor" % total_bonus
		"velocidad":
			return "ENERGY Bonus actual: -%.1fs tiempo" % total_bonus
		"multiplicador":
			return "TARGET Bonus actual: +%.2fx multiplicador" % total_bonus
		_:
			return "Bonus actual: +%s" % str(total_bonus)

func apply_upgrade_effect(upgrade_id: String, level: int):
	match upgrade_id:
		"fridge":
			# Aumentar capacidad de la nevera
			Save.game_data.max_inventory = 12 + (level * 3)
			print("Fridge capacity increased to: ", Save.game_data.max_inventory)
		"hook":
			# Mejorar probabilidad de rareza - se aplicará en FishingSystem
			Save.game_data.rarity_bonus = level * 0.15 # 15% por nivel
			print("Hook rarity bonus increased to: +%.1f%%" % (Save.game_data.rarity_bonus * 100))
		"bait_quality":
			# Aumentar valor de los peces - se aplicará en captura
			Save.game_data.value_bonus = level * 0.20 # 20% por nivel
			print("Bait quality value bonus increased to: +%.1f%%" % (Save.game_data.value_bonus * 100))
		"fishing_speed":
			# Reducir tiempo entre capturas - se aplicará en FishingSystem
			Save.game_data.speed_bonus = level * 0.5 # 0.5s menos por nivel
			print("Fishing speed bonus increased to: -%.1fs" % Save.game_data.speed_bonus)
		"zone_multiplier":
			# Aumentar multiplicador de zona
			Save.game_data.zone_multiplier_bonus = level * 0.25 # 0.25x más por nivel
			print("Zone multiplier bonus increased to: +%.2fx" % Save.game_data.zone_multiplier_bonus)
