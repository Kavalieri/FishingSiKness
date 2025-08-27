# PROMPT IA — TopBar profesional integrada en `main.tscn` (Godot 4.x, idle de pesca vertical)

> **Objetivo del proyecto**: Integrar una **TopBar** en la escena principal `main.tscn` que muestre **Dinero**, **Diamantes**, **Zona**, **Nivel** y **Barra de XP**, con **botón de Opciones** en la esquina superior derecha. Debe **adaptarse al proyecto en curso** (nombres de escenas/ventanas ya existentes, señales ya creadas) y permitir **migrar** desde una barra generada por código a una **escena independiente** reutilizable.

---

## 1) Alcance y principios (adaptado al proyecto en curso)

- La TopBar debe:
  - Mostrar datos: **Dinero**, **Diamantes**, **Zona**, **Nivel**, **XP**.
  - Cada bloque es **botón**: abre ventana asociada (si existe) y muestra **tooltip** (hover) o **long‑press** (móvil).
  - Incluir **botón de Opciones** (⚙) arriba a la derecha.
  - **No romper** resoluciones: diseño con **Containers**, sin posiciones mágicas.
  - Respetar **Safe Areas** y **Theme** del proyecto.
  - **Acoplarse** a las **señales y ventanas** ya presentes: usar **alias** para mapear a las escenas reales.

- Diferencias clave por **adaptación al proyecto** (no consejo genérico):
  - **No** asumas nombres fijos de ventanas: usa **alias** → se resuelven en `WindowManager` actual del proyecto.
  - **No** dupliques señales existentes: **conéctate** a las ya definidas en `GameState`.
  - **Mantén** la compatibilidad temporal con funciones antiguas del HUD mediante **adaptadores**.

---

## 2) Variantes de diseño (elige según estética y espacio)

### Variante A — **Una sola línea** (compacta, pro)
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ [$ 1.23M]  [💎 240]  [ZONA: Lago Estelar]  [LVL 12]  [XP ▓▓▓▓░ 45%]   [⚙] │
└─────────────────────────────────────────────────────────────────────────────┘
```
- **Recomendado** si la pantalla no está muy cargada y quieres todo visible en una franja.
- El bloque **Zona** y el bloque **XP** deben llevar `Expand|Fill` para absorber ancho.
- El botón **⚙ Opciones** anclado a la derecha con tamaño táctil ≥ 96×96 (base 1080×1920).

### Variante B — **Dos líneas** (aire y legibilidad)
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ [$ 1.23M]   [💎 240]           [ZONA: Lago Estelar]              [⚙ Opc.] │
│ [LVL 12]                      [XP ▓▓▓▓▓░ 45% (toque)]                         │
└─────────────────────────────────────────────────────────────────────────────┘
```
- **Más profesional** si priorizas legibilidad. Útil con idiomas largos o UI densa.
- Fila 1: Dinero, Diamantes, Zona, ⚙ Opciones. Fila 2: Nivel + XP con expansión.

> **Adaptación**: usa la **misma escena** con estructura `VBoxContainer` que contiene dos `HBoxContainer`. Cambiar entre A/B es solo cuestión de layout, **sin cambiar lógica** ni señales.

---

## 3) Árbol de nodos propuesto

### Para Variante A (una línea)
```
TopBar (HBoxContainer)                # altura mínima 112–128 px
  BtnMoney   (Button)
  BtnGems    (Button)
  BtnZone    (Button)      # H: Expand|Fill
  BtnLevel   (Button)
  XPBlock    (HBoxContainer)  # H: Expand|Fill
    BtnXP    (Button)         # hitbox (flat/transparent), tooltips/long-press
    XPBar    (ProgressBar)    # 0..100
  BtnOptions (Button)         # ⚙ anclado a derecha
```

### Para Variante B (dos líneas)
```
TopBar (VBoxContainer)
  Row1 (HBoxContainer)
    BtnMoney   (Button)
    BtnGems    (Button)
    BtnZone    (Button)      # H: Expand|Fill
    BtnOptions (Button)      # ⚙
  Row2 (HBoxContainer)
    BtnLevel   (Button)
    XPBlock    (HBoxContainer)  # H: Expand|Fill
      BtnXP    (Button)
      XPBar    (ProgressBar)    # 0..100
```

> **Adaptación**: Elige A o B según tu HUD actual. Mantén **nombres de nodos** estables para no reescribir scripts que dependan de ellos.

---

## 4) Señales y contratos (encaje con lo ya creado)

### `GameState` (autoload actual del proyecto)
- Señales **ya existentes** (usa estas, no redefinas):
  - `money_changed(int)`
  - `diamonds_changed(int)`
  - `zone_changed(String)`
  - `level_changed(int)`
  - `xp_changed(int current, int required)`
- Propiedades esperadas (lectura inicial):
  - `money:int`, `diamonds:int`, `zone_name:String`, `level:int`, `xp_current:int`, `xp_required:int`

### `WindowManager` (autoload actual del proyecto)
- Método de apertura **ya existente**:
  - `open(alias:String) -> void`
- **Alias** (mapéalos al proyecto real):
  - `"money" | "diamonds" | "zone" | "level" | "xp" | "options"`

### `TopBar` (nueva escena)
- **Señales publicadas** (para no acoplar a una sola implementación de ventanas):
  - `open_requested(alias:String)`  → con valores arriba
- **Métodos públicos** (para wiring externo si no haces self‑wiring):
  - `set_money(int)`, `set_diamonds(int)`, `set_zone(String)`, `set_level(int)`
  - `set_xp(int current, int required)`
  - `sync_from_state(gs:Node)`

---

## 5) Implementación — `TopBar.gd` (núcleo)

```gdscript
extends Container
signal open_requested(alias:String)

@onready var btn_money  : Button      = %BtnMoney
@onready var btn_gems   : Button      = %BtnGems
@onready var btn_zone   : Button      = %BtnZone
@onready var btn_level  : Button      = %BtnLevel
@onready var xp_bar     : ProgressBar = %XPBar
@onready var btn_xp     : Button      = %BtnXP
@onready var btn_options: Button      = %BtnOptions

func _ready() -> void:
    # Tooltips (desktop); móvil usa long-press (ver sección 7)
    btn_money.hint_tooltip  = tr("Dinero. Toca para ver detalles.")
    btn_gems.hint_tooltip   = tr("Diamantes. Tienda.")
    btn_zone.hint_tooltip   = tr("Zona actual.")
    btn_level.hint_tooltip  = tr("Nivel de jugador.")
    btn_xp.hint_tooltip     = tr("Progreso hacia el siguiente nivel.")
    btn_options.hint_tooltip= tr("Opciones")

    # Botones → solicitud de apertura por alias (WindowManager decide la ventana real)
    btn_money.pressed.connect(func(): emit_signal("open_requested", "money"))
    btn_gems.pressed.connect(func(): emit_signal("open_requested", "diamonds"))
    btn_zone.pressed.connect(func(): emit_signal("open_requested", "zone"))
    btn_level.pressed.connect(func(): emit_signal("open_requested", "level"))
    btn_xp.pressed.connect(func(): emit_signal("open_requested", "xp"))
    btn_options.pressed.connect(func(): emit_signal("open_requested", "options"))

    # Self‑wiring opcional (adáptate al GameState del proyecto)
    var gs := get_node_or_null("/root/GameState")
    if gs:
        if not gs.is_connected("money_changed", set_money):
            gs.money_changed.connect(set_money)
            gs.diamonds_changed.connect(set_diamonds)
            gs.zone_changed.connect(set_zone)
            gs.level_changed.connect(set_level)
            gs.xp_changed.connect(set_xp)
        sync_from_state(gs)

# ---- setters públicos (para wiring externo si no usas self‑wiring) ----
func set_money(v:int) -> void:
    btn_money.text = _fmt_money(v)

func set_diamonds(v:int) -> void:
    btn_gems.text = str(v)

func set_zone(name:String) -> void:
    btn_zone.text = tr("Zona: ") + name

func set_level(l:int) -> void:
    btn_level.text = tr("Lvl ") + str(l)

func set_xp(current:int, required:int) -> void:
    var p := (required > 0) ? float(current)/float(required) : 0.0
    xp_bar.value = clampf(p * 100.0, 0.0, 100.0)
    xp_bar.tooltip_text = "%d / %d (%.0f%%)" % [current, required, xp_bar.value]

func sync_from_state(gs:Node) -> void:
    set_money(gs.money)
    set_diamonds(gs.diamonds)
    set_zone(gs.zone_name)
    set_level(gs.level)
    set_xp(gs.xp_current, gs.xp_required)

# ---- utilidades ----
func _fmt_money(n:int) -> String:
    var f := float(n)
    if f >= 1_000_000_000.0: return "%.2fB" % (f/1_000_000_000.0)
    if f >= 1_000_000.0:     return "%.2fM" % (f/1_000_000.0)
    if f >= 1_000.0:         return "%.2fK" % (f/1_000.0)
    return str(n)
```

> **Adaptación**: los textos de los botones pueden ser **icono + texto** o solo icono, según tu Theme. No incrustes textos en imágenes; deja el texto en el nodo (`.text`) para localización y accesibilidad.

---

## 6) Integración con `main.tscn` (y migración desde barra por código)

### 6.1 Añadir TopBar a `main.tscn`
- Si ya tienes un `CanvasLayer` de UI, **instancia** `TopBar.tscn` dentro. Si no:
```
CanvasLayer (layer=10)
  Control name=UIRoot [Anchors FullRect]
    MarginContainer name=SafeArea (márgenes por notch)
      [instancia de TopBar.tscn]
```
- **Ancla** la TopBar arriba (Full Width). Define `custom_minimum_size.y = 112..128`.

### 6.2 Conectar a `WindowManager` desde `main.gd` (en tu proyecto)
```gdscript
@onready var topbar := $CanvasLayer/UIRoot/SafeArea/TopBar
@onready var wm     := get_node("/root/WindowManager")

func _ready() -> void:
    # TopBar → WindowManager (alias → ventana real)
    topbar.open_requested.connect(func(alias:String): wm.open(alias))
```

### 6.3 Migración: barra generada por código → escena independiente
1) Localiza el bloque que **crea botones/labels** de topbar **por código**.
2) Crea `disable_legacy_topbar()` que **oculte/elimine** esos nodos.
3) Instancia `TopBar.tscn` en el **mismo contenedor** UI que usabas.
4) **Reutiliza** tus señales existentes:
   - Si antes conectabas `GameState.money_changed` a `update_money_ui(v)`, ahora conecta a `topbar.set_money(v)` (o confía en el self‑wiring).
5) **Adaptador temporal** (mantiene compatibilidad de llamadas antiguas):
```gdscript
func update_money_ui(v:int) -> void:
    if is_instance_valid(topbar):
        topbar.set_money(v)
```
6) Cuando verifiques paridad funcional, **elimina** el código legacy.

> **Adaptación**: si tus alias o nombres de propiedades no coinciden (`zone` vs `region`, `diamonds` vs `gems`), crea un **mapper** en `WindowManager` y ajusta los setters en `TopBar` o usa los correctos.

---

## 7) UX móvil: tooltips y long‑press (adaptado a tu HUD)

- **Desktop**: `hint_tooltip` ya funciona.
- **Móvil**: implementa **long‑press** → abre `TooltipPanel` o micro‑overlay
  - Integrar con tu sistema existente. Ejemplo mínimo:
```gdscript
func _attach_long_press(btn:Button) -> void:
    btn.gui_input.connect(func(e):
        if e is InputEventScreenTouch:
            if e.pressed: btn.set_meta("t0", Time.get_ticks_msec())
            else:
                var dt = Time.get_ticks_msec() - int(btn.get_meta("t0", 0))
                if dt > 400: _show_touch_tooltip(btn) # adapta a tu TooltipPanel
    )
```
- **Opciones (⚙)**: puede abrir un **Panel** modal o una **ventana lateral** (según tu patrón actual). Alias estándar: `"options"`.

---

## 8) Responsive, Theme y safe area (alineado con tu proyecto)

- Project → Display → Window → Stretch: **Mode `canvas_items`, Aspect `keep`**.
- `SafeArea` (MarginContainer) con márgenes del notch vía `DisplayServer.get_display_safe_area()`.
- Theme del proyecto:
  - Botones con **icono + texto** coherentes.
  - `ProgressBar` con alto legible y contraste; opcional icono de pez a la izquierda.
  - Tipografías legibles (14–16 pt base, 18–20 pt títulos).

---

## 9) Pruebas (centradas en tu integración)

- Cambia los valores en `GameState` y comprueba actualización inmediata (sin `_process()`).
- `open_requested` dispara `WindowManager.open(alias)` para cada botón (incl. `"options"`).
- Verifica legibilidad en 19.5:9, 20:9, 16:9, y tablet 4:3.
- Táctil: áreas ≥ 96×96 px en base 1080×1920.
- Localización: `tr()` funcionando; textos dinámicos sin desbordes en Variante B.

---

## 10) Checklists (listo para commit)

**Funcionalidad:**
- [ ] TopBar instanciada en `main.tscn` (posición superior, full width).
- [ ] `open_requested` → `WindowManager.open(alias)` (incluye `"options"`).
- [ ] Señales de `GameState` conectadas o self‑wiring activo.
- [ ] `set_*()` funcionan y `sync_from_state()` inicializa todo.
- [ ] XP muestra % correcto y tooltip con `cur/req`.

**UI/UX:**
- [ ] Variante A/B elegida según tu HUD; sin solapamientos.
- [ ] Theme aplicado; iconos + textos consistentes.
- [ ] Tooltips/long‑press integrados al sistema del proyecto.
- [ ] Safe Area respetada.

**Código:**
- [ ] Mapper de **alias** actualizado en `WindowManager`.
- [ ] Adaptadores temporales para calls legacy (si existen).
- [ ] Eliminada la barra legacy tras verificación.

---

### Nota final
Este prompt **no impone nombres rígidos**: define alias y contratos para **encajar** con tus escenas/ventanas/estados **existentes**. La IA debe **instanciar `TopBar.tscn`**, cablearla a **`GameState` / `WindowManager`**, y migrar tu barra previa **sin romper** el flujo actual.
