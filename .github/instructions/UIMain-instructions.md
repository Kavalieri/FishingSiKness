
# 📱 UI Godot 4 (Portrait) — Especificación **PRO** para móvil
**Topbar 2 filas (50/50) con XP, todas las celdas con imagen + tooltip, Botbar con 5 botones cuadrados (solo imagen), SplashScreen completa, fondos y responsividad total.**
Documento listo para usar como **prompt fijo del proyecto** y guía de implementación.

> Criterio: nada de posiciones absolutas. Todo por *containers*, ratios, clamps, **Safe Area ON**, *themes* y *resources* reutilizables. Touch targets ≥ 56 px. DPI y escalado cuidados.

---

## 0) Objetivos y supuestos
- **Orientación**: *portrait* (vertical) como foco principal. Soporte landscape opcional.
- **Escala base de referencia**: 1080×2400 (19.5:9).
- **Metas**: GUI limpia, legible, responsiva, con señales y *tooltips*. Diseño “gamey” moderno.
- **Entrada**: táctil (MÍN 56×56 px por botón), *tooltips* con retardo breve para *mouse/desktop*.

---

## 1) Ajustes de proyecto (Godot 4)
**Project → Display → Window**
- **Content Scale Mode**: `canvas_items`
- **Content Scale Aspect**: `keep` (o `keep_width` si priorizas no recortar lateral)
- **Allow HiDPI**: ON
- **Handheld** → **Use Safe Area**: ON

**Project → Rendering**
- **Low-end móviles**: desactiva efectos pesados por *quality preset* (filtros, sombras suaves, etc.).
- **Textures**: usa compresión ASTC/ETC2 para APK/AAB cuando sea posible.

---

## 2) Distribución vertical por % + clamps
| Zona        | % alto | Mín px | Máx px | Notas |
|-------------|--------|--------|--------|------|
| **Topbar**  | **11%**| 64     | 96     | 2 filas 50/50, superior: 3 tercios (extremos 50/50), inferior: XP a todo ancho |
| **Central** | **77%**| —      | —      | Pantallas dinámicas (no toques Top/Bottom) |
| **Botbar**  | **12%**| 72     | 104    | 5 botones cuadrados 1:1 (solo imagen) |

> Mantén **porcentajes** y **clamps**. Ajusta *Theme paddings* y separaciones para “polish”, no el %.

---

## 3) Estructura de escenas (separadas)
```
res://scenes/Main.tscn                 ← raíz (Control)
res://scenes/ui/TopBar.tscn            ← topbar 2 filas (clickable, imagen + tooltip)
res://scenes/ui/BottomBar.tscn         ← 5 botones cuadrados 1:1 (imagen + tooltip)
res://scenes/ui/CentralHost.tscn       ← contenedor central (carga pantallas dinámicas)
res://scenes/ui/SplashScreen.tscn      ← splash con carga, tips, logo, versión, copyright
res://scenes/screens/...               ← pantallas (Pesca, Mapa, Mercado, Mejoras, Prestigio)
res://scripts/Main.gd                  ← ratios + clamps + bootstrap
res://scripts/SplashScreen.gd          ← flujo splash → main
res://themes/app.theme                 ← tema global
res://themes/tooltip.tres              ← estilo tooltip
res://themes/progress_xp.tres          ← estilo ProgressBar XP
res://assets/ui/icons/...              ← iconos raster/SVG (dinero, gemas, social, pausa, tabs)
res://assets/ui/logo.png               ← logotipo
res://assets/ui/backgrounds/...        ← fondos (splash y main)
res://i18n/strings.csv                 ← i18n tooltips/textos
```

---

## 4) Árbol de nodos (por escena)

### `Main.tscn`
```
Control (Main)
└── VBoxContainer
    ├── TopBar      (Instancia TopBar.tscn)           # ratio 11
    ├── CentralHost (Instancia CentralHost.tscn)      # ratio 77
    └── BottomBar   (Instancia BottomBar.tscn)        # ratio 12
```

### `TopBar.tscn` — 2 filas 50/50 (todas las celdas con **imagen** + tooltip)
```
Control (TopBar)
└── VBoxContainer                        # 2 filas iguales
    ├── TopRow (Control)                 # ratio 1
    │   └── HBoxContainer                # 3 tercios
    │       ├── LeftThird (Control)      # 1/3
    │       │   └── HBoxContainer        # 2 mitades 50/50
    │       │       ├── MoneyCell  (Button/TextureButton)  # imagen + label (opcional)
    │       │       └── GemsCell   (Button/TextureButton)  # imagen + label
    │       ├── CenterThird (Button/TextureButton)         # ZONA Social (imagen + label opc.)
    │       └── RightThird (Control)                        # 1/3
    │           └── HBoxContainer            # 2 mitades 50/50
    │               ├── NotifCell? (Button/TextureButton)  # opcional (perfíl/notificaciones)
    │               └── PauseCell  (Button/TextureButton)  # imagen + label opc.
    └── BottomRow (Control)                # ratio 1
        └── MarginContainer (padding)
            └── ProgressBar (XP)           # a todo el ancho (clicable opc.)
                ├── Label (Level)          # opcional (izquierda)
                └── Label (Value)          # opcional (derecha)
```

### `BottomBar.tscn` — 5 **cuadrados** 1:1 (**solo imagen** + tooltip)
```
Control (BottomBar)
└── HBoxContainer (separation 8–12)
    ├── Btn1 (AspectRatioContainer ratio=1.0) → TextureButton (tooltip="Pesca")
    ├── Btn2 (AspectRatioContainer ratio=1.0) → TextureButton (tooltip="Mapa")
    ├── Btn3 (AspectRatioContainer ratio=1.0) → TextureButton (tooltip="Mercado")
    ├── Btn4 (AspectRatioContainer ratio=1.0) → TextureButton (tooltip="Mejoras")
    └── Btn5 (AspectRatioContainer ratio=1.0) → TextureButton (tooltip="Prestigio")
```

### `CentralHost.tscn`
```
Control (CentralHost)
└── MarginContainer  (paddings opcionales)
    └── Control (ScreenRoot)  # aquí se instancian pantallas dinámicas
```

### `SplashScreen.tscn`
```
Control (SplashScreen)
├── TextureRect (Background)      # escala a pantalla, calidad media/alta
├── VBoxContainer
│   ├── Control (TopBarZone)      # esquina sup. derecha: botón pausa
│   │   └── HBoxContainer
│   │       └── PauseButton (TextureButton, tooltip="Pausa")
│   ├── Control (LogoZone)        # mitad superior: logotipo centrado
│   │   └── TextureRect (Logo)
│   ├── Label ("Pulsa para empezar")  # aparece tras carga mínima
│   ├── VBoxContainer (TipsZone)  # consejos rotativos (Label)
│   │   └── Label (TipText)
│   └── VBoxContainer (LoadZone)  # barra de carga + %
│       ├── ProgressBar
│       └── Label (PercentText)
└── HBoxContainer (Footer, bottom) # versión y copyright
    ├── Label (VersionText)        # vX.Y.Z (build hash opcional)
    └── Label (CopyrightText)      # © Año NombreEstudio
```

---

## 5) ASCII — diseños visuales

### 5.1 Global (portrait)
```
+───────────────────────────────────────────────+
|                 TOPBAR (11%)                  |
|  ┌─────────────── TopRow ─────────────────┐   |
|  | [💰 12.3K] [💎 250] |  [👥 Social]  | [🔔][⏸] |   ← extremos 50/50, centro 1/3
|  └────────────── BottomRow ──────────────┘   |
|  | [LVL 12] ██████████░░░░  12,345/20,000 |   |   ← XP a todo el ancho
+───────────────────────────────────────────────+
|                 CENTRAL (77%)                 |
|            [pantallas dinámicas]             |
+───────────────────────────────────────────────+
| [🎣] [🗺] [🏬] [⬆] [⭐]        BOTTOM (12%)       |
|  Pesca Mapa Mercado Mejoras Prestigio        |
+───────────────────────────────────────────────+
```

### 5.2 TopRow (detalle)
```
┌─────────────────┬─────────────────┬─────────────────┐
│ LeftThird       │ CenterThird     │ RightThird      │
│ ┌──────┬──────┐ │     [ Zone ]    │ ┌──────┬──────┐ │
│ │💰K   │💎G  │ │                 │ │Social│pause │ │
│ └──────┴──────┘ │                 │ └──────┴──────┘ │
└─────────────────┴─────────────────┴─────────────────┘
```

### 5.3 Progress XP (fila inferior Topbar)
```
┌───────────────────────────────────────────────────┐
│ [LVL 12]  ████████████░░░░░  12,345 / 20,000      │
└───────────────────────────────────────────────────┘
```

### 5.4 Botbar (5 cuadrados 1:1, **solo imagen**)
```
HBox (sep 8–12)
[  🎣  ][  🗺  ][  🏬  ][  ⬆  ][  ⭐  ]
  1:1      1:1     1:1     1:1     1:1
```

### 5.5 SplashScreen
```
+───────────────────────────────────────────────+
| [BG Imagen]                                   |
|                               [⏸]             | ← Pausa (sup. dcha.)
|                                               |
|                  [ LOGO ]                     | ← Mitad superior
|                                               |
|           "PULSA PARA EMPEZAR"                |
|                                               |
|           Tip: Arrastra para lanzar...        | ← Tips rotativos
|                                               |
|     Cargando: ████████░░░░  68%               |
|                                               |
|  v0.3.1 (a1b2c3)            © 2025 SiK Studio |
+───────────────────────────────────────────────+
```

---

## 6) Métricas, imágenes y responsividad

### 6.1 Hit-targets y tipografías
- **Botones/celdas**: ≥ 56×56 px (mín 48 px).
- **Iconos Topbar**: 24–28 px (máx 32 en DPI altos).
- **Iconos Botbar**: 32–40 px (según espacio).
- **Texto**: 14–16 px en labels; 12–13 px en tooltips.
- **Separation** HBox/VBox: 8–12 px (ajusta en *Theme*).

### 6.2 Imágenes y *stretch*
- `TextureButton` Topbar:
  - `expand = true`, `stretch_mode = TextureButton.STRETCH_SCALE`.
  - Internamente, usa `TextureRect` hijo si necesitas **imagen + texto** (layout más fino).
- `AspectRatioContainer` en Botbar: **ratio = 1.0** para cuadrado perfecto, imagen centrada.
- **SVG** preferible para iconos si el *style* lo permite (nítidos en DPI altos).

### 6.3 Responsividad total
- Los **%** determinan alturas macro.
- **AspectRatioContainer** asegura **botones cuadrados**.
- **Size Flags** (`Fill+Expand`) reparten espacio entre hermanos.
- **Clamps** evitan absurdos en pantallas micro o gigantes.
- **Safe Area** evita notch/gestos invadiendo UI.

---

## 7) Tooltips e interacción
**Todos los elementos clicables** tienen `tooltip_text`. Sugerencias i18n (keys → texto):
```
ui.money.tooltip     = "Dinero: abre economía"
ui.gems.tooltip      = "Gemas premium"
ui.social.tooltip    = "Zona Social"
ui.pause.tooltip     = "Pausa / Opciones"
ui.xp.tooltip        = "Experiencia"
ui.tab.fish          = "Pesca"
ui.tab.map           = "Mapa"
ui.tab.market        = "Mercado"
ui.tab.upgrades      = "Mejoras"
ui.tab.prestige      = "Prestigio"
```
**Delay recomendado**: 0.4–0.6 s; **duración**: 2–3 s.
Señales `pressed()` conectadas con `Callable` hacia un **controlador central**; **no** incrustes lógica de juego en la UI.

---

## 8) Themes (estilo profesional)

### 8.1 Tooltip (`tooltip.tres`)
- Fondo semitransparente (negro 70%), radio 6–8 px, padding 8–12 px, sombra leve.
- Texto 12–13 px, alto contraste.

### 8.2 Barra XP (`progress_xp.tres`)
- Fondo oscuro sutil, borde 1 px soft.
- *Fill* degradado suave + brillo ligero (gloss) arriba.
- Texto nivel/valor con sombra sutil para legibilidad.

### 8.3 Botones (Top/Bottom)
- Estados: `normal/hover/pressed/disabled/focus`.
- Efectos: escala 0.96 en `pressed`, sombra leve en `hover` (en desktop).
- Paddings uniformes en Theme (no por nodo).

---

## 9) Fondos (Splash y Main)
- **Splash**: imagen única a pantalla con `TextureRect` (STRETCH_KEEP_ASPECT_COVER).
  - Opcional: *overlay* oscuro (ColorRect) para mejorar contraste del logo/textos.
- **Main**: 2 opciones pro:
  1) **Imagen estática** (ligera) con *parallax* sutil.
  2) **Color/gradiente** con patrones suaves vectoriales (mejor rendimiento).
- Evita vídeos/animaciones pesadas en móviles bajos. Si hay partículas, limítalas.

---

## 10) Código clave

### 10.1 `Main.gd` — ratios + clamps
```gdscript
extends Control

const TOP_MIN := 64
const TOP_MAX := 96
const BOT_MIN := 72
const BOT_MAX := 104

@onready var vbox := $VBoxContainer
@onready var topbar: Control = vbox.get_node("TopBar")
@onready var central_host: Control = vbox.get_node("CentralHost")
@onready var bottombar: Control = vbox.get_node("BottomBar")

func _ready() -> void:
    vbox.set_stretch_ratio(topbar, 11)
    vbox.set_stretch_ratio(central_host, 77)
    vbox.set_stretch_ratio(bottombar, 12)
    _apply_clamps()

func _notification(what):
    if what == NOTIFICATION_RESIZED:
        _apply_clamps()

func _apply_clamps() -> void:
    var h := size.y
    topbar.custom_minimum_size.y    = clamp(h * 0.11, TOP_MIN, TOP_MAX)
    bottombar.custom_minimum_size.y = clamp(h * 0.12, BOT_MIN, BOT_MAX)
```

### 10.2 `SplashScreen.gd` — flujo splash
```gdscript
extends Control

@export var min_time_to_show := 1.2
@export var tips := PackedStringArray(["Consejo 1...", "Consejo 2...", "Consejo 3..."])

@onready var progress: ProgressBar = $VBoxContainer/LoadZone/ProgressBar
@onready var percent: Label = $VBoxContainer/LoadZone/PercentText
@onready var tip_label: Label = $VBoxContainer/TipsZone/TipText
@onready var press_to_start: Label = $VBoxContainer/"Pulsa para empezar"
@onready var pause_btn: BaseButton = $VBoxContainer/TopBarZone/HBoxContainer/PauseButton

var _elapsed := 0.0
var _ready_to_start := false

func _ready() -> void:
    press_to_start.visible = false
    tip_label.text = tips.is_empty() ? "" : tips.pick_random()
    _simulate_loading()

func _process(delta: float) -> void:
    _elapsed += delta
    if _ready_to_start and _elapsed > min_time_to_show:
        press_to_start.visible = true

func _unhandled_input(event: InputEvent) -> void:
    if _ready_to_start and press_to_start.visible and event.is_action_pressed("ui_accept"):
        _go_to_main()

func _simulate_loading() -> void:
    # Sustituye por carga real de recursos (ResourceLoader, etc.)
    var tween := create_tween()
    tween.tween_property(progress, "value", 100.0, 1.5)
    tween.tween_callback(Callable(self, "_on_loaded_step"))

func _on_loaded_step() -> void:
    percent.text = str(roundi(progress.value)) + "%"
    if progress.value >= 100.0:
        _ready_to_start = true

func _go_to_main() -> void:
    get_tree().change_scene_to_file("res://scenes/Main.tscn")
```

### 10.3 Tooltips y señales (ejemplo Topbar)
```gdscript
# En _ready() de TopBar.gd
$VBoxContainer/TopRow/HBoxContainer/LeftThird/HBoxContainer/MoneyCell.tooltip_text = tr("ui.money.tooltip")
$VBoxContainer/TopRow/HBoxContainer/LeftThird/HBoxContainer/GemsCell.tooltip_text  = tr("ui.gems.tooltip")
$VBoxContainer/TopRow/HBoxContainer/CenterThird.tooltip_text                      = tr("ui.social.tooltip")
$VBoxContainer/TopRow/HBoxContainer/RightThird/HBoxContainer/PauseCell.tooltip_text = tr("ui.pause.tooltip")

# Conectar señales a un controlador (ej. MainController singleton o node)
$.../MoneyCell.pressed.connect(Callable(MainController, "on_money_pressed"))
```

### 10.4 Carga de pantallas en `CentralHost`
```gdscript
extends Control
@onready var screen_root := $MarginContainer/ScreenRoot

func show_screen(scene_path: String) -> void:
    screen_root.free_children()
    var ps: PackedScene = load(scene_path)
    if ps:
        screen_root.add_child(ps.instantiate())

func Node.free_children(self):
    for c in get_children():
        c.queue_free()
```

---

## 11) QA / Checklist
- [ ] Topbar=11% (clamped), 2 filas **50/50**.
- [ ] TopRow: **3 tercios**, extremos 50/50; **orden**: Dinero, Gemas, ZONA Social, Pausa.
- [ ] Todas las celdas **clicables**, con **imagen** y **tooltip**.
- [ ] BottomRow: **ProgressBar XP** a todo ancho, estilo aplicado, opcionalmente clicable con tooltip.
- [ ] CentralHost carga pantallas sin tocar Top/Bottom.
- [ ] Botbar: 5 cuadrados 1:1 **solo imagen**, tooltips correctos.
- [ ] Safe Area OK (notch/gestos), touch targets ≥ 56 px.
- [ ] Themes aplicados (tooltip, barra XP, botones).
- [ ] Rendimiento estable en low-end (sin stutters).
- [ ] Splash: logo, tips rotativos, barra y %, versión y copyright, pausa.
- [ ] “Pulsa para empezar” visible **tras** carga mínima y listo para pasar a Main.

---

## 12) Consejos de *polish*
- Abreviaturas num: `1.2K`, `3.4M` con *locale*.
- Animación XP suave (lerp); pulso discreto al subir nivel.
- Badges en Social/Notif con contador mínimo visual (·1·).
- Retroalimentación táctil: vibración ligera en acciones críticas (Android/iOS).

---

## 13) Landscape (opcional)
- Mantén Topbar/Bottombar o migra navegación a **sidebar** (left/right) con 5 botones 1:1.
- Evita reducir la altura de la barra XP por debajo de ~24 px visual.

---

## 14) Aceptación final
Cuando todo lo anterior pase checklist en 720×1600, 1080×2400 y 1440×3200, y la *safe area* no tape nada, el layout se considera **listo para arte final** y escalado.

---

**Fin de documento.** Este MD es un *prompt* operativo para agentes IA y una guía reproducible para el equipo.
