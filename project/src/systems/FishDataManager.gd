
extends Node

# Diccionario para almacenar las definiciones de peces, indexadas por su ID.
var fish_definitions: Dictionary = {}

func _ready() -> void:
	"""
	Carga todas las definiciones de peces (FishDef) desde el directorio de datos
	y las almacena en el diccionario para un acceso rápido.
	"""
	print("FishDataManager: Cargando definiciones de peces...")
	_load_fish_defs_from_directory("res://data/fish/")
	print("FishDataManager: %d definiciones de peces cargadas." % fish_definitions.size())

func _load_fish_defs_from_directory(path: String) -> void:
	"""
	Escanea un directorio en busca de recursos .tres (FishDef) y los carga.
	"""
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var resource_path = path.path_join(file_name)
				var fish_def = load(resource_path) as FishDef
				if fish_def and fish_def.id:
					if not fish_definitions.has(fish_def.id):
						fish_definitions[fish_def.id] = fish_def
					else:
						push_warning("FishDataManager: ID de pez duplicado encontrado: '%s' en '%s'. Se ignorará." % [fish_def.id, resource_path])
				else:
					push_warning("FishDataManager: No se pudo cargar FishDef o no tiene ID en: '%s'" % resource_path)
			file_name = dir.get_next()
	else:
		push_error("FishDataManager: No se pudo abrir el directorio: '%s'" % path)


func get_fish_def(id: String) -> FishDef:
	"""
	Devuelve la definición de un pez (FishDef) a partir de su ID.
	Devuelve null si no se encuentra.
	"""
	if fish_definitions.has(id):
		return fish_definitions[id]
	
	push_warning("FishDataManager: No se encontró la definición para el pez con ID: '%s'" % id)
	return null

