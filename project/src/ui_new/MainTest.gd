extends Control

# Test simple para verificar ejecución

func _ready() -> void:
	print("=== MAIN TEST READY START ===")
	print("Este es un test simple para verificar que Main se ejecuta")
	print("=== MAIN TEST READY END ===")

	# Conectar señales después de un frame
	call_deferred("connect_signals")

func connect_signals() -> void:
	print("=== CONECTANDO SEÑALES ===")

	var bottombar = $VBoxContainer/BottomBar
	if bottombar and bottombar.has_signal("tab_selected"):
		bottombar.tab_selected.connect(_on_bottombar_tab_selected)
		print("✓ Señal BottomBar conectada exitosamente")
	else:
		print("❌ ERROR: No se pudo conectar señal BottomBar")

func _on_bottombar_tab_selected(tab_name: String) -> void:
	print("[MainTest] ¡SEÑAL RECIBIDA! Tab seleccionado: ", tab_name)
