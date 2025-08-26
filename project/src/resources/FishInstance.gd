class_name FishInstance
extends Resource

@export var fish_def: FishDef
@export var size: float
@export var weight: float
@export var value: int
@export var timestamp: int

func _init(def: FishDef = null, caught_size: float = 0.0):
	if def:
		fish_def = def
		size = caught_size
		weight = size * 0.1 # Peso aproximado
		value = calculate_value()
		timestamp = Time.get_unix_time_from_system()

func calculate_value() -> int:
	if not fish_def:
		return 0

	# Valor base + bonificación por tamaño
	var size_bonus = (size - fish_def.size_min) / (fish_def.size_max - fish_def.size_min)
	size_bonus = max(0.0, min(1.0, size_bonus)) # Clamp entre 0-1

	return int(fish_def.base_price * (1.0 + size_bonus * 0.5))

func get_display_name() -> String:
	if not fish_def:
		return "Pez desconocido"
	return "%s (%.1fcm)" % [fish_def.name, size]
