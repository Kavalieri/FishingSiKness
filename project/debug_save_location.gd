extends Control

func _ready():
	print("=== FISHING SIKNESS - UBICACIÓN DE GUARDADO ===")
	print("user:// se resuelve a: ", OS.get_user_data_dir())
	print("Archivo de guardado: ", ProjectSettings.globalize_path("user://save.json"))
	print("Directorio de logs: ", ProjectSettings.globalize_path("user://logs/"))
	print("Nombre del proyecto: ", ProjectSettings.get_setting("application/config/name"))
	print("=== FIN ===")

	# Crear archivo de test para verificar
	var test_file = FileAccess.open("user://test_location.txt", FileAccess.WRITE)
	if test_file:
		test_file.store_string("Fishing SiKness - Test de ubicación\n")
		test_file.store_string("Timestamp: " + str(Time.get_unix_time_from_system()) + "\n")
		test_file.close()
		print("Archivo de test creado en: ", ProjectSettings.globalize_path("user://test_location.txt"))

	# Salir inmediatamente
	get_tree().quit()
