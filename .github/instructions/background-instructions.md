
# 🎯 Post‑Refactor: Fondo Único Global con UI Transparente/Translúcida (Godot 4, Mobile Portrait)

**Modo prompt para agente IA + guía paso a paso.**  
Objetivo: Sustituir fondos locales de escenas por **un único fondo principal** en `Main.tscn` y **pintar toda la UI encima** con transparencias o texturas a demanda, manteniendo responsividad, Safe Area y estilos centralizados.

---

## 0) Resultado esperado (contrato)
- `Main.tscn` contiene **un único `TextureRect`** de fondo que cubre toda la pantalla.
- Todas las secciones de UI (TopBar, CentralHost, BottomBar, ventanas, tarjetas) **no tienen fondo sólido** salvo cuando se especifique **translúcido** (velo) o **texturizado** (marco) mediante *theme overrides*.
- El cambio de fondo se realiza **sin tocar** TopBar/BottomBar/CentralHost (aislados del fondo).
- Se puede cambiar **en caliente**: color → imagen → otra imagen → degradado, etc.
- **Safe Area ON**. Touch targets ≥ 56 px. No posiciones absolutas.

---

## 1) Pre‑requisitos
- Proyecto ya refactorizado con estructura base (Top 11% / Central 77% / Bottom 12%).  
- `Main.tscn` con `VBoxContainer` para layout vertical.
- TopBar y BottomBar **no dependen** de imágenes de fondo propias (o se retirarán).
- `app.theme` aplicado globalmente.

---

## 2) Cambios en Main.tscn (fondo único global)

### 2.1 Estructura final
```
Main (Control)
├── TextureRect (Background)           # fondo global (opaco)
└── VBoxContainer                      # topbar / central / bottombar
    ├── TopBar       (instancia)
    ├── CentralHost  (instancia)
    └── BottomBar    (instancia)
```

### 2.2 Configuración del Background
- Nodo: `TextureRect (name: Background)`
- Props:
  - `expand = true`
  - `stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVER`
  - `texture = preload("res://assets/ui/backgrounds/main_bg_1080p.png")`
  - (opcional) `modulate = Color(1,1,1,1)` (se puede tintar dinámicamente)

**ASCII**
```
[ TextureRect (BG opaco) ]
  └─ VBoxContainer (UI transparente/translúcida encima)
```

### 2.3 Orden de dibujo
- Asegúrate de que **Background** está **antes** del `VBoxContainer` (debajo en el árbol).  
  En Control, el orden del árbol define el *z-order* (de atrás hacia delante).

---

## 3) Limpieza de fondos locales (Top/Bottom/Central)
**Objetivo**: dejar los elementos “limpios”, listos para ser transparentes o con velo/marco según convenga.

### 3.1 TopBar / BottomBar
- Sustituir cualquier `PanelContainer` con estilo sólido por uno sin fondo:
  - `add_theme_stylebox_override("panel", StyleBoxEmpty.new())`
- Si necesitas **translúcido** (velo):
  - `add_theme_stylebox_override("panel", preload("res://themes/panel_translucent.tres"))`

### 3.2 CentralHost y pantallas
- Las pantallas no deben traer fondos opacos salvo diseño explícito.
- Cualquier fondo sólido/imagen usado **como “tapete”** debe migrarse a un `PanelContainer` con:
  - **Por defecto**: `StyleBoxEmpty` (transparente).
  - **Según necesidad**: `StyleBoxFlat` (alpha 0.15–0.35) o `StyleBoxTexture` (marco).

---

## 4) Estilos reutilizables (themes `.tres`)

### 4.1 Transparente total
- `StyleBoxEmpty` (sin color, sin borde):
```gdscript
$Node.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
```

### 4.2 Translúcido (velo)
- `res://themes/panel_translucent.tres` (StyleBoxFlat)
  - `bg_color = Color(0,0,0,0.25)`
  - `corner_radius = 6..10`
  - `border_width = 0..1` (opcional bajo)
**Uso**:
```gdscript
$Node.add_theme_stylebox_override("panel", preload("res://themes/panel_translucent.tres"))
```

### 4.3 Texturizado (marco/tablilla)
- `res://themes/panel_textured.tres` (StyleBoxTexture)
  - `texture = preload("res://assets/ui/frames/frame_wood.png")`
  - `draw_center = true`
  - `modulate_color = Color(1,1,1,1)` (tinte opcional)
**Uso**:
```gdscript
$Node.add_theme_stylebox_override("panel", preload("res://themes/panel_textured.tres"))
```

> **Regla**: por *defecto transparente*, **elevar** a translúcido o texturizado **solo** donde aporte legibilidad/jerarquía.

---

## 5) Cambios en caliente (API de tema/fondo)

### 5.1 Cambiar imagen de fondo en runtime
```gdscript
# Main.gd
@onready var bg: TextureRect = $Background

func set_background(tex_path: String, modulate_color: Color = Color(1,1,1,1)) -> void:
    var tex: Texture2D = load(tex_path)
    if tex:
        bg.texture = tex
        bg.modulate = modulate_color
```

### 5.2 Forzar transparencia/translucidez por escena
```gdscript
# En _ready() de TopBar.gd (ejemplo)
func _ready() -> void:
    # Transparente total:
    add_theme_stylebox_override("panel", StyleBoxEmpty.new())

    # O velo translúcido:
    # add_theme_stylebox_override("panel", preload("res://themes/panel_translucent.tres"))
```

### 5.3 Reemplazo temático global (por Theme único)
- Asigna `app.theme` al `Main` o a `ProjectSettings` y luego **override** finos por nodo donde toque.
- No copies estilos en cada escena; **reutiliza** `.tres`.

---

## 6) Fondos: guía y assets
- Rutas: `res://assets/ui/backgrounds/`
- Variantes:
  - `main_bg_720p.png` (baja), `main_bg_1080p.png` (media), `main_bg_1440p.png` (alta)
- `TextureRect.STRETCH_KEEP_ASPECT_COVER` para cubrir sin deformar.
- **Overlay** (opcional): `ColorRect` negro con `alpha` 0.2–0.35 para mejorar contraste de textos.
- Optimización Android: ETC2/ASTC, mipmaps ON, compresión al empaquetar.

---

## 7) ASCII: casos típicos

### 7.1 UI transparente sobre fondo único
```
[ BG ── imagen opaca a pantalla completa ]
+───────────────────────────────────────+
|  TopBar (transparente)               |
|--------------------------------------|
|  CentralHost (contenido libre)       |
|--------------------------------------|
|  BottomBar (transparente)            |
+───────────────────────────────────────+
```

### 7.2 UI con velo sutil (solo contenedores)
```
[ BG ]
+───────────────────────────────────────+
|  TopBar (velo 25%)                    |
|--------------------------------------|
|  CentralHost (transparente)          |
|--------------------------------------|
|  BottomBar (velo 25%)                |
+───────────────────────────────────────+
```

### 7.3 Panel/ventana con marco texturizado
```
[ BG ]
       +────────────────────+
       |  [marco textura]   |  ← StyleBoxTexture
       |  contenido...      |
       |  [OK]  [Cancelar]  |
       +────────────────────+
```

---

## 8) Safe Area y responsividad
- `Project > Display > Window > Handheld > Use Safe Area = ON`.
- El fondo cubre todo; Top/Bottom se ajustan **dentro** de la safe area.
- % verticales (11/77/12) + clamps (Top 64–96 px, Bottom 72–104 px).
- Touch targets ≥ 56 px; iconos Topbar 24–28 px; Botbar 32–40 px.

---

## 9) Checklist de migración
1. [ ] Agregar `TextureRect (Background)` en `Main.tscn` **debajo** del `VBoxContainer`.
2. [ ] Retirar fondos opacos locales en TopBar/BottomBar/Central y sustituir por `StyleBoxEmpty`.
3. [ ] Crear `panel_translucent.tres` (velo) y `panel_textured.tres` (marco).
4. [ ] Aplicar overrides **solo** donde aporte (legibilidad/jerarquía).
5. [ ] Probar en 720×1600, 1080×2400, 1440×3200 con Safe Area.
6. [ ] Validar contraste con y sin overlay.
7. [ ] Medir memoria/PNG/SVG y ajustar compresión.
8. [ ] Documentar en `docs/ui/CHANGELOG_UI.md` la migración y estilos usados.

---

## 10) Prompt de operación para agente IA
> **Acción**: Migrar el proyecto a **fondo global único** y UI transparente/translúcida para que todo comparta el mismo fondo.
> 
> **Pasos obligatorios**:
> 1. En `Main.tscn`, crear `TextureRect (Background)` antes del `VBoxContainer`, con `expand=true` y `STRETCH_KEEP_ASPECT_COVER`. Cargar `res://assets/ui/backgrounds/main_bg_1080p.png`.
> 2. Asegurar que TopBar/BottomBar/CentralHost **no tienen fondos opacos**. Sustituir por `StyleBoxEmpty`. Donde convenga legibilidad, aplicar `panel_translucent.tres`.
> 3. Preparar `panel_textured.tres` para marcos de ventanas/tarjetas específicas y usarlo solo en esos casos.
> 4. Mantener Safe Area ON, ratios 11/77/12, clamps (Top 64–96, Bottom 72–104), hit-target ≥ 56 px.
> 5. Entregar script utilitario en `Main.gd` con `set_background(tex_path, modulate_color)` para cambiar fondo en runtime.
> 6. Validar en resoluciones 720×1600, 1080×2400, 1440×3200 y subir capturas.
> 7. Actualizar documentación en `docs/ui` y dejar comentarios `# UI-BG-GLOBAL` en nodos afectados.

---

## 11) Rollback rápido (si algo falla)
- Deshabilita overrides: `add_theme_stylebox_override("panel", null)`.
- Quita textura del `Background` o apágalo (visible=false) para ver si un panel mantiene un fondo incorrecto.
- Verifica orden de nodos: el BG debe estar **antes** (debajo) del `VBoxContainer`.
- Revisa overlays/ColorRect con alpha demasiado alto.

---

## 12) Notas de estilo
- Por defecto todo **transparente**; sube a **translúcido** solo si el texto pierde legibilidad.
- Evita texturas de marco pesadas; usa 9‑patch (`StyleBoxTexture` con márgenes) para escalado limpio.
- Mantén las fuentes y tamaños en `app.theme`.

---

**Fin.** A partir de ahora, el fondo de la app es único y la UI lo respeta. Cambiar look & feel pasa por: cambiar la textura del BG, regular velos (alpha) y elegir texturas de marco donde toque.  
