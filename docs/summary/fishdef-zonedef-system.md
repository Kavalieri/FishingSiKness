# Sistema FishDef y ZoneDef - Documentación Técnica

## Resumen Ejecutivo

El proyecto Fishing-SiKness implementa un **sistema 100% data-driven** donde todo el contenido del juego (peces, zonas, rareza, loot tables) se define mediante recursos `.tres` de Godot, permitiendo modificar contenido sin tocar código. Los sistemas **FishDef** y **ZoneDef** son los pilares de esta arquitectura.

## 🐟 Sistema FishDef - Definición de Especies

### **Archivos Clave**
```
📁 project/src/resources/
└── FishDef.gd                     # Clase resource para especies

📁 project/data/fish/
├── fish_arapaima.tres             # Recursos individuales de peces
├── fish_salmon_atlantico.tres
├── fish_trucha_comun.tres
└── ... (35+ especies)

📁 project/src/autoload/
└── FishDataManager.gd             # Singleton para gestión de peces
```

### **Estructura de Datos**
```gdscript
# FishDef.gd - Resource class
class_name FishDef extends Resource

@export var id: String                    # ID único (ej: "arapaima")
@export var display_name: String          # Nombre visual
@export var description: String           # Descripción del pez
@export var icon: Texture2D               # Sprite del pez
@export var rarity: GameEnums.Rarity      # Común/Raro/Épico/Legendario
@export var base_value: int               # Valor base en coins
@export var weight_min: float             # Peso mínimo
@export var weight_max: float             # Peso máximo
@export var size_min: float               # Tamaño mínimo
@export var size_max: float               # Tamaño máximo
```

### **Ejemplo de Archivo .tres**
```tres
# fish_arapaima.tres
[gd_resource type="Resource" script_class="FishDef" load_steps=3 format=3]

[ext_resource type="Script" path="res://src/resources/FishDef.gd" id="1"]
[ext_resource type="Texture2D" path="res://art/fish/arapaima.png" id="2"]

[resource]
script = ExtResource("1")
id = "arapaima"
display_name = "Arapaima"
description = "El gigante de los ríos amazónicos."
icon = ExtResource("2")
rarity = 4
base_value = 1500
weight_min = 50.0
weight_max = 200.0
size_min = 150.0
size_max = 300.0
```

## 🗺️ Sistema ZoneDef - Definición de Zonas

### **Archivos Clave**
```
📁 project/src/resources/
└── ZoneDef.gd                     # Clase resource para zonas

📁 project/data/zones/
├── zone_lago_montana_alpes.tres   # Recursos de zonas individuales
├── zone_rios_amazonicos.tres
├── zone_oceanos_profundos.tres
└── ... (8 zonas realistas)

📁 project/data/loot_tables/
├── entry_arapaima.tres            # LootEntry individuales
├── entry_trucha_comun.tres
├── lago_montana_alpes_table.tres  # LootTable completas
└── ... (32+ entradas de loot)

📁 project/src/autoload/
└── Content.gd                     # Singleton para gestión de zonas
```

### **Estructura de Datos**
```gdscript
# ZoneDef.gd - Resource class
class_name ZoneDef extends Resource

@export var id: String                         # ID único
@export var display_name: String               # Nombre visual
@export var description: String                # Descripción de la zona
@export var background: String                 # Ruta del fondo visual
@export var icon: String                       # Icono de la zona
@export var price_multiplier: float = 1.0      # Multiplicador de precios
@export var unlock_cost: int = 0               # Costo de desbloqueo
@export var difficulty: int = 1                # Nivel de dificultad
@export var entries: Array[Resource] = []      # LootEntry que contiene
```

### **Sistema de LootEntry (ÚNICO Y CONSISTENTE)**
```gdscript
# LootEntry.gd - Entrada individual de pesca
class_name LootEntry extends Resource

@export var fish: FishDef          # Referencia al FishDef
@export var weight: int = 1        # Peso probabilístico
```

**Arquitectura Final**:
- ✅ **1 LootEntry por pez** - Fuente única de verdad
- ✅ **ZoneDef.entries** referencia directamente a LootEntry individuales
- ✅ **Escalabilidad**: Nuevos peces = nuevo entry_*.tres
- ✅ **Reutilización**: Mismo pez en múltiples zonas sin duplicación

## ✅ PROBLEMA RESUELTO: Loot Tables Unificadas

### **Estado Anterior (INCONSISTENTE)**
- ❌ LootEntry individuales + LootTable completas = duplicación
- ❌ Dos fuentes de verdad = posibles inconsistencias

### **Estado Actual (CONSISTENTE)**
- ✅ **Solo LootEntry individuales**: `entry_*.tres` (26+ archivos)
- ✅ **ZoneDef.entries**: Array[Resource] que referencia LootEntry directamente
- ✅ **Single Source of Truth**: 1 archivo por especie
- ✅ **Migración completada**: LootTable.gd y *_table.tres eliminados

## 🔄 Flujo de Datos y Integración

### **Inicialización del Sistema**
```gdscript
# 1. Autoload FishDataManager carga todos los FishDef
FishDataManager._load_fish_definitions()  # 35+ peces

# 2. Autoload Content carga todas las zonas
Content._load_all_zones()                 # 8 zonas realistas

# 3. Cada zona carga sus LootEntry asociadas
for zone in zones:
    zone.entries  # Array de LootEntry con referencias a FishDef
```

### **Uso en Gameplay**
```gdscript
# MapScreen.gd - Mostrar zonas disponibles
func _populate_zones():
    var all_zones = Content.get_all_zones()
    for zone_def in all_zones:
        var fish_list = Content.get_fish_for_zone(zone_def.id)
        _create_zone_card(zone_def, fish_list)

# FishingScreen.gd - Sistema de pesca
func _catch_fish_in_zone(zone_id: String):
    var zone_def = Content.get_zone_def(zone_id)
    var available_fish = Content.get_fish_for_zone(zone_id)
    var caught_fish = _roll_loot_table(zone_def.entries)
    return caught_fish
```

## 📊 Arquitectura de Archivos

```
📦 FishingSiKness/
├── 📁 project/
│   ├── 📁 src/
│   │   ├── 📁 resources/
│   │   │   ├── FishDef.gd              # ⭐ Clase base para peces
│   │   │   ├── ZoneDef.gd              # ⭐ Clase base para zonas
│   │   │   └── LootEntry.gd            # ⭐ Entrada única de loot
│   │   └── 📁 autoload/
│   │       ├── FishDataManager.gd      # ⭐ Gestor de peces
│   │       └── Content.gd              # ⭐ Gestor de zonas/loot
│   └── 📁 data/
│       ├── 📁 fish/                    # ⭐ 35+ archivos .tres de peces
│       ├── 📁 zones/                   # ⭐ 8 archivos .tres de zonas
│       └── 📁 loot_tables/             # ⭐ Solo entry_*.tres individuales
└── 📁 art/
    ├── 📁 fish/                        # Sprites de peces
    └── 📁 env/                         # Fondos de zonas
```

## 🛠️ Ventajas del Sistema Data-Driven

1. **Sin recompilación**: Modificar especies/zonas editando solo `.tres`
2. **Escalabilidad**: Añadir contenido creando nuevos archivos
3. **Balance**: Ajustar rareza/precios sin tocar código
4. **Modding**: Potencial para mods comunitarios
5. **Testing**: Crear contenido de prueba fácilmente

## 🔧 Herramientas de Desarrollo

- **Editor Godot**: Crear/editar recursos `.tres` visualmente
- **CSV Importers**: Scripts para generar `.tres` desde datos CSV
- **Debug Panel**: Inspector en tiempo real de FishDef/ZoneDef cargados
- **Validation Tools**: Scripts para verificar integridad de datos

## 🎯 Estado Final

✅ **Sistema Unificado y Consistente**
- **35 FishDef**: Especies individuales completamente definidas
- **8 ZoneDef**: Zonas realistas con ecosistemas balanceados
- **26 LootEntry**: Una entrada por especie (Single Source of Truth)
- **0 duplicaciones**: Sistema limpio sin inconsistencias

---

**✅ SISTEMA COMPLETADO**: La arquitectura FishDef/ZoneDef está completamente implementada con un sistema de loot tables unificado que mantiene la consistencia de datos y sigue las mejores prácticas de Godot 4.4 para arquitecturas data-driven.
