extends Node
## FloatingWindowManager - Gestor centralizado de ventanas flotantes (Refactorizado v4)

signal window_opened(window: Control)
signal window_closed(window: Control)
signal all_windows_closed()

var window_stack: Array[Control] = []
var open_windows_by_path: Dictionary = {}

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not window_stack.is_empty():
		var top_window = window_stack.back()
		if top_window.config.get("close_on_escape", true):
			close_window(top_window)
			get_viewport().set_input_as_handled()

func open_window(scene_path: String, win_config: Dictionary = {}) -> void:
	if is_window_open(scene_path):
		printerr("Window already open: %s" % scene_path)
		return

	var scene = load(scene_path)
	if not scene:
		printerr("Could not load scene: %s" % scene_path)
		return

	var window_instance = scene.instantiate()
	assert(window_instance is BaseWindow, "Scene must inherit from BaseWindow: %s" % scene_path)

	get_tree().root.add_child(window_instance)
	window_stack.push_back(window_instance)
	open_windows_by_path[scene_path] = window_instance
	window_instance.z_index = 1000 + window_stack.size()
	window_instance.open(win_config)
	animate_window_in(window_instance)
	window_opened.emit(window_instance)

func close_window(window: Control) -> void:
	if not is_instance_valid(window):
		return

	var scene_path = window.scene_file_path
	window_stack.erase(window)
	open_windows_by_path.erase(scene_path)
	animate_window_out(window, func(): _remove_window_from_tree(window))
	window_closed.emit(window)

	if window_stack.is_empty():
		all_windows_closed.emit()

func get_top_window() -> Control:
	return window_stack.back() if not window_stack.is_empty() else null

func is_window_open(scene_path: String) -> bool:
	return open_windows_by_path.has(scene_path)

func animate_window_in(window: Control) -> void:
	window.modulate.a = 0.0
	window.scale = Vector2(0.9, 0.9)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(window, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(window, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func animate_window_out(window: Control, on_finish: Callable) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(window, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(window, "scale", Vector2(0.9, 0.9), 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(on_finish)

func _remove_window_from_tree(window: Control) -> void:
	if is_instance_valid(window):
		window.queue_free()