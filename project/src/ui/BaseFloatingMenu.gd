class_name BaseFloatingMenu
extends Control
## Clase base SIMPLE para menús flotantes con fondo estandarizado
##
## Uso: Los menús que hereden de esta clase automáticamente tendrán:
## - Fondo configurado por BackgroundManager
## - Estructura básica de contenedor
## - El resto de la lógica es responsabilidad de cada menú específico

var main_container: Control

func _ready():
	# Configurar fondo usando BackgroundManager si existe
	if BackgroundManager:
		BackgroundManager.setup_menu_background(self)
		print("✅ BaseFloatingMenu: Fondo configurado para %s" % name)

	# Llamar a setup_menu() en el siguiente frame para que las clases hijas puedan configurarse
	call_deferred("setup_menu")

func setup_menu():
	"""Override en clases hijas para configurar el contenido específico"""
	print("⚠️ BaseFloatingMenu: setup_menu() no implementado en %s" % name)
