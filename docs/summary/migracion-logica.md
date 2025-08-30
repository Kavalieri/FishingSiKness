# Migración de Lógica: De UI Antigua a Nueva Arquitectura

## Vista General de la Migración

### Arquitectura Anterior (ui/)
```
src/ui/
├── TopBar.gd (mezcla static + dynamic)
├── BottomBar.gd (mezcla static + dynamic)
└── views/
    ├── FishingView.gd (lógica mezclada)
    └── MapView.gd (lógica mezclada)
```

### Nueva Arquitectura (ui_new/)
```
src/ui_new/
├── TopBar.gd (solo lógica dinámica)
├── BottomBar.gd (solo lógica dinámica)
├── components/
│   └── QTEContainer.gd (componente especializado)
└── views/
    ├── FishingView.gd (migración pendiente)
    └── MapView.gd (migración pendiente)
```

## Pasos de Migración

### 1. Análisis de Dependencias
Antes de migrar una vista, identificar:
- **Datos**: ¿De dónde vienen? (Save, GameState, autoloads)
- **UI Components**: ¿Qué elementos necesita? (botones, labels, progreso)
- **Signals**: ¿Qué eventos emite y escucha?
- **Resources**: ¿Qué assets utiliza? (iconos, texturas, sounds)

### 2. Separación .tscn vs .gd

#### En archivo .tscn:
- **Estructura visual**: Nodos, containers, layout
- **Propiedades estáticas**: tamaños, anclas, estilos
- **Recursos**: iconos, texturas, themes
- **Configuración inicial**: textos por defecto, colores

#### En archivo .gd:
- **Lógica de negocio**: cálculos, validaciones
- **Event handling**: respuesta a input, signals
- **Data binding**: sincronización con autoloads
- **Animaciones**: tweens, efectos visuales
- **Estado dinámico**: cambios en runtime

### 3. Patrón de Migración

```gdscript
# ANTES (mezcla static + dynamic)
class_name OldView
extends Control

func _ready():
    _setup_ui()  # ← Esto va al .tscn
    _setup_logic()  # ← Esto se queda en .gd

# DESPUÉS (solo dynamic)
class_name NewView
extends Control

func _ready():
    _connect_signals()
    _sync_from_autoloads()
    _set_dynamic_properties()
```

### 4. Ejemplo Práctico: FishingView

#### Migración de lógica UI:
```gdscript
# src/ui_new/views/FishingView.gd
class_name FishingView
extends Control

signal fish_caught(fish_data: FishData)
signal qte_started()

@onready var cast_button: Button = $VBox/CastButton
@onready var progress_bar: ProgressBar = $VBox/ProgressBar
@onready var qte_container: QTEContainer = $QTEContainer

func _ready():
    _connect_fishing_signals()
    _sync_from_fishing_manager()

func _connect_fishing_signals():
    cast_button.pressed.connect(_on_cast_button_pressed)
    qte_container.qte_success.connect(_on_qte_success)

func _on_cast_button_pressed():
    if FishingManager.can_cast():
        FishingManager.start_fishing()
        _start_fishing_animation()
```

#### Actualizar Main.gd para usar nueva vista:
```gdscript
# src/ui_new/Main.gd
func _switch_to_fishing_view():
    var fishing_scene = preload("res://scenes/ui_new/views/FishingView.tscn")
    current_view = fishing_scene.instantiate()
    view_container.add_child(current_view)

    # Conectar señales de la nueva vista
    current_view.fish_caught.connect(_on_fish_caught)
```

### 5. Checklist de Migración

#### Para cada vista:
- [ ] **Assets verificados**: Todos los iconos/texturas están en art/
- [ ] **.tscn actualizado**: Estructura visual completa, sin lógica
- [ ] **.gd limpio**: Solo lógica dinámica, sin setup visual
- [ ] **Signals conectados**: Event handling funcional
- [ ] **Data sync**: Autoloads conectados correctamente
- [ ] **QTE integrado**: Si necesita QTE, usar QTEContainer
- [ ] **Background compatible**: Funciona con fondo único global

#### Testing:
- [ ] **Funcionalidad**: La vista funciona igual que antes
- [ ] **Performance**: No hay lag en la UI
- [ ] **Responsive**: Se adapta a diferentes tamaños
- [ ] **Asset loading**: Iconos y texturas cargan correctamente

### 6. Orden de Migración Sugerido

1. **FishingView**: Vista principal, más crítica
2. **MapView**: Navegación entre zonas
3. **MarketView**: Compra/venta de items
4. **UpgradesView**: Mejoras de equipo
5. **PrestigeView**: Sistema de prestigio

### 7. Manejo de Estados Globales

```gdscript
# Ejemplo: Sincronizar con Save autoload
func _sync_from_autoloads():
    if Save:
        Save.coins_changed.connect(_update_money_display)
        Save.items_changed.connect(_update_inventory)
        _update_money_display(Save.coins)

# Ejemplo: Sincronizar con FishingManager
func _sync_from_fishing_manager():
    if FishingManager:
        FishingManager.fishing_started.connect(_on_fishing_started)
        FishingManager.fish_caught.connect(_on_fish_caught)
```

### 8. Notas Importantes

- **No romper funcionalidad**: La migración debe ser invisible al usuario
- **Mantener señales**: Las señales existentes deben seguir funcionando
- **Asset paths**: Verificar que todas las rutas de assets sean correctas
- **i18n ready**: Preparar strings para localización futura
- **QTE integration**: Usar el nuevo QTEContainer para eventos interactivos

### 9. Testing de Migración

```bash
# Ejecutar juego para probar
godot --path project/

# Verificar que funcione cada vista migrada:
# - TopBar: botones responden, datos actualizados
# - BottomBar: tabs cambian correctamente
# - Views: funcionalidad completa
# - QTE: eventos interactivos funcionan
# - Background: fondo único se mantiene
```
