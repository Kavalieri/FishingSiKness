class_name FishingView
extends Control

signal fish_caught(fish_name: String, value: int)

var cast_button: Button
var inventory_button: Button

# Nuevo sistema QTE visual
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

# Peces básicos temporales
var available_fish := []

func _ready():
	setup_temp_fish()
	setup_qte_ui()

	# Obtener referencias básicas
	cast_button = $GameplayArea/CastButton
	if cast_button:
		cast_button.pressed.connect(_on_cast_button_pressed)

	setup_inventory_button()
	print("FishingView ready")

func setup_qte_ui():
	# Crear contenedor para el QTE
	qte_container = VBoxContainer.new()
	qte_container.visible = false
	qte_container.add_theme_constant_override("separation", 15)

	var gameplay_area = $GameplayArea
	if gameplay_area:
		gameplay_area.add_child(qte_container)

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

func setup_inventory_button():
	inventory_button = Button.new()
	inventory_button.text = "🗑️ Gestionar Inventario"
	inventory_button.custom_minimum_size = Vector2(200, 50)
	inventory_button.pressed.connect(_on_inventory_button_pressed)

	var gameplay_area = $GameplayArea
	if gameplay_area:
		gameplay_area.add_child(inventory_button)

func setup_temp_fish():
	var sardina = FishDef.new()
	sardina.id = "sardina"
	sardina.name = "Sardina"
	sardina.rarity = 0
	sardina.base_price = 12
	sardina.size_min = 8.0
	sardina.size_max = 15.0

	var trucha = FishDef.new()
	trucha.id = "trucha"
	trucha.name = "Trucha"
	trucha.rarity = 1
	trucha.base_price = 22
	trucha.size_min = 15.0
	trucha.size_max = 30.0

	var carpa = FishDef.new()
	carpa.id = "carpa"
	carpa.name = "Carpa"
	carpa.rarity = 1
	carpa.base_price = 18
	carpa.size_min = 12.0
	carpa.size_max = 25.0

	var boqueron = FishDef.new()
	boqueron.id = "boqueron"
	boqueron.name = "Boquerón"
	boqueron.rarity = 0
	boqueron.base_price = 10
	boqueron.size_min = 6.0
	boqueron.size_max = 12.0

	available_fish = [sardina, trucha, carpa, boqueron]

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
	if qte_container:
		qte_container.visible = true

	cast_button.text = "🎯 ¡ATRAPAR!"

func try_catch_fish():
	if not qte_active:
		return

	print("Trying to catch fish... QTE progress: ", qte_progress)

	var success = qte_progress >= qte_target_min and qte_progress <= qte_target_max

	# Terminar QTE
	qte_active = false
	is_fishing = false
	if qte_container:
		qte_container.visible = false

	cast_button.text = "🎣 LANZAR"

	if success:
		catch_successful()
	else:
		qte_failed()

func catch_successful():
	if available_fish.size() > 0:
		var random_fish = available_fish[randi() % available_fish.size()]
		# Generar tamaño aleatorio dentro del rango del pez
		var random_size = randf_range(random_fish.size_min, random_fish.size_max)
		var fish_instance = FishInstance.new(random_fish, random_size)

		Save.add_fish(fish_instance)
		show_catch_message(fish_instance, true)
		emit_signal("fish_caught", fish_instance.fish_def.name, fish_instance.value)

		# Añadir experiencia por captura exitosa
		if Experience:
			var xp_gained = calculate_xp_reward(fish_instance)
			Experience.add_experience(xp_gained)

		if SFX:
			SFX.play_event("success")

		print("Caught: ", fish_instance.fish_def.name, " worth ", fish_instance.value, " coins")

func calculate_xp_reward(fish_instance: FishInstance) -> int:
	"""Calcular XP basado en rareza y tamaño del pez"""
	var base_xp = 10
	var rarity_bonus = fish_instance.fish_def.rarity * 5
	var size_ratio = fish_instance.size / fish_instance.fish_def.size_max
	var size_bonus = int(size_ratio * 10)

	return base_xp + rarity_bonus + size_bonus

func qte_failed():
	show_catch_message(null, false)
	if SFX:
		SFX.play_event("error")
	print("Fish got away!")

func show_catch_message(fish_instance: FishInstance, success: bool):
	var message = Label.new()

	if success and fish_instance:
		message.text = "🎉 ¡Pescaste un %s!\n💰 +%d monedas\n📏 %.1fcm" % [
			fish_instance.fish_def.name,
			fish_instance.value,
			fish_instance.size
		]
		message.add_theme_color_override("font_color", Color.LIME_GREEN)
	else:
		message.text = "💔 ¡El pez se escapó!\n⏱️ ¡Sé más rápido la próxima vez!"
		message.add_theme_color_override("font_color", Color.ORANGE)

	message.add_theme_font_size_override("font_size", 16)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.position = Vector2(50, 150)
	add_child(message)

	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(message.queue_free)

func show_inventory_full_message():
	var message = Label.new()
	message.text = "🧊 ¡Inventario lleno!\n🗑️ Usa 'Gestionar Inventario' para liberar espacio"
	message.add_theme_font_size_override("font_size", 18)
	message.add_theme_color_override("font_color", Color.ORANGE)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.position = Vector2(50, 200)
	add_child(message)

	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(message.queue_free)

	if SFX:
		SFX.play_event("error")

func _on_inventory_button_pressed():
	var screen_manager = get_tree().current_scene
	if screen_manager and screen_manager.has_method("show_inventory_discard_mode"):
		screen_manager.show_inventory_discard_mode()
		if SFX:
			SFX.play_event("click")
