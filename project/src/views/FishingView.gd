extends Control

signal fish_caught(fish_name: String, value: int)

var cast_button: Button

# Fondo dinámico
var background_node: Control

# Sistema QTE como componente separado
var qte_component: Control
var qte_container: VBoxContainer
var qte_progress_bar: ProgressBar
var qte_target_zone: Control
var qte_needle: Control
var qte_instructions: Label
var qte_timer_bar: ProgressBar

var is_fishing := false
var qte_progress := 0.0
var qte_speed := 1.5
var qte_direction := 1
var qte_target_min := 0.3
var qte_target_max := 0.7
var qte_timer := 0.0
var qte_max_time := 3.0
var qte_active := false

# Historial de pescas
var fishing_history_panel: PanelContainer
var history_scroll: ScrollContainer
var history_list: VBoxContainer
var fishing_history: Array = []
var max_history_entries := 50

# Sistema gacha/rareza
var rarity_multipliers = {
	"común": 1.0,
	"rara": 1.5,
	"épica": 2.5,
	"legendaria": 5.0
}

var rarity_chances = {
	"común": 70.0, # 70%
	"rara": 20.0, # 20%
	"épica": 8.0, # 8%
	"legendaria": 2.0 # 2%
}

var rarity_colors = {
	"común": Color.WHITE,
	"rara": Color.CYAN,
	"épica": Color.MAGENTA,
	"legendaria": Color.GOLD
}

var rarity_emojis = {
	"común": "⚪",
	"rara": "🔵",
	"épica": "🟣",
	"legendaria": "🟡"
}

func _ready():
	# Obtener referencias a los nodos existentes
	cast_button = $GameplayArea/CastButton
	if cast_button:
		cast_button.pressed.connect(_on_cast_button_pressed)

	# Obtener referencia al fondo
	background_node = $Background

	# Inicializar sistema QTE
	setup_qte_component()

	# Inicializar historial de pescas
	setup_fishing_history()

	# Conectar señal de visibilidad
	visibility_changed.connect(_on_visibility_changed)

	update_zone_background()
	print("FishingView ready")

func setup_qte_component():
	"""Crear el componente QTE como un elemento separado que no interfiera con la UI"""
	# Crear contenedor principal del QTE
	qte_component = Control.new()
	qte_component.name = "QTEComponent"
	qte_component.visible = false
	qte_component.layout_mode = 1
	qte_component.anchor_left = 0.1
	qte_component.anchor_right = 0.9
	qte_component.anchor_top = 0.3
	qte_component.anchor_bottom = 0.6
	add_child(qte_component)

	# Crear contenedor para el QTE
	qte_container = VBoxContainer.new()
	qte_container.layout_mode = 1
	qte_container.anchor_right = 1.0
	qte_container.anchor_bottom = 1.0
	qte_container.add_theme_constant_override("separation", 15)
	qte_component.add_child(qte_container)

	# Título del QTE
	qte_instructions = Label.new()
	qte_instructions.text = "🎣 ¡PESCANDO! ¡Presiona cuando la aguja esté en la zona verde!"
	qte_instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qte_instructions.add_theme_font_size_override("font_size", 18)
	qte_instructions.add_theme_color_override("font_color", Color.WHITE)
	qte_container.add_child(qte_instructions)

	# Panel del QTE principal
	var qte_panel = PanelContainer.new()
	qte_panel.custom_minimum_size = Vector2(350, 120)
	qte_container.add_child(qte_panel)

	var qte_content = VBoxContainer.new()
	qte_content.add_theme_constant_override("separation", 10)
	qte_panel.add_child(qte_content)

	# Barra de progreso principal
	var progress_container = Control.new()
	progress_container.custom_minimum_size.y = 40
	qte_content.add_child(progress_container)

	qte_progress_bar = ProgressBar.new()
	qte_progress_bar.anchor_right = 1.0
	qte_progress_bar.anchor_bottom = 1.0
	qte_progress_bar.min_value = 0.0
	qte_progress_bar.max_value = 1.0
	qte_progress_bar.value = 0.0
	qte_progress_bar.show_percentage = false
	progress_container.add_child(qte_progress_bar)

	# Zona objetivo (verde)
	qte_target_zone = ColorRect.new()
	qte_target_zone.color = Color.GREEN
	qte_target_zone.color.a = 0.6
	progress_container.add_child(qte_target_zone)

	# Aguja (roja)
	qte_needle = ColorRect.new()
	qte_needle.color = Color.RED
	qte_needle.custom_minimum_size = Vector2(4, 40)
	progress_container.add_child(qte_needle)

	# Timer bar
	var timer_label = Label.new()
	timer_label.text = "⏱️ Tiempo restante:"
	timer_label.add_theme_font_size_override("font_size", 14)
	qte_content.add_child(timer_label)

	qte_timer_bar = ProgressBar.new()
	qte_timer_bar.min_value = 0.0
	qte_timer_bar.max_value = 1.0
	qte_timer_bar.value = 1.0
	qte_timer_bar.add_theme_color_override("fill", Color.ORANGE)
	qte_content.add_child(qte_timer_bar)

func setup_fishing_history():
	"""Crear panel de historial de pescas debajo del botón de lanzamiento"""
	# Panel principal del historial - posicionado en el área de gameplay
	fishing_history_panel = PanelContainer.new()
	fishing_history_panel.name = "FishingHistoryPanel"
	fishing_history_panel.layout_mode = 2
	fishing_history_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fishing_history_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fishing_history_panel.custom_minimum_size = Vector2(0, 200)

	# Añadir al GameplayArea después del botón
	var gameplay_area = $GameplayArea
	if gameplay_area:
		gameplay_area.add_child(fishing_history_panel)

	# VBox principal
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 5)
	fishing_history_panel.add_child(main_vbox)

	# Título del historial
	var title_label = Label.new()
	title_label.text = "📜 HISTORIAL DE PESCAS"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	main_vbox.add_child(title_label)

	main_vbox.add_child(HSeparator.new())

	# Contenedor con scroll
	history_scroll = ScrollContainer.new()
	history_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(history_scroll)

	# Lista de entradas del historial
	history_list = VBoxContainer.new()
	history_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_list.add_theme_constant_override("separation", 2)
	history_scroll.add_child(history_list)

	# Añadir mensaje inicial
	add_history_entry("🎣 ¡Comienza a pescar!", "", 0, 0.0, false)

func add_history_entry(message: String, fish_name: String, value: int, size: float, success: bool):
	"""Añadir una entrada al historial de pescas"""
	# Crear entrada del historial con mayor separación
	var entry_container = VBoxContainer.new()
	entry_container.add_theme_constant_override("separation", 8)
	entry_container.custom_minimum_size.y = 60

	# Panel de fondo para cada entrada
	var entry_panel = PanelContainer.new()
	entry_panel.add_theme_color_override("bg_color", Color(0.1, 0.1, 0.1, 0.8))

	var inner_container = HBoxContainer.new()
	entry_panel.add_child(inner_container)

	# Timestamp
	var time_label = Label.new()
	var current_time = Time.get_datetime_string_from_system().split("T")[1].substr(0, 5)
	time_label.text = current_time
	time_label.custom_minimum_size.x = 50
	time_label.add_theme_font_size_override("font_size", 16) # Fuente más grande
	time_label.add_theme_color_override("font_color", Color.GRAY)
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inner_container.add_child(time_label)

	# Contenido principal
	var content_label = Label.new()
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_label.add_theme_font_size_override("font_size", 16) # Fuente más grande
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if success and fish_name != "":
		var rarity_color = get_rarity_color_from_fish_name(fish_name)
		content_label.text = "%s\n💰 %dc • 📏 %.1fcm" % [message, value, size]
		content_label.add_theme_color_override("font_color", rarity_color)
	elif not success:
		content_label.text = message
		content_label.add_theme_color_override("font_color", Color.ORANGE_RED)
	else:
		content_label.text = message
		content_label.add_theme_color_override("font_color", Color.WHITE)

	inner_container.add_child(content_label)
	entry_container.add_child(entry_panel)

	# Separador visual
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 2
	entry_container.add_child(separator)

	# Añadir al principio de la lista (más reciente arriba)
	history_list.add_child(entry_container)
	history_list.move_child(entry_container, 0)

	# Almacenar en array del historial
	var history_data = {
		"time": current_time,
		"message": message,
		"fish_name": fish_name,
		"value": value,
		"size": size,
		"success": success
	}
	fishing_history.push_front(history_data)

	# Limitar entradas del historial
	if fishing_history.size() > max_history_entries:
		fishing_history.pop_back()
		# Remover la entrada visual más antigua
		var children = history_list.get_children()
		if children.size() > max_history_entries:
			children[-1].queue_free()

	# Scroll automático al principio para mostrar la entrada más reciente
	await get_tree().process_frame
	if history_scroll:
		history_scroll.scroll_vertical = 0

func get_rarity_color_from_fish_name(fish_name: String) -> Color:
	"""Obtener color de rareza basado en el nombre del pez"""
	# Intentar obtener el pez del sistema de contenido
	if Content:
		# Buscar en todas las zonas por el pez
		var zones = ["orilla", "lago", "rio", "costa", "mar"]
		for zone_id in zones:
			var zone_def = Content.get_zone_by_id(zone_id)
			if zone_def and zone_def.entries:
				for entry in zone_def.entries:
					if entry and entry.fish and entry.fish.name == fish_name:
						return get_rarity_color(entry.fish.rarity)

	# Color por defecto si no se encuentra
	return Color.WHITE

func roll_rarity_bonus() -> String:
	"""Sistema gacha: determinar rareza aleatoria de la captura"""
	var roll = randf() * 100.0 # 0-100
	var cumulative = 0.0

	# Orden de probabilidad: común -> rara -> épica -> legendaria
	for rarity in ["común", "rara", "épica", "legendaria"]:
		cumulative += rarity_chances[rarity]
		if roll <= cumulative:
			return rarity

	return "común" # Fallback

func get_rarity_multiplier(rarity: String) -> float:
	"""Obtener multiplicador según rareza"""
	return rarity_multipliers.get(rarity, 1.0)

func get_rarity_color_by_name(rarity: String) -> Color:
	"""Obtener color según nombre de rareza"""
	return rarity_colors.get(rarity, Color.WHITE)

func get_rarity_emoji(rarity: String) -> String:
	"""Obtener emoji según rareza"""
	return rarity_emojis.get(rarity, "⚪")

func create_catch_popup(popup_data: Dictionary) -> Control:
	"""Crear popup de captura con detalles y opciones"""
	var fish_instance = popup_data.fish_instance
	var rarity = popup_data.rarity
	var rarity_multiplier = popup_data.rarity_multiplier

	var overlay = Control.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.z_index = 300

	# Fondo semi-transparente con efecto especial para rareza legendaria
	var background = ColorRect.new()
	if rarity == "legendaria":
		background.color = Color(0.8, 0.6, 0.0, 0.9) # Dorado intenso
	elif rarity == "épica":
		background.color = Color(0.5, 0.0, 0.8, 0.9) # Púrpura intenso
	elif rarity == "rara":
		background.color = Color(0.0, 0.5, 0.8, 0.9) # Azul intenso
	else:
		background.color = Color(0, 0, 0, 0.9) # Negro normal

	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	overlay.add_child(background)

	# Panel del popup (más grande para mostrar detalles)
	var popup_panel = PanelContainer.new()
	popup_panel.custom_minimum_size = Vector2(500, 400)
	popup_panel.position = Vector2(
		(get_viewport().get_visible_rect().size.x - 500) / 2,
		(get_viewport().get_visible_rect().size.y - 400) / 2
	)
	overlay.add_child(popup_panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	popup_panel.add_child(main_vbox)

	# Título con efecto de rareza
	var title_label = Label.new()
	var rarity_emoji = get_rarity_emoji(rarity)
	title_label.text = "%s ¡CAPTURA %s! %s" % [rarity_emoji, rarity.to_upper(), rarity_emoji]
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", get_rarity_color_by_name(rarity))
	main_vbox.add_child(title_label)

	# Información del pez
	var fish_info = VBoxContainer.new()
	fish_info.add_theme_constant_override("separation", 10)
	main_vbox.add_child(fish_info)

	var fish_name_label = Label.new()
	fish_name_label.text = "🐟 %s" % fish_instance.fish_def.name
	fish_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fish_name_label.add_theme_font_size_override("font_size", 20)
	fish_name_label.add_theme_color_override("font_color", Color.WHITE)
	fish_info.add_child(fish_name_label)

	var size_label = Label.new()
	size_label.text = "📏 Tamaño: %.1fcm" % fish_instance.size
	size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	size_label.add_theme_font_size_override("font_size", 16)
	fish_info.add_child(size_label)

	var price_info = VBoxContainer.new()
	price_info.add_theme_constant_override("separation", 5)
	main_vbox.add_child(price_info)

	var base_price_label = Label.new()
	base_price_label.text = "💰 Precio base: %d monedas" % fish_instance.fish_def.base_market_value
	base_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	base_price_label.add_theme_font_size_override("font_size", 14)
	price_info.add_child(base_price_label)

	var multipliers_label = Label.new()
	var multipliers_text = "🔢 Zona: x%.1f • Rareza: x%.1f"
	multipliers_label.text = multipliers_text % [fish_instance.zone_multiplier, rarity_multiplier]
	multipliers_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	multipliers_label.add_theme_font_size_override("font_size", 14)
	price_info.add_child(multipliers_label)

	var final_price_label = Label.new()
	final_price_label.text = "💎 PRECIO FINAL: %d MONEDAS" % fish_instance.final_price
	final_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_price_label.add_theme_font_size_override("font_size", 18)
	final_price_label.add_theme_color_override("font_color", Color.GOLD)
	price_info.add_child(final_price_label)

	# Botones de acción
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(button_container)

	var store_btn = Button.new()
	store_btn.text = "🧊 ALMACENAR"
	store_btn.custom_minimum_size = Vector2(150, 50)
	store_btn.add_theme_font_size_override("font_size", 16)
	store_btn.add_theme_color_override("font_color", Color.WHITE)
	store_btn.add_theme_color_override("font_hover_color", Color.LIGHT_GREEN)
	store_btn.pressed.connect(func():
		_confirm_store_fish(fish_instance, rarity, rarity_multiplier)
		overlay.queue_free()
	)
	button_container.add_child(store_btn)

	var separator = VSeparator.new()
	separator.custom_minimum_size.x = 20
	button_container.add_child(separator)

	var discard_btn = Button.new()
	discard_btn.text = "🗑️ DESCARTAR"
	discard_btn.custom_minimum_size = Vector2(150, 50)
	discard_btn.add_theme_font_size_override("font_size", 16)
	discard_btn.add_theme_color_override("font_color", Color.WHITE)
	discard_btn.add_theme_color_override("font_hover_color", Color.ORANGE_RED)
	discard_btn.pressed.connect(func():
		_confirm_discard_catch(fish_instance, rarity)
		overlay.queue_free()
	)
	button_container.add_child(discard_btn)

	return overlay

func _confirm_store_fish(fish_instance: FishInstance, rarity: String, rarity_multiplier: float):
	"""Confirmar almacenamiento del pez capturado"""
	Save.add_fish(fish_instance)

	# Añadir al historial con información de rareza
	var rarity_emoji = get_rarity_emoji(rarity)
	var success_message = "%s ¡%s %s!" % [
		rarity_emoji, rarity.capitalize(), fish_instance.fish_def.name
	]
	add_special_history_entry(
		success_message,
		fish_instance.fish_def.name,
		fish_instance.final_price,
		fish_instance.size,
		rarity
	)

	emit_signal("fish_caught", fish_instance.fish_def.name, fish_instance.final_price)

	# Añadir experiencia con bonus por rareza
	if Experience:
		var xp_gained = calculate_xp_reward(fish_instance)
		var rarity_xp_bonus = int(xp_gained * (rarity_multiplier - 1.0))
		Experience.add_experience(xp_gained + rarity_xp_bonus)

	if SFX:
		SFX.play_event("success")

	print("Stored: %s (%.1fcm) %s rarity worth %d coins" % [
		fish_instance.fish_def.name,
		fish_instance.size,
		rarity,
		fish_instance.final_price
	])

func _confirm_discard_catch(fish_instance: FishInstance, rarity: String):
	"""Confirmar descarte del pez capturado"""
	var rarity_emoji = get_rarity_emoji(rarity)
	var discard_message = "%s Descartaste un %s %s (perdiste %d monedas)" % [
		rarity_emoji, rarity, fish_instance.fish_def.name, fish_instance.final_price
	]
	add_history_entry(discard_message, "", 0, 0.0, false)

	if SFX:
		SFX.play_event("error")

	print("Discarded: %s %s worth %d coins" % [
		rarity, fish_instance.fish_def.name, fish_instance.final_price
	])

func add_special_history_entry(
	message: String, fish_name: String, value: int, size: float, rarity: String
):
	"""Añadir entrada especial al historial con efectos de rareza"""
	# Similar a add_history_entry pero con efectos especiales
	var entry_container = VBoxContainer.new()
	entry_container.add_theme_constant_override("separation", 8)
	entry_container.custom_minimum_size.y = 70 # Más grande para rareza especial

	# Panel de fondo con efecto especial según rareza
	var entry_panel = PanelContainer.new()
	var bg_color = get_rarity_color_by_name(rarity)
	bg_color.a = 0.3 # Semi-transparente
	entry_panel.add_theme_color_override("bg_color", bg_color)

	var inner_container = HBoxContainer.new()
	entry_panel.add_child(inner_container)

	# Timestamp
	var time_label = Label.new()
	var current_time = Time.get_datetime_string_from_system().split("T")[1].substr(0, 5)
	time_label.text = current_time
	time_label.custom_minimum_size.x = 50
	time_label.add_theme_font_size_override("font_size", 16)
	time_label.add_theme_color_override("font_color", Color.GRAY)
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inner_container.add_child(time_label)

	# Contenido principal con efecto de rareza
	var content_label = Label.new()
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_label.add_theme_font_size_override("font_size", 18) # Más grande para rareza especial
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content_label.text = "%s\n💰 %dc • 📏 %.1fcm • %s" % [message, value, size, rarity.to_upper()]
	content_label.add_theme_color_override("font_color", get_rarity_color_by_name(rarity))

	inner_container.add_child(content_label)
	entry_container.add_child(entry_panel)

	# Separador especial para rareza
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 3
	separator.add_theme_color_override("color", get_rarity_color_by_name(rarity))
	entry_container.add_child(separator)

	# Añadir al principio de la lista (más reciente arriba)
	history_list.add_child(entry_container)
	history_list.move_child(entry_container, 0)

	# Almacenar en array del historial
	var history_data = {
		"time": current_time,
		"message": message,
		"fish_name": fish_name,
		"value": value,
		"size": size,
		"success": true,
		"rarity": rarity
	}
	fishing_history.push_front(history_data)

	# Limitar entradas del historial
	if fishing_history.size() > max_history_entries:
		fishing_history.pop_back()
		var children = history_list.get_children()
		if children.size() > max_history_entries:
			children[-1].queue_free()

	# Scroll automático al principio
	await get_tree().process_frame
	if history_scroll:
		history_scroll.scroll_vertical = 0

func get_rarity_color(rarity: int) -> Color:
	"""Obtener color según rareza"""
	var colors = {
		0: Color.WHITE, # Común
		1: Color.LIME_GREEN, # Poco común
		2: Color.CYAN, # Raro
		3: Color.MAGENTA, # Épico
		4: Color.GOLD # Legendario
	}
	return colors.get(rarity, Color.WHITE)

func _process(delta):
	if is_fishing and qte_active:
		# Actualizar timer del QTE
		qte_timer += delta
		var timer_progress = 1.0 - (qte_timer / qte_max_time)
		if qte_timer_bar:
			qte_timer_bar.value = timer_progress

		# Cambiar color del timer según urgencia
		if timer_progress < 0.3:
			qte_timer_bar.add_theme_color_override("fill", Color.RED)
		elif timer_progress < 0.6:
			qte_timer_bar.add_theme_color_override("fill", Color.ORANGE)
		else:
			qte_timer_bar.add_theme_color_override("fill", Color.GREEN)

		# Mover la aguja del QTE con movimiento de rebote
		qte_progress += qte_speed * qte_direction * delta
		if qte_progress >= 1.0:
			qte_progress = 1.0
			qte_direction = -1
		elif qte_progress <= 0.0:
			qte_progress = 0.0
			qte_direction = 1

		update_qte_display()

		# Verificar si se acabó el tiempo
		if qte_timer >= qte_max_time:
			qte_failed()

func update_qte_display():
	if not qte_progress_bar or not qte_needle or not qte_target_zone:
		return

	# Actualizar barra de progreso
	qte_progress_bar.value = qte_progress

	# Posicionar zona objetivo
	var container_width = qte_progress_bar.size.x
	var target_width = (qte_target_max - qte_target_min) * container_width
	var target_x = qte_target_min * container_width

	qte_target_zone.position.x = target_x
	qte_target_zone.size.x = target_width
	qte_target_zone.size.y = qte_progress_bar.size.y

	# Posicionar aguja
	var needle_x = qte_progress * container_width - 2
	qte_needle.position.x = needle_x

	# Cambiar color de la aguja según proximidad al objetivo
	if qte_progress >= qte_target_min and qte_progress <= qte_target_max:
		qte_needle.color = Color.LIME_GREEN
		qte_instructions.text = "🎯 ¡PERFECTO! ¡Presiona AHORA!"
		qte_instructions.add_theme_color_override("font_color", Color.LIME_GREEN)
	else:
		qte_needle.color = Color.RED
		qte_instructions.text = "🎣 ¡Espera a que esté en la zona verde!"
		qte_instructions.add_theme_color_override("font_color", Color.WHITE)

func _on_cast_button_pressed():
	if SFX:
		SFX.play_event("click")

	if not is_fishing:
		start_fishing()
	else:
		try_catch_fish()

func start_fishing():
	print("Starting fishing...")

	# Verificar espacio en el inventario
	var inventory = Save.get_inventory()
	var max_inventory = Save.game_data.get("max_inventory", 12)

	if inventory.size() >= max_inventory:
		show_inventory_full_message()
		return

	# Configurar el QTE
	is_fishing = true
	qte_active = true
	qte_timer = 0.0
	qte_progress = 0.0
	qte_direction = 1

	# Randomizar zona objetivo
	qte_target_min = randf_range(0.2, 0.5)
	qte_target_max = qte_target_min + randf_range(0.15, 0.25)
	qte_speed = randf_range(1.2, 2.0)

	# Mostrar UI del QTE
	if qte_component:
		qte_component.visible = true

	cast_button.text = "🎯 ¡ATRAPAR!"

func try_catch_fish():
	if not qte_active:
		return

	print("Trying to catch fish... QTE progress: ", qte_progress)

	var success = qte_progress >= qte_target_min and qte_progress <= qte_target_max

	# Terminar QTE
	qte_active = false
	is_fishing = false
	if qte_component:
		qte_component.visible = false

	cast_button.text = "🎣 LANZAR"

	if success:
		catch_successful()
	else:
		qte_failed()

func catch_successful():
	# Usar el sistema real de contenido para pescar
	if not Content or not Save:
		print("Content or Save system not available")
		add_history_entry("❌ Sistema no disponible", "", 0, 0.0, false)
		return

	var current_zone_id = Save.game_data.get("current_zone", "orilla")
	var zone_def = Content.get_zone_by_id(current_zone_id)
	print("Fishing in zone: ", current_zone_id)

	if not zone_def:
		print("Zone not found: ", current_zone_id)
		add_history_entry("❌ Zona no encontrada: " + current_zone_id, "", 0, 0.0, false)
		return

	# Seleccionar pez aleatorio de la zona
	var selected_fish = select_random_fish_from_zone(zone_def)
	if not selected_fish:
		print("No fish available in zone: ", current_zone_id)
		add_history_entry("❌ No hay peces en zona: " + current_zone_id, "", 0, 0.0, false)
		return

	print("Selected fish: ", selected_fish.name)

	# ¡SISTEMA GACHA! - Determinar rareza aleatoria
	var rarity_bonus = roll_rarity_bonus()
	var rarity_multiplier = get_rarity_multiplier(rarity_bonus)

	print("Rarity roll: ", rarity_bonus, " (x", rarity_multiplier, ")")

	# Generar tamaño aleatorio
	var random_size = randf_range(selected_fish.size_min, selected_fish.size_max)

	# Crear instancia de pez con multiplicadores combinados (zona + rareza)
	var base_price = selected_fish.base_market_value
	var zone_multiplier = zone_def.price_multiplier
	var final_multiplier = zone_multiplier * rarity_multiplier
	var final_price = int(base_price * final_multiplier)

	# Crear fish_instance personalizada con rareza
	var fish_instance = FishInstance.new(
		selected_fish,
		random_size,
		current_zone_id,
		zone_multiplier
	)
	# Sobrescribir el precio final con el bonus de rareza
	fish_instance.final_price = final_price

	# Mostrar popup de captura antes de guardar
	show_catch_popup(fish_instance, rarity_bonus, rarity_multiplier)

func show_catch_popup(fish_instance: FishInstance, rarity: String, rarity_multiplier: float):
	"""Mostrar popup con detalles de la captura y opciones de almacenar/descartar"""
	var popup_data = {
		"fish_instance": fish_instance,
		"rarity": rarity,
		"rarity_multiplier": rarity_multiplier
	}

	# Crear popup personalizado
	var popup = create_catch_popup(popup_data)
	add_child(popup)

func select_random_fish_from_zone(zone_def: ZoneDef) -> FishDef:
	"""Seleccionar un pez aleatorio usando el sistema de loot tables"""
	if not zone_def.entries or zone_def.entries.size() == 0:
		print("No entries in zone_def")
		return null

	print("Zone has ", zone_def.entries.size(), " entries")

	# Calcular peso total
	var total_weight = 0
	for entry in zone_def.entries:
		if entry and entry.fish:
			total_weight += entry.weight
			print("Entry: ", entry.fish.name, " weight: ", entry.weight)
		else:
			print("Invalid entry found")

	if total_weight == 0:
		print("Total weight is 0")
		return null

	print("Total weight: ", total_weight)

	# Seleccionar basado en peso
	var random_weight = randi() % total_weight
	var current_weight = 0

	print("Random weight selected: ", random_weight)

	for entry in zone_def.entries:
		if entry and entry.fish:
			current_weight += entry.weight
			if random_weight < current_weight:
				print("Selected: ", entry.fish.name)
				return entry.fish

	print("No fish selected - fallback to first available")
	# Fallback - devolver el primer pez disponible
	for entry in zone_def.entries:
		if entry and entry.fish:
			return entry.fish

	return null

func calculate_xp_reward(fish_instance: FishInstance) -> int:
	"""Calcular XP basado en rareza y tamaño del pez"""
	var base_xp = 10
	var rarity_bonus = fish_instance.fish_def.rarity * 5
	var size_ratio = fish_instance.size / fish_instance.fish_def.size_max
	var size_bonus = int(size_ratio * 10)

	return base_xp + rarity_bonus + size_bonus

func qte_failed():
	# Añadir fallo al historial
	add_history_entry("💔 ¡El pez se escapó!", "", 0, 0.0, false)

	if SFX:
		SFX.play_event("error")
	print("Fish got away!")

func show_inventory_full_message():
	# Añadir al historial en lugar de mensaje temporal
	add_history_entry("🧊 ¡Inventario lleno! Ve al Mercado para vender peces", "", 0, 0.0, false)

	if SFX:
		SFX.play_event("error")

func _on_visibility_changed():
	"""Actualizar fondo cuando la vista se hace visible"""
	if visible:
		update_zone_background()

func update_zone_background():
	"""Actualizar el fondo basado en la zona actual usando BackgroundManager"""
	if not background_node or not Save:
		return

	var current_zone_id = Save.game_data.get("current_zone", "orilla")

	if BackgroundManager:
		BackgroundManager.setup_zone_background(self, current_zone_id)
		print("✅ Fondo de zona actualizado:", current_zone_id)
	else:
		# Fallback manual si BackgroundManager no está disponible
		setup_fallback_zone_background(current_zone_id)

func setup_fallback_zone_background(zone_id: String):
	"""Fallback para fondo de zona sin BackgroundManager"""
	if not Content:
		setup_color_background(zone_id)
		return

	var zone_def = Content.get_zone_by_id(zone_id)
	if zone_def and zone_def.background:
		var texture = load(zone_def.background)
		if texture:
			# Convertir ColorRect a TextureRect si es necesario
			if background_node is ColorRect:
				var parent = background_node.get_parent()
				var old_index = background_node.get_index()

				background_node.queue_free()

				var new_background = TextureRect.new()
				new_background.name = "Background"
				new_background.layout_mode = 1
				new_background.anchor_right = 1.0
				new_background.anchor_bottom = 1.0
				new_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				new_background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				new_background.texture = texture

				parent.add_child(new_background)
				parent.move_child(new_background, old_index)
				background_node = new_background
			elif background_node is TextureRect:
				background_node.texture = texture
				background_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				background_node.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		else:
			setup_color_background(zone_id)
	else:
		setup_color_background(zone_id)

func setup_texture_background(background_path: String):
	"""Convertir ColorRect a TextureRect para mostrar imagen"""
	if not background_node or not background_node.get_parent():
		return

	var parent = background_node.get_parent()
	var old_position = background_node.get_index()

	# Remover el ColorRect anterior
	background_node.queue_free()

	# Crear nuevo TextureRect
	var new_background = TextureRect.new()
	new_background.name = "Background"
	new_background.layout_mode = 1
	new_background.anchor_right = 1.0
	new_background.anchor_bottom = 1.0
	new_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	new_background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

	# Cargar textura
	var texture = load(background_path)
	if texture:
		new_background.texture = texture

	# Añadir al parent en la misma posición
	parent.add_child(new_background)
	parent.move_child(new_background, old_position)

	# Actualizar referencia
	background_node = new_background

func setup_color_background(zone_id: String):
	"""Configurar fondo de color sólido como fallback"""
	if not background_node:
		return

	# Si es TextureRect, convertir a ColorRect
	if background_node is TextureRect:
		var parent = background_node.get_parent()
		var old_position = background_node.get_index()

		background_node.queue_free()

		var new_background = ColorRect.new()
		new_background.name = "Background"
		new_background.layout_mode = 1
		new_background.anchor_right = 1.0
		new_background.anchor_bottom = 1.0
		new_background.color = get_zone_color(zone_id)

		parent.add_child(new_background)
		parent.move_child(new_background, old_position)

		background_node = new_background
	elif background_node is ColorRect:
		background_node.color = get_zone_color(zone_id)

func get_zone_color(zone_id: String) -> Color:
	"""Obtener color representativo para cada zona"""
	var zone_colors = {
		"orilla": Color(0.2, 0.5, 0.8), # Azul agua
		"lago": Color(0.1, 0.4, 0.6), # Azul lago
		"rio": Color(0.3, 0.6, 0.4), # Verde río
		"costa": Color(0.4, 0.7, 0.9), # Azul claro
		"mar": Color(0.1, 0.3, 0.7) # Azul profundo
	}
	return zone_colors.get(zone_id, Color(0.2, 0.5, 0.8))
