extends Control
class_name SaveWindow
## Ventana de guardado/carga con múltiples slots
##
## Permite guardar y cargar partidas en diferentes slots
## Usa la arquitectura UI-BG-GLOBAL con estilos translúcidos

signal window_closed()
signal game_loaded(slot_id: int)
signal game_saved(slot_id: int)

# Referencias a nodos UI
@onready var overlay: ColorRect = $Overlay
@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer
@onready var slots_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/SlotsContainer
@onready var auto_save_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsContainer/AutoSaveButton
@onready var close_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsContainer/CloseButton

# Datos de slots
var save_slots: Array[Dictionary] = []

func _ready() -> void:
	print("[SaveWindow] Inicializando ventana de guardado...")

	# Configurar estilo translúcido
	_setup_translucent_style()

	# Cargar información de slots
	_load_save_slots()

	# Conectar señales
	_connect_signals()

	# Configurar tooltips
	_setup_tooltips()

	# Animar entrada
	_animate_show()

	print("[SaveWindow] ✓ Ventana de guardado lista")

func _setup_translucent_style() -> void:
	"""Configurar estilo translúcido"""
	# Configurar overlay para recibir input
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS

	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	style_box.border_width_left = 1
	style_box.border_width_right = 1
	style_box.border_width_top = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color(0.3, 0.3, 0.3, 0.7)

	panel_container.add_theme_stylebox_override("panel", style_box)

	# Estilos para slots individuales
	_setup_slot_styles()

func _setup_slot_styles() -> void:
	"""Configurar estilos para los slots de guardado"""
	for i in range(slots_container.get_child_count()):
		var slot = slots_container.get_child(i)
		if slot is PanelContainer:
			var slot_style = StyleBoxFlat.new()
			slot_style.bg_color = Color(0.2, 0.2, 0.2, 0.6)
			slot_style.corner_radius_top_left = 6
			slot_style.corner_radius_top_right = 6
			slot_style.corner_radius_bottom_left = 6
			slot_style.corner_radius_bottom_right = 6
			slot_style.border_width_left = 1
			slot_style.border_width_right = 1
			slot_style.border_width_top = 1
			slot_style.border_width_bottom = 1
			slot_style.border_color = Color(0.4, 0.4, 0.4, 0.5)

			slot.add_theme_stylebox_override("panel", slot_style)

func _load_save_slots() -> void:
	"""Cargar información de los slots de guardado"""
	save_slots.clear()

	for i in range(3): # 3 slots
		var slot_data = _get_slot_data(i + 1)
		save_slots.append(slot_data)
		_update_slot_ui(i, slot_data)

func _get_slot_data(slot_id: int) -> Dictionary:
	"""Obtener datos del slot de guardado usando Save.gd"""
	if Save:
		return Save.get_save_slot_info(slot_id)
	else:
		return {"exists": false, "empty": true}

func _update_slot_ui(slot_index: int, slot_data: Dictionary) -> void:
	"""Actualizar UI de un slot específico"""
	var slot_node = slots_container.get_child(slot_index)
	if not slot_node:
		return

	# Obtener referencias a elementos del slot
	var info_container = slot_node.get_node("HBoxContainer/InfoContainer")
	var name_label = info_container.get_node("SlotName")
	var details_label = info_container.get_node("SlotDetails")
	var date_label = info_container.get_node("SlotDate")
	var buttons_container = slot_node.get_node("HBoxContainer/ButtonsContainer")
	var load_button = buttons_container.get_node("LoadButton")
	var save_button = buttons_container.get_node("SaveButton")

	# Actualizar información
	name_label.text = "Partida %d" % slot_data.slot_id

	if slot_data.exists:
		var zone_name = _get_zone_display_name(slot_data.current_zone)
		details_label.text = "Nivel %d - Zona: %s" % [slot_data.player_level, zone_name]
		date_label.text = "Guardado: %s" % _format_timestamp(slot_data.timestamp)
		load_button.disabled = false

		# Estilo para slot con datos
		var active_style = StyleBoxFlat.new()
		active_style.bg_color = Color(0.15, 0.25, 0.15, 0.7) # Tinte verde sutil
		active_style.corner_radius_top_left = 6
		active_style.corner_radius_top_right = 6
		active_style.corner_radius_bottom_left = 6
		active_style.corner_radius_bottom_right = 6
		active_style.border_width_left = 1
		active_style.border_width_right = 1
		active_style.border_width_top = 1
		active_style.border_width_bottom = 1
		active_style.border_color = Color(0.3, 0.5, 0.3, 0.8)
		slot_node.add_theme_stylebox_override("panel", active_style)
	else:
		details_label.text = "Slot vacío"
		date_label.text = "Nunca usado"
		load_button.disabled = true

func _get_zone_display_name(zone_id: String) -> String:
	"""Obtener nombre legible de la zona"""
	var zone_names = {
		"orilla": "Orilla",
		"mar": "Mar",
		"lago": "Lago",
		"rio": "Río",
		"costa": "Costa",
		"abismo": "Abismo",
		"glaciar": "Glaciar",
		"industrial": "Industrial",
		"infernal": "Infernal"
	}
	return zone_names.get(zone_id, zone_id.capitalize())

func _format_timestamp(timestamp: String) -> String:
	"""Formatear timestamp para mostrar"""
	if timestamp.is_empty():
		return "Desconocido"

	# Convertir timestamp a formato legible
	var time = Time.get_datetime_dict_from_system()
	return "%02d/%02d/%04d %02d:%02d" % [
		time.day, time.month, time.year,
		time.hour, time.minute
	]

func _connect_signals() -> void:
	"""Conectar señales de botones"""
	# Botones principales
	auto_save_button.pressed.connect(_on_auto_save_pressed)
	close_button.pressed.connect(_on_close_pressed)

	# Botones de slots
	for i in range(save_slots.size()):
		var slot_node = slots_container.get_child(i)
		var buttons_container = slot_node.get_node("HBoxContainer/ButtonsContainer")
		var load_button = buttons_container.get_node("LoadButton")
		var save_button = buttons_container.get_node("SaveButton")

		# Usar bind para pasar el slot_id
		load_button.pressed.connect(_on_load_pressed.bind(i + 1))
		save_button.pressed.connect(_on_save_pressed.bind(i + 1))

	# Cerrar con overlay
	overlay.gui_input.connect(_on_overlay_input)
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.z_index = 0
	panel_container.z_index = 1

	# CRÍTICO: Hacer que el CenterContainer no bloquee el input del overlay
	var center_container = $CenterContainer
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _setup_tooltips() -> void:
	"""Configurar tooltips"""
	auto_save_button.tooltip_text = "Guardar partida actual inmediatamente"
	close_button.tooltip_text = "Cerrar ventana de guardado"

	# Tooltips para slots
	for i in range(save_slots.size()):
		var slot_node = slots_container.get_child(i)
		var buttons_container = slot_node.get_node("HBoxContainer/ButtonsContainer")
		var load_button = buttons_container.get_node("LoadButton")
		var save_button = buttons_container.get_node("SaveButton")

		load_button.tooltip_text = "Cargar partida del slot %d" % (i + 1)
		save_button.tooltip_text = "Guardar partida actual en el slot %d" % (i + 1)

func _animate_show() -> void:
	"""Animar entrada de la ventana"""
	modulate.a = 0.0
	panel_container.scale = Vector2(0.85, 0.85)

	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.3)

	var scale_tween = create_tween()
	scale_tween.tween_property(panel_container, "scale", Vector2(1.0, 1.0), 0.3)

func close_animated() -> void:
	"""Cerrar ventana con animación (API pública)"""
	_animate_close()

func _animate_close() -> void:
	"""Animar cierre de la ventana"""
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.2)

	var scale_tween = create_tween()
	scale_tween.tween_property(panel_container, "scale", Vector2(0.85, 0.85), 0.2)

	fade_tween.tween_callback(func():
		window_closed.emit()
		queue_free()
	)

# Handlers de botones
func _on_load_pressed(slot_id: int) -> void:
	"""Cargar partida del slot especificado"""
	print("[SaveWindow] Cargando partida del slot %d..." % slot_id)

	if Save:
		Save.load_from_slot(slot_id)
		print("[SaveWindow] ✓ Partida cargada exitosamente")
		game_loaded.emit(slot_id)
		_animate_close()
	else:
		print("[SaveWindow] ❌ Sistema de guardado no disponible")

func _on_save_pressed(slot_id: int) -> void:
	"""Guardar partida en el slot especificado"""
	print("[SaveWindow] Guardando partida en slot %d..." % slot_id)

	# Confirmar sobreescritura si ya existe
	var slot_data = save_slots[slot_id - 1]
	if slot_data.exists:
		_confirm_overwrite(slot_id)
	else:
		_perform_save(slot_id)

func _confirm_overwrite(slot_id: int) -> void:
	"""Confirmar sobreescritura de slot existente"""
	# TODO: Mostrar diálogo de confirmación
	# Por ahora guardar directamente
	_perform_save(slot_id)

func _perform_save(slot_id: int) -> void:
	"""Realizar el guardado en el slot especificado"""
	if Save:
		Save.save_to_slot(slot_id)
		print("[SaveWindow] ✓ Partida guardada en slot %d" % slot_id)
		game_saved.emit(slot_id)

		# Recargar información de slots
		_load_save_slots()
	else:
		print("[SaveWindow] ❌ Sistema de guardado no disponible")

func _on_auto_save_pressed() -> void:
	"""Guardar automáticamente"""
	print("[SaveWindow] Guardado automático...")

	if Save:
		Save.save_game()
		print("[SaveWindow] ✓ Guardado automático completado")

func _on_close_pressed() -> void:
	"""Cerrar ventana"""
	_animate_close()

func _show_error_message(message: String) -> void:
	"""Mostrar mensaje de error"""
	# TODO: Implementar ventana de error
	print("[SaveWindow] ERROR: %s" % message)

func _on_overlay_input(event: InputEvent) -> void:
	"""Cerrar al hacer clic en overlay"""
	print("[SaveWindow] Overlay input recibido: %s" % event)
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("[SaveWindow] Clic en overlay - cerrando ventana")
			_on_close_pressed()

func _unhandled_input(event: InputEvent) -> void:
	"""Cerrar con ESC"""
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
