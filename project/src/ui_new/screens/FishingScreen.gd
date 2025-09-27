class_name FishingScreen
extends Control

# Pantalla principal de pesca según especificación

signal fishing_cast_requested
signal auto_cast_toggled(enabled: bool)
signal stats_requested
signal fish_caught(fish_data: Dictionary)

var current_zone: Dictionary = {}
var is_auto_casting: bool = false
var fishing_stats: Dictionary = {}
var is_fishing: bool = false

@onready var background: TextureRect = $Background
@onready var cast_button: Button = $VBoxContainer/MarginContainer/ContentVBox/FishingArea/CastButton
@onready var auto_cast_button: Button = $VBoxContainer/MarginContainer/ContentVBox/BottomButtonsContainer/BottomPanel/AutoCastButton
@onready var stats_button: Button = $VBoxContainer/MarginContainer/ContentVBox/BottomButtonsContainer/BottomPanel/StatsButton
@onready var qte_container = $QTEContainer

# Panel de estadísticas
var stats_panel: Control



# Instancia de la ventana de captura
var capture_window: Control = null
var stats_window: AcceptDialog = null

func _ready() -> void:
	_connect_signals()
	_sync_with_fishing_manager()
	_setup_capture_window()

	# ÚNICA FUENTE DE VERDAD: Cargar estadísticas desde UnifiedInventorySystem
	call_deferred("_update_fishing_stats_from_inventory")
	
	# Timer para actualizar botón cada segundo
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_cast_button_text)
	timer.autostart = true
	add_child(timer)
	
	# Actualizar estado inicial de auto-pesca
	call_deferred("update_auto_cast_state", false)

func _connect_signals() -> void:
	cast_button.pressed.connect(_on_cast_button_pressed)
	auto_cast_button.pressed.connect(_on_auto_cast_toggled)
	stats_button.pressed.connect(_on_stats_button_pressed)

	# Conectar señales del QTE Container unificado
	if qte_container and qte_container.has_signal("qte_success"):
		qte_container.qte_success.connect(_on_qte_success)
		qte_container.qte_failed.connect(_on_qte_failed)
		qte_container.qte_timeout.connect(_on_qte_timeout)
		# Nuevas señales para resultado
		qte_container.fish_kept.connect(_on_fish_kept)
		qte_container.fish_released.connect(_on_fish_released)
	else:
		print("⚠️ QTEContainer no disponible o sin señales correctas")
	
	if AutoFishingSystem:
		AutoFishingSystem.auto_fishing_toggled.connect(_on_auto_fishing_toggled)
		AutoFishingSystem.auto_catch_made.connect(_on_auto_catch_made)
	
	if EnergySystem:
		EnergySystem.energy_changed.connect(_on_energy_changed_fishing)

func _sync_with_fishing_manager() -> void:
	"""Sincronizar con sistemas de pesca"""
	# Conectar con Content para obtener datos de peces
	if Content:
		print("Content system disponible para datos de peces")

func _setup_capture_window() -> void:
	"""Configurar la ventana de captura (ya no se usa, mantenido para compatibilidad)"""
	# La ventana de captura ahora se maneja en el QTE unificado
	pass

	# La ventana de estadísticas se creará dinámicamente cuando se necesite
	stats_window = null

	# Conectar con SFX para sonidos
	if SFX:
		print("SFX system disponible para efectos de sonido")

	# TODO: Integrar con FishingSystem cuando esté disponible como autoload

func _update_fishing_stats_from_inventory() -> void:
	"""ÚNICA FUENTE DE VERDAD: Actualizar estadísticas desde UnifiedInventorySystem"""
	print("📊 [DEBUG] Actualizando estadísticas desde UnifiedInventorySystem...")

	# Leer SOLO desde UnifiedInventorySystem
	var fishing_container = UnifiedInventorySystem.get_fishing_container()
	if not fishing_container:
		print("📊 [DEBUG] No se pudo obtener contenedor de pesca")
		return

	# Calcular estadísticas desde los peces en el inventario
	var total_fish = fishing_container.items.size()
	var total_value = 0
	var fish_by_species = {}

	for item in fishing_container.items:
		var fish_data = item.to_fish_data()
		total_value += fish_data.get("value", 0)

		var species = fish_data.get("name", "Desconocido")
		fish_by_species[species] = fish_by_species.get(species, 0) + 1

	# Actualizar estadísticas locales
	fishing_stats = {
		"total_fish_caught": total_fish,
		"total_value": total_value,
		"species_caught": fish_by_species,
		"inventory_count": total_fish
	}

	print("📊 [DEBUG] Estadísticas actualizadas: %d peces, valor total: %d" % [total_fish, total_value])

	# Si hay ventana de estadísticas abierta, actualizarla
	if stats_window and stats_window.visible:
		_update_stats_window_display()

func _update_stats_window_display() -> void:
	"""Actualizar el display de la ventana de estadísticas"""
	if not stats_window or not stats_window.has_method("update_stats"):
		return

	stats_window.update_stats(fishing_stats)

func setup_fishing_screen(zone_def, stats: Dictionary) -> void:
	"""Configurar pantalla de pesca con zona y estadísticas"""
	# Convertir ZoneDef a Dictionary interno para compatibilidad con código existente
	current_zone = {}
	if zone_def:
		current_zone = {
			"id": zone_def.id,
			"name": zone_def.name,
			"price_multiplier": zone_def.price_multiplier,
			"background_path": zone_def.background
		}

	fishing_stats = stats

	_update_zone_background()
	_update_fishing_display()

func _update_zone_background() -> void:
	"""Actualizar fondo según la zona actual (compatible con fondo único global)"""
	# En la nueva arquitectura, el fondo se maneja globalmente en Main.tscn
	# Esta función puede comunicarse con Main para cambiar el fondo
	var zone_background = current_zone.get("background_path", "")
	if zone_background != "":
		# TODO: Comunicar con Main para cambio de fondo
		# Main.set_background(zone_background)
		pass

func _update_fishing_display() -> void:
	"""Actualizar elementos de visualización de pesca"""
	# Actualizar texto del botón según estado
	set_casting_state(is_fishing)

func show_caught_fish(fish_data: Dictionary) -> void:
	"""Mostrar pez capturado (ahora se maneja en QTE y ventana de captura)"""
	# La visualización del pez se maneja ahora en el QTE y la ventana de captura
	# Esta función se mantiene para compatibilidad pero ya no necesita hacer animaciones redundantes
	print("🐟 [UI] Pez capturado: %s" % fish_data.get("name", "desconocido"))

func set_casting_state(is_casting: bool) -> void:
	"""Establecer estado de lanzamiento"""
	cast_button.disabled = is_casting
	if is_casting:
		cast_button.text = "Lanzando..."
	else:
		_update_cast_button_text()

func _update_cast_button_text() -> void:
	"""Actualizar texto del botón con energía y tiempo"""
	if not EnergySystem:
		cast_button.text = "Lanzar Caña"
		return
	
	var current = EnergySystem.current_energy
	var max_energy = EnergySystem.max_energy
	
	# Texto base con energía
	var button_text = "Lanzar Caña (%d/%d)" % [current, max_energy]
	
	# Añadir tiempo si no está completa
	if current < max_energy:
		var time_to_next = EnergySystem.get_time_to_next_recharge()
		var minutes = int(time_to_next / 60)
		var seconds = int(time_to_next) % 60
		button_text += "\nPróxima: %02d:%02d" % [minutes, seconds]
	else:
		button_text += "\nCompleta"
	
	cast_button.text = button_text
	
	# Cambiar color según energía
	if current == 0:
		cast_button.modulate = Color.RED
		cast_button.disabled = true
	elif current <= 3:
		cast_button.modulate = Color.ORANGE
		cast_button.disabled = false
	else:
		cast_button.modulate = Color.WHITE
		cast_button.disabled = false

func update_auto_cast_state(enabled: bool) -> void:
	"""Actualizar estado del auto-cast"""
	is_auto_casting = enabled
	
	# Verificar si está desbloqueado
	if AutoFishingSystem and not AutoFishingSystem.is_unlocked():
		auto_cast_button.text = "Auto Pesca: LVL 10"
		auto_cast_button.modulate = Color.GRAY
		auto_cast_button.disabled = true
		return
	
	auto_cast_button.disabled = false
	if enabled:
		auto_cast_button.text = "Auto Pesca: ON"
		auto_cast_button.modulate = Color.LIGHT_GREEN
	else:
		auto_cast_button.text = "Auto Pesca: OFF"
		auto_cast_button.modulate = Color.WHITE

func _on_cast_button_pressed() -> void:
	"""Manejar lanzamiento manual"""
	print("[DEBUG] Botón de lanzar caña presionado")
	if not is_fishing:
		# Verificar energía
		if EnergySystem and not EnergySystem.can_cast():
			print("[DEBUG] Sin energía")
			_show_no_energy_message()
			return
		
		# Verificar espacio en inventario
		if not _has_inventory_space():
			print("[DEBUG] Inventario lleno")
			_show_inventory_full_message()
			return
		
		_start_fishing()
	else:
		fishing_cast_requested.emit()

func _start_fishing() -> void:
	"""Iniciar proceso de pesca con QTE"""
	print("[DEBUG] Iniciando pesca...")
	if is_fishing:
		return
	
	# Consumir energía
	if EnergySystem:
		if not EnergySystem.consume_energy():
			print("[DEBUG] No se pudo consumir energía")
			return
		print("[DEBUG] Energía consumida")
		# Guardar inmediatamente después de consumir energía
		if Save:
			Save.save_game()
	
	# Registrar lanzamiento
	if StatsTracker:
		StatsTracker.record_cast()

	is_fishing = true
	set_casting_state(true)

	# Simular tiempo de lanzamiento
	await get_tree().create_timer(0.5).timeout

	# Iniciar QTE
	_start_qte_event()

func _start_qte_event() -> void:
	"""Iniciar evento QTE clásico de pesca"""
	var qte_duration = 5.0  # Tiempo fijo para QTE clásico

	# Pre-generar datos de pez para mostrar icono correcto
	var preview_fish = _generate_caught_fish()
	var fish_icon_texture = preview_fish.get("icon", null)

	print("🎣 [QTE] Iniciando QTE clásico con pez: %s" % preview_fish.get("name", "desconocido"))
	print("🎣 [QTE] Sprite disponible: %s" % (fish_icon_texture != null))
	if fish_icon_texture:
		print("🎣 [QTE] Tamaño sprite: %dx%d" % [fish_icon_texture.get_width(), fish_icon_texture.get_height()])

	# Reproducir sonido de anzuelo
	if SFX and SFX.has_method("play_event"):
		SFX.play_event("qte")

	# Iniciar QTE clásico (sin parámetros de tipo)
	qte_container.start_qte(
		null,  # No hay tipos múltiples
		qte_duration,
		1,  # No usado en QTE clásico
		fish_icon_texture,
		"¡Presiona cuando la aguja esté en la zona verde!"
	)

	# Guardar datos del pez para cuando se complete el QTE
	set_meta("preview_fish", preview_fish)

func _on_qte_success() -> void:
	"""QTE exitoso - pero el pez puede escapar"""
	print("[DEBUG] QTE exitoso")
	
	# Generar pez con posibilidad de escape
	var caught_fish = _generate_caught_fish()
	
	# Verificar si el pez escapó
	if caught_fish.get("escaped", false):
		print("[DEBUG] El pez escapó después del QTE exitoso")
		_handle_fish_escaped(caught_fish)
		return

	# Reproducir sonido de captura
	if SFX and SFX.has_method("play_event"):
		SFX.play_event("capture")

	# Transformar QTE en ventana de resultado
	qte_container.show_result(caught_fish)

	# Guardar datos para procesamiento posterior
	set_meta("current_fish", caught_fish)

func _on_qte_failed() -> void:
	"""QTE fallido - pez escapó"""
	is_fishing = false
	set_casting_state(false)
	
	# Registrar escape
	if StatsTracker:
		StatsTracker.record_fish_escaped()

	# Reproducir sonido de fallo
	if SFX and SFX.has_method("play_event"):
		SFX.play_event("fail")

	# Mostrar mensaje de escape
	_show_escape_message()

	# Limpiar metadata
	remove_meta("preview_fish")
	remove_meta("current_fish")
	
	# Asegurar que QTE esté oculto
	if qte_container:
		qte_container.visible = false

func _on_qte_timeout() -> void:
	"""QTE timeout - sin actividad"""
	is_fishing = false
	set_casting_state(false)

	# Mostrar mensaje de timeout
	_show_timeout_message()

	# Limpiar metadata
	remove_meta("preview_fish")
	remove_meta("current_fish")
	
	# Asegurar que QTE esté oculto
	if qte_container:
		qte_container.visible = false

func _on_fish_kept() -> void:
	"""Pez guardado desde ventana de resultado"""
	var fish_data = get_meta("current_fish", {})
	if not fish_data.is_empty():
		_process_caught_fish(fish_data)
	remove_meta("current_fish")
	
	# Resetear estado de pesca
	is_fishing = false
	set_casting_state(false)

func _on_fish_released() -> void:
	"""Pez liberado desde ventana de resultado"""
	var fish_data = get_meta("current_fish", {})
	if not fish_data.is_empty():
		_show_release_message(fish_data)
	remove_meta("current_fish")
	
	# Resetear estado de pesca
	is_fishing = false
	set_casting_state(false)

func _show_escape_message() -> void:
	"""Mostrar mensaje de pez escapado"""
	# TODO: Implementar notificación visual
	print("¡El pez escapó!")

func _show_timeout_message() -> void:
	"""Mostrar mensaje de timeout"""
	# TODO: Implementar notificación visual
	print("No hubo actividad...")

func _handle_fish_escaped(fish_data: Dictionary) -> void:
	"""Manejar cuando un pez escapa después de QTE exitoso"""
	is_fishing = false
	set_casting_state(false)
	
	# Registrar escape
	if StatsTracker:
		StatsTracker.record_fish_escaped()
	
	# Mostrar mensaje de escape
	var dialog = AcceptDialog.new()
	dialog.title = "¡Pez Escapado!"
	dialog.dialog_text = "¡El %s (%s) logró escapar!\nLos peces más raros son más difíciles de capturar." % [
		fish_data.get("name", "pez"),
		fish_data.get("rarity", "común")
	]
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())
	
	# Reproducir sonido de escape
	if SFX and SFX.has_method("play_event"):
		SFX.play_event("fail")
	
	# Ocultar QTE
	if qte_container:
		qte_container.visible = false

func _calculate_experience_from_fish(fish_data: Dictionary) -> int:
	"""Calcular experiencia para progresión rápida inicial"""
	var value = fish_data.get("value", 0)
	var base_xp = max(8, int(value * 0.3))  # 30% del valor, mínimo 8 XP
	
	# Bonus por rareza
	var rarity_value = fish_data.get("rarity_value", 1)
	var rarity_bonus = (rarity_value - 1) * 5  # +5 XP por nivel de rareza
	
	var total_xp = base_xp + rarity_bonus
	print("[XP] Pez valor %d, rareza %d → %d XP" % [value, rarity_value, total_xp])
	return total_xp

func _generate_caught_fish() -> Dictionary:
	"""Usar datos ya generados por Content system"""
	var zone_id = current_zone.get("id", "lago_montana_alpes")
	
	if Content and Content.has_method("get_random_fish_for_zone"):
		var fish_data = Content.get_random_fish_for_zone(zone_id)
		
		if not fish_data.is_empty():
			# Datos base desde Content
			var actual_size = fish_data.get("size", 20.0)
			var base_rarity = fish_data.get("rarity", 1)
			var base_value = fish_data.get("base_market_value", 20)
			var zone_multiplier = fish_data.get("zone_multiplier", 1.0)
			var size_min = fish_data.get("size_min", 10.0)
			var size_max = fish_data.get("size_max", 30.0)
			
			# Calcular peso realista
			var expected_weight = pow(actual_size, 3) * 0.008
			var weight_variation = randf_range(0.75, 1.25)
			var actual_weight = max(expected_weight * weight_variation, pow(actual_size, 2) * 0.01)
			
			# Calcular rareza final basada en tamaño y peso
			var size_ratio = (actual_size - size_min) / (size_max - size_min)
			var weight_ratio = (weight_variation - 0.75) / 0.5
			var excellence_score = (size_ratio * 0.7) + (weight_ratio * 0.3)
			
			var excellence_bonus = 0
			if excellence_score >= 0.85:
				excellence_bonus = 2
			elif excellence_score >= 0.70:
				excellence_bonus = 1
			
			var final_rarity = min(4, base_rarity + excellence_bonus)
			
			var rarity_names = ["", "común", "raro", "épico", "legendario"]
			var rarity_name = rarity_names[final_rarity] if final_rarity < rarity_names.size() else "común"
			
			# Calcular valor final
			var rarity_multipliers = [1.0, 1.0, 1.5, 2.0, 3.0]
			var rarity_mult = rarity_multipliers[final_rarity] if final_rarity < rarity_multipliers.size() else 1.0
			var size_bonus = size_ratio * 0.3
			var weight_bonus = weight_ratio * 0.2
			var final_value = int(base_value * zone_multiplier * rarity_mult * (1.0 + size_bonus + weight_bonus))
			
			# Probabilidad de escape
			if randf() < (0.03 + (final_rarity - 1) * 0.02):
				return {"escaped": true, "name": fish_data.get("name", "Pez"), "rarity": rarity_name}
			
			print("🐟 [Fish Gen] %s: %.1fcm, %.1fg, %s (%d), %d monedas" % [
				fish_data.get("name"), actual_size, actual_weight, rarity_name, final_rarity, final_value
			])
			
			return {
				"id": fish_data.get("id", "unknown"),
				"name": fish_data.get("name", "Pez"),
				"size": actual_size,
				"weight": actual_weight,
				"rarity": rarity_name,
				"rarity_value": final_rarity,
				"value": final_value,
				"zone_caught": zone_id,
				"icon": fish_data.get("icon", null)
			}
	
	return {"id": "fallback", "name": "Pez", "size": 20.0, "weight": 100.0, "rarity": "común", "rarity_value": 1, "value": 20, "zone_caught": zone_id}


func _load_fish_icon(fish_name: String) -> Texture2D:
	"""Cargar icono de pez con fallback usando ResourceLoader"""
	var icon_path = "res://art/fish/%s.png" % fish_name

	# Verificar si el archivo existe antes de cargarlo
	if ResourceLoader.exists(icon_path):
		var texture = ResourceLoader.load(icon_path, "Texture2D")
		if texture:
			return texture

	# Fallback al primer pez disponible
	var fallback_path = "res://art/fish/sardina.png"
	if ResourceLoader.exists(fallback_path):
		return ResourceLoader.load(fallback_path, "Texture2D")

	# Si incluso el fallback falla, devolver null
	print("⚠️ No se pudo cargar ningún sprite de pez para: %s" % fish_name)
	return null

func _on_auto_cast_toggled() -> void:
	"""Manejar toggle del auto-cast"""
	print("[DEBUG] Botón auto-cast presionado")
	
	# Verificar si está desbloqueado
	if AutoFishingSystem and not AutoFishingSystem.is_unlocked():
		_show_auto_fishing_locked_message()
		return
	
	# Si ya está activo, mostrar menú de configuración
	if AutoFishingSystem and AutoFishingSystem.is_auto_fishing:
		_show_auto_fishing_config()
		return
	
	# Activar auto-pesca
	if AutoFishingSystem:
		AutoFishingSystem.toggle_auto_fishing()
	else:
		# Fallback
		is_auto_casting = not is_auto_casting
		update_auto_cast_state(is_auto_casting)
		auto_cast_toggled.emit(is_auto_casting)

func _on_stats_button_pressed() -> void:
	"""Mostrar estadísticas/historial de capturas"""
	print("[DEBUG] Botón de estadísticas presionado")
	
	if stats_window:
		print("[DEBUG] Ventana ya existe, cerrando")
		stats_window.queue_free()
		stats_window = null
		return
	
	# Crear ventana simple funcional
	stats_window = AcceptDialog.new()
	stats_window.title = "Estadísticas de Pesca"
	
	# Obtener datos de estadísticas
	var stats_text = "ESTADÍSTICAS DE PESCA\n\n"
	if StatsTracker:
		var stats = StatsTracker.get_formatted_stats()
		stats_text += "HOY:\n"
		stats_text += "Peces capturados: %s\n" % stats.today.fish_caught
		stats_text += "Valor ganado: %s monedas\n" % stats.today.value_earned
		stats_text += "Racha actual: %s\n" % stats.today.current_streak
		stats_text += "Tasa de éxito: %s\n\n" % stats.today.success_rate
		
		stats_text += "TOTAL:\n"
		stats_text += "Peces capturados: %s\n" % stats.total.fish_caught
		stats_text += "Valor ganado: %s monedas\n" % stats.total.value_earned
		stats_text += "Mejor racha: %s\n" % stats.total.best_streak
		stats_text += "Tasa de éxito: %s\n\n" % stats.total.success_rate
	else:
		stats_text += "Sistema de estadísticas no disponible\n\n"
	
	# Agregar historial desde Save
	stats_text += "HISTORIAL RECIENTE:\n"
	if Save:
		var history = Save.get_recent_catches(5)
		print("[DEBUG] Historial obtenido: %d entradas" % history.size())
		if history.size() > 0:
			for catch_entry in history:
				var status = "(Vendido)" if catch_entry.get("is_sold", false) else "(En inventario)"
				stats_text += "- %s (%s) - %d monedas %s\n" % [
					catch_entry.get("fish_name", "Pez"),
					catch_entry.get("rarity", "común"),
					catch_entry.get("value", 0),
					status
				]
		else:
			stats_text += "No hay capturas recientes"
	else:
		stats_text += "Sistema no disponible"
	
	stats_window.dialog_text = stats_text
	get_tree().current_scene.add_child(stats_window)
	stats_window.popup_centered(Vector2i(400, 500))
	stats_window.confirmed.connect(_on_stats_window_closed)
	stats_window.close_requested.connect(_on_stats_window_closed)
	
	stats_requested.emit()

func _on_stats_window_closed() -> void:
	"""Manejar cierre de ventana de estadísticas"""
	stats_window = null
	# Asegurar que el input esté liberado
	get_viewport().set_input_as_handled()

# OBSOLETO: Botones removidos para simplificar UI
# func _on_boosters_button_pressed() -> void:
#	"""Mostrar potenciadores disponibles"""
#	boosters_requested.emit()

func _on_fish_sold(fish_data: Dictionary, value: int) -> void:
	"""Pez vendido (función legacy)"""
	if Save and Save.has_method("add_coins"):
		Save.add_coins(value)

	# Mostrar mensaje de venta
	_show_sale_message(fish_data, value)

func _on_capture_window_closed() -> void:
	"""Ventana de captura cerrada sin acción"""
	pass

func _process_caught_fish(fish_data: Dictionary) -> void:
	"""Procesar pez capturado - ÚNICA FUENTE DE VERDAD: UnifiedInventorySystem"""
	print("🐟 [DEBUG] INICIANDO PROCESO DE CAPTURA")
	print("🐟 [DEBUG] Fish data recibido: %s" % str(fish_data))
	print("🐟 [DEBUG] UnifiedInventorySystem disponible: %s" % (UnifiedInventorySystem != null))

	# FUENTE DE VERDAD: Solo UnifiedInventorySystem maneja el inventario real
	# Asegurar que el pez tiene zona actual
	var current_zone_id = current_zone.get("id", Save.game_data.get("current_zone", "lago_montana_alpes"))
	fish_data["zone_caught"] = current_zone_id
	fish_data["timestamp"] = Time.get_unix_time_from_system()
	
	var item_instance = ItemInstance.new()
	item_instance.from_fish_data({
		"id": fish_data.get("id", "unknown_fish"),
		"name": fish_data.get("name", "Pez desconocido"),
		"size": fish_data.get("size", 10.0),
		"value": int(fish_data.get("value", 10)),
		"zone_caught": current_zone_id,
		"timestamp": Time.get_unix_time_from_system()
	})

	print("🐟 [DEBUG] ItemInstance creado: %s" % str(item_instance))
	print("🐟 [DEBUG] Intentando añadir al contenedor 'fishing'...")

	# ÚNICA FUENTE DE VERDAD: Añadir solo al UnifiedInventorySystem
	if UnifiedInventorySystem.add_item(item_instance, "fishing"):
		print("✅ [DEBUG] Pez añadido al UnifiedInventorySystem: %s" % fish_data.get("name", "Pez"))

		# Registrar captura en estadísticas
		if StatsTracker:
			StatsTracker.record_fish_caught(fish_data)
		
		# Otorgar experiencia basada en el valor del pez
		var xp_gained = _calculate_experience_from_fish(fish_data)
		print("✨ [DEBUG] Calculando XP: valor %d → %d XP" % [fish_data.get("value", 0), xp_gained])
		
		if Experience:
			Experience.add_experience(xp_gained)
			print("✨ [DEBUG] XP otorgada exitosamente")
		else:
			print("✨ [ERROR] Experience system no disponible")
		
			# Añadir a la base de datos de capturas
		var catch_id = ""
		if Save:
			catch_id = Save.add_catch_to_database(fish_data)
			print("✅ [DEBUG] Añadido a BD con ID: %s" % catch_id)
			# Agregar ID de captura al item_instance
			item_instance.instance_data["catch_id"] = catch_id

		# Guardar el juego después de añadir el pez
		if Save:
			Save.save_game()
			print("💾 [DEBUG] Juego guardado después de capturar pez")
		else:
			print("🚨 [DEBUG] Save no disponible")

		# NO necesitamos recargar UnifiedInventorySystem
		# El mercado lee directamente desde la base de datos
		
		# Actualizar estadísticas locales desde UnifiedInventorySystem
		_update_fishing_stats_from_inventory()
		print("📊 [DEBUG] Estadísticas actualizadas desde inventario")
	else:
		print("🚨 [DEBUG] Error: No se pudo añadir el pez al inventario")
		return # No continuar si falla

	print("🐟 [DEBUG] Mostrando pez capturado y emitiendo señal...")
	show_caught_fish(fish_data)
	fish_caught.emit(fish_data)
	print("🐟 [DEBUG] PROCESO DE CAPTURA COMPLETADO")

func _show_sale_message(fish_data: Dictionary, value: int) -> void:
	"""Mostrar mensaje de venta"""
	print("¡%s vendido por %d monedas!" % [fish_data.get("name", "Pez"), value])

func _show_release_message(fish_data: Dictionary) -> void:
	"""Mostrar mensaje de liberación"""
	print("¡%s liberado!" % fish_data.get("name", "Pez"))
	# TODO: Añadir notificación visual si es necesario

func _show_no_energy_message() -> void:
	"""Mostrar mensaje de energía agotada"""
	var dialog = AcceptDialog.new()
	dialog.title = "Sin Energía"
	dialog.dialog_text = "No tienes energía para lanzar.\nEspera a que se recargue o usa gemas."
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func _show_auto_fishing_locked_message() -> void:
	"""Mostrar mensaje de auto-pesca bloqueada"""
	var dialog = AcceptDialog.new()
	dialog.title = "Auto-Pesca Bloqueada"
	dialog.dialog_text = "La auto-pesca se desbloquea en el nivel 10."
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func _has_inventory_space() -> bool:
	"""Verificar si hay espacio en inventario"""
	if not UnifiedInventorySystem:
		print("[DEBUG] UnifiedInventorySystem no disponible")
		return true
	
	var fishing_container = UnifiedInventorySystem.get_fishing_container()
	if not fishing_container:
		print("[DEBUG] Contenedor de pesca no disponible")
		return true
	
	var current_items = fishing_container.items.size()
	var max_capacity = fishing_container.capacity
	var has_space = current_items < max_capacity
	
	print("[DEBUG] Inventario: %d/%d, espacio: %s" % [current_items, max_capacity, has_space])
	return has_space

func _show_inventory_full_message() -> void:
	"""Mostrar mensaje de inventario lleno"""
	var dialog = AcceptDialog.new()
	dialog.title = "Inventario Lleno"
	dialog.dialog_text = "Tu inventario está lleno.\nVe al mercado para vender o descartar peces."
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func _show_auto_fishing_config() -> void:
	"""Mostrar menú de configuración de auto-pesca"""
	var dialog = AcceptDialog.new()
	dialog.title = "Configuración Auto-Pesca"
	
	var config_text = "AUTO-PESCA ACTIVA\n\n"
	if AutoFishingSystem:
		var filters = AutoFishingSystem.filters
		config_text += "Configuración actual:\n"
		config_text += "Rareza mínima: %s\n" % filters.get("min_rarity", "común")
		config_text += "Valor mínimo: %d monedas\n" % filters.get("min_value", 0)
		config_text += "Auto-venta: %s\n\n" % ("Sí" if filters.get("auto_sell", false) else "No")
		config_text += "Presiona OK para detener auto-pesca\n"
		config_text += "o cierra para mantener activa"
	else:
		config_text += "Sistema no disponible"
	
	dialog.dialog_text = config_text
	dialog.get_ok_button().text = "Detener Auto-Pesca"
	dialog.add_cancel_button("Mantener Activa")
	
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered(Vector2i(350, 250))
	
	dialog.confirmed.connect(func(): 
		if AutoFishingSystem:
			AutoFishingSystem.toggle_auto_fishing()
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())



func _on_auto_fishing_toggled(enabled: bool) -> void:
	"""Manejar cambio de estado de auto-pesca"""
	update_auto_cast_state(enabled)

func _on_auto_catch_made(fish_data: Dictionary) -> void:
	"""Manejar captura automática"""
	print("[AutoFishing] Capturado automáticamente: %s" % fish_data.get("name", "Pez"))
	# Actualizar estadísticas
	_update_fishing_stats_from_inventory()

func _on_energy_changed_fishing(current: int, max_energy: int) -> void:
	"""Actualizar botón cuando cambia la energía"""
	if not is_fishing:
		_update_cast_button_text()






