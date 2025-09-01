class_name ZoneDef
extends Resource

@export var id: String
@export var name: String
@export var description: String = "" # Descripción de la zona
@export var difficulty: int = 1 # Dificultad de 1-5
@export var unlock_cost: int = 0 # Costo para desbloquear la zona
@export var price_multiplier: float = 1.0
@export var entries: Array[LootEntry] = []
@export var background: String = "" # Path to background texture
