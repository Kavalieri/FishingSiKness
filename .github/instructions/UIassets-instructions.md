
# 📱 UI Godot 4 (Portrait) — Manual Maestro de Interfaces
**Refactorización profesional + guía futura de expansión**
**Móvil (smartphone portrait) con responsividad, reusabilidad y consistencia.**

> Este documento sirve como **prompt para IA** y **guía de referencia a largo plazo**.
> Objetivo: definir la base y los patrones de **todos los elementos de UI** que usaremos en el proyecto.

---

## 0) Principios clave
- **Contenedores**: nada de posiciones absolutas. Todo `VBoxContainer`, `HBoxContainer`, `GridContainer`, `MarginContainer`, `AspectRatioContainer`.
- **Responsivo**: % + clamps + `Safe Area ON` + escalado por DPI.
- **Reutilizable**: escenas modulares (`TopBar.tscn`, `BottomBar.tscn`, `Card.tscn`, etc.).
- **Consistente**: estilos centralizados en `.theme` y `.tres` (`app.theme`, `tooltip.tres`, `progress_xp.tres`).
- **Interactivo**: todos los elementos importantes son clicables, con `tooltip_text` y estados (hover/pressed/disabled).
- **Accesibilidad**: hit-target ≥ 56 px; tooltips, contrastes, tipografías legibles.

---

## 1) Estructura base de UI
Ya definida previamente: **Topbar (11%)**, **Central (77%)**, **BottomBar (12%)**.
Con **Topbar en 2 filas (stats+XP)** y **BottomBar con 5 botones cuadrados (solo imagen)**.

Ver documento [UI_Godot_Mobile_Layout_Spec.md] como base.

---

## 2) Patrones Reutilizables (Componentes)

### 2.1 Botones
```
Button/TextureButton
└── TextureRect (Icono opcional)
└── Label (Texto opcional)
```
- **Botones principales**: `TextureButton` con imagen (SVG/PNG 32–48 px).
- **Estados** definidos en `app.theme`.
- **Botones cuadrados**: usar `AspectRatioContainer (1:1)`.

**Ejemplo ASCII**
```
[ 🎣 ]
 Pesca
```

### 2.2 Marcos (Frames)
```
PanelContainer (frame_base.tscn)
└── MarginContainer
    └── VBoxContainer (contenido)
```
- Fondo semitransparente + borde definido en `.theme`.
- Usado como base para **ventanas, menús y tarjetas**.

### 2.3 Tooltips
- Definidos en `tooltip.tres`.
- Fondo oscuro semitransparente, padding 8–12 px, radio 6 px.
- Texto 12–13 px, alto contraste.

### 2.4 Tarjetas (Cards)
```
Card.tscn
└── PanelContainer (con estilo card)
    └── VBoxContainer
        ├── TextureRect (Icono/Imagen)
        ├── Label (Título)
        ├── Label (Descripción corta)
        └── Button (Acción principal)
```
**Usos**: tienda, menú de mejoras, selección de zona.
**Ejemplo ASCII**
```
+───────────────+
|    [🎣 IMG]   |
|   Caña Lv.1   |
|  +5% pesca    |
|   [Mejorar]   |
+───────────────+
```

### 2.5 Tarjetas Informativas Emergentes
```
InfoCard.tscn
└── PanelContainer (overlay)
    └── VBoxContainer
        ├── Label (Título grande)
        ├── TextureRect (Imagen opcional)
        └── Label (Texto largo/descripción)
```
Se muestran sobre el CentralHost, con **animación fade/slide**.

### 2.6 Ventana Emergente (Popup Window)
```
PopupWindow.tscn (deriva de Window o Control con Modal=true)
└── PanelContainer (frame estilo ventana)
    └── VBoxContainer
        ├── Label (Título)
        ├── Control (Contenido dinámico)
        └── HBoxContainer (Botones OK/Cancelar)
```
**Ejemplo ASCII**
```
+─────────────────────+
|    Opciones Juego   |
| ──────────────────  |
|  Música: [ON]       |
|  Sonido: [ON]       |
| ──────────────────  |
| [Aceptar] [Cancelar]|
+─────────────────────+
```

### 2.7 Menú Emergente (Dropdown/PopupMenu)
```
PopupMenu (nativo de Godot)
```
Se invoca desde un botón (ej. Social, Pausa).
Items definidos vía script o CSV.

**Ejemplo ASCII**
```
[⏸]
 ▼
 ┌───────────────┐
 │ Reanudar      │
 │ Opciones      │
 │ Salir         │
 └───────────────┘
```

---

## 3) Ejemplos de Escenas Reutilizables

### 3.1 Ventana de Opciones
```
OptionsWindow.tscn (hereda PopupWindow)
└── VBoxContainer
    ├── HBoxContainer (Label "Música", CheckButton)
    ├── HBoxContainer (Label "Sonido", CheckButton)
    ├── HBoxContainer (Label "Idioma", OptionButton)
    └── HBoxContainer (Botones)
```
**Uso**: invocado desde botón Pausa.

### 3.2 Tienda
```
ShopScreen.tscn
└── ScrollContainer
    └── GridContainer (col=2–3 según ancho)
        ├── Card (ítem 1)
        ├── Card (ítem 2)
        └── ...
```
**ASCII**
```
+───────+ +───────+
|  🐟   | |  🎣   |
| Pez A | | Caña  |
| $100  | | $300  |
| Buy   | | Buy   |
+───────+ +───────+
```

### 3.3 Ventana Emergente de Recompensa
```
RewardPopup.tscn
└── PopupWindow
    └── VBoxContainer
        ├── TextureRect (Icono grande recompensa)
        ├── Label ("¡Has ganado 500 gemas!")
        └── Button ("Aceptar")
```

### 3.4 Selección de Zona
```
ZoneSelectScreen.tscn
└── GridContainer (col=2)
    ├── Card (Bosque)
    ├── Card (Mar)
    ├── Card (Desierto)
    └── Card (Espacio)
```
Cada Card: imagen zona + título + tooltip.

---

## 4) SplashScreen (extendida)
Incluye:
- Fondo (`TextureRect` + overlay ColorRect para contraste).
- Logotipo centrado.
- Barra de carga + % + consejos rotativos.
- Botón de Pausa (arriba derecha).
- “Pulsa para empezar” (tras carga mínima).
- Footer: versión + copyright.

**ASCII**
```
+──────────────────────────────+
| [Background IMG]             |
|                     [⏸]      |
|                              |
|           [LOGO]             |
|                              |
|     "Pulsa para empezar"     |
|                              |
|  Tip: Mejora tu caña...      |
|                              |
| Cargando: ███████░░  70%     |
|                              |
| v0.3.1       © 2025 SiKStud  |
+──────────────────────────────+
```

---

## 5) Sprites e Imágenes
- **Iconos pequeños** (stats/topbar): 24–28 px, SVG si posible.
- **Botones/botbar**: 32–40 px, SVG/PNG optimizado.
- **Tarjetas**: imágenes 64–128 px según arte.
- **Fondos**: 720p para bajo, 1080p–1440p para medio/alto. Usa `TextureRect.STRETCH_KEEP_ASPECT_COVER`.
- **Optimización**: compresión ETC2/ASTC en Android, mipmaps ON.

---

## 6) Themes (.tres)

### 6.1 `app.theme`
- Tipografía global (labels/buttons).
- Colores primarios/secundarios.
- Botones: estados + paddings + bordes.
- PanelContainer: bordes redondeados.

### 6.2 `tooltip.tres`
- Fondo negro 70% opacidad.
- Padding 8–12 px.
- Texto blanco 12–13 px.

### 6.3 `progress_xp.tres`
- Fondo gris oscuro.
- Fill degradado azul/verde.
- Bordes finos.
- Animación al ganar XP (Tween).

### 6.4 `card.theme`
- Fondo claro/oscuro con sombra.
- Padding interno uniforme.
- Borde redondeado 6–8 px.

---

## 7) Diagramas ASCII comparativos

### Ventana emergente vs Tarjeta
```
Ventana (PopupWindow)
+──────────────────+
|   Título         |
|  contenido...    |
| [OK] [Cancelar]  |
+──────────────────+

Tarjeta (Card)
+─────────+
|  [IMG]  |
| Nombre  |
| Precio  |
| [Buy]   |
+─────────+
```

### Menú emergente vs Ventana
```
Menú
[⏸] ▼
 ┌─────────────┐
 │ Reanudar    │
 │ Opciones    │
 │ Salir       │
 └─────────────┘

Ventana Opciones
+──────────────────+
| Opciones Juego   |
| Música: ON/OFF   |
| Sonido: ON/OFF   |
| Idioma: EN/ES    |
| [Aceptar] [Cancelar]
+──────────────────+
```

---

## 8) Guía de expansión futura
- **Nuevos elementos** deben ser subescenas reutilizables.
- **Siempre** usar contenedores y flags, nunca posiciones absolutas.
- **Theme centralizado**: cualquier nuevo elemento se conecta a `app.theme`.
- **Documentar** cada nuevo patrón en este manual, con ASCII y estructura.
- **Versionar**: mantener `docs/ui/CHANGELOG_UI.md` para cambios de diseño.
- **Testing QA**: probar en 720×1600, 1080×2400 y 1440×3200.

---

## 9) Checklist final
- [ ] Topbar y Bottombar correctos con imágenes+tooltips.
- [ ] XP Progress estilada y clicable.
- [ ] Splash completa con logo, carga, tips, footer.
- [ ] Componentes reusables listos: botones, tarjetas, ventanas, menús.
- [ ] Themes creados (`app.theme`, `tooltip.tres`, `progress_xp.tres`, `card.theme`).
- [ ] Escenas de ejemplo: OptionsWindow, ShopScreen, RewardPopup, ZoneSelect.
- [ ] Fondos optimizados, imágenes escalables.
- [ ] QA hecho en múltiples resoluciones.
- [ ] Safe Area respetada.

---

**Este documento es el punto único de verdad (single source of truth) para la UI del proyecto.**
Todo elemento nuevo debe seguirlo o actualizarlo.
Sirve tanto como **prompt para IA** como para el **equipo humano** de desarrollo.
