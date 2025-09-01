extends SceneTree

func _ready():
	print("=== TEST CAMBIO DE FONDO POR ZONA ===")

	# Simular cambio de zona
	var test_zones = [
		"lago_montana_alpes",
		"costas_atlanticas",
		"rios_amazonicos",
		"oceanos_profundos"
	]

	# Esperar a que Content esté listo
	await process_frame
	await process_frame

	if not Content:
		print("❌ Content system no disponible")
		quit()
		return

	print("✅ Content system disponible")
	print("Zonas disponibles: %d" % Content.get_all_zones().size())

	# Probar cada zona
	for zone_id in test_zones:
		print("\n--- Probando zona: %s ---" % zone_id)

		var zone_def = Content.get_zone_by_id(zone_id)
		if zone_def:
			print("✅ Zona encontrada: %s" % zone_def.name)
			print("Background path: %s" % zone_def.background)

			if zone_def.background != "":
				var bg_name = zone_def.background.get_file().get_basename()
				print("✅ Background extraído: %s" % bg_name)

				# Verificar que el archivo existe
				var full_path = "res://art/env/%s.png" % bg_name
				if ResourceLoader.exists(full_path):
					print("✅ Archivo de fondo existe: %s" % full_path)
				else:
					print("❌ Archivo de fondo NO existe: %s" % full_path)
			else:
				print("⚠️ Zona sin background definido")
		else:
			print("❌ Zona no encontrada: %s" % zone_id)

	print("\n=== FIN TEST ===")
	quit()
