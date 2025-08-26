class_name FishDef
extends Resource

@export var id: String
@export var name: String
@export var description: String = ""
@export var species_category: String = "" # "common", "uncommon", "rare", "epic", "legendary"
@export var rarity: int = 0 # 0..4 (0=common, 1=uncommon, 2=rare, 3=epic, 4=legendary)
@export var base_market_value: int = 10 # Precio base por especie independiente del tamaño
@export var size_min: float = 10.0
@export var size_max: float = 30.0
@export var sprite: Texture2D
@export var habitat_zones: Array[String] = [] # Zonas donde se puede encontrar
@export var difficulty: int = 1 # 1-5, para futuras mecánicas de captura
