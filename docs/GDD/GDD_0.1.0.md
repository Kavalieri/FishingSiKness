# Fishing SiKness — GDD Global (Godot 4.4)

> **Objetivo**: Juego de pesca 2D para smartphone (retrato) con navegación por pestañas permanentes, core loop mínimo y progresión infinita. Arquitectura **100% data‑driven** para que peces, zonas, herramientas y tienda se añadan creando **solo** nuevos `.tres` en `res://data/**` sin tocar código ni escenas. Monetización **no intrusiva** (gemas, boosters, cosméticos, ads recompensados) reservada desde el día 1.

---

## 1) Concepto
- **Nombre**: **Fishing SiKness**.
- **Bucle**: Lanzar → Esperar → QTE breve → Captura → Inventario (Nevera) → Vender → Mejorar.
- **Pilares**: one‑tap/one‑hand, sesiones cortas, feedback claro, rendimiento móvil, modularidad extrema.
- **Inspiraciones**: Hooked Inc, Fishing Life, Ridiculous Fishing (sin copiar complejidad; mantener MVP limpio).

---

## 2) Plataforma
- **Android** objetivo; **Windows** para debug; **iOS** futuro.
- **Orientación**: Retrato (9:16). **Resolución lógica**: 1080×1920.
- **Framerate**: 60 fps objetivo; desactivar procesos en vistas ocultas.

---

## 3) Progresión
- **Divisas**
  - **Monedas** (soft): venta de capturas, recompensas.
  - **Gemas** (hard): packs IAP, logros/eventos, **anuncios recompensados**.
- **Upgrades** (lineales con coste geométrico): Caña, Carrete, Anzuelo, Cebo (temporal), Nevera (capacidad), Mapa (desbloqueo de zonas).
- **Zonas** (biomas): Orilla → Lago → Río → Costa → Mar… Cada zona define **tabla de loot** y **multiplicador** de precio.
- **Prestigio** (futuro): reset de upgrades a cambio de multiplicador permanente y meta‑moneda (“Escamas”). Hooks preparados.

---

## 4) Pantallas **(pestañas permanentes)**
**Barra superior**: Monedas · **💎 Gemas [ + ]** (abre Tienda) · Zona · ⚙ Ajustes.
**Barra inferior** (fija): `🐟 Pescar` · `🧊 Nevera` · `🛒 Mercado` · `⬆ Mejoras` · `🗺 Mapa`.
Badges en pestañas para novedades/acciones disponibles.

### 4.1 Pescar (home)
```
+------------------------------------------------+
| Monedas: 12,345   💎 120 [ + ]   Zona: Orilla [⚙]|
|------------------------------------------------|
|                 ~ Agua animada ~               |
|                                                |
|                [   BARRA  QTE   ]              |
|                     (aguja)                    |
|                                                |
|                     [ LANZAR ]                 |
|                                                |
|------------------------------------------------|
| 🐟 Pescar | 🧊 Nevera | 🛒 Mercado | ⬆ Mejora | 🗺 Mapa |
+------------------------------------------------+
```

### 4.2 Nevera (Inventario)
```
+------------------------------------------------+
| Capacidad 7/12      💎 120 [ + ]         [⚙]   |
|------------------------------------------------|
| [Sardina 12c] [Trucha 20c] [Lubina 30c]        |
| [Atún 55c]    [Vacío]      [Vacío]             |
|------------------------------------------------|
| [ VENDER SELECCIÓN ]   [ VENDER TODO ]         |
|------------------------------------------------|
| 🐟 Pescar | 🧊 Nevera | 🛒 Mercado | ⬆ Mejora | 🗺 Mapa |
+------------------------------------------------+
```

### 4.3 Mercado
```
+------------------------------------------------+
| MERCADO (Orilla)      💎 120 [ + ]       [⚙]   |
|------------------------------------------------|
| Sardina (3u)            36c   [ VENDER ]       |
| Trucha  (2u)            40c   [ VENDER ]       |
|------------------------------------------------|
| [ VENDER TODO ]   Precio x1.0 (zona Orilla)    |
|  — Tip: Booster x2 valor 5 min en Tienda —     |
|------------------------------------------------|
| 🐟 Pescar | 🧊 Nevera | 🛒 Mercado | ⬆ Mejora | 🗺 Mapa |
+------------------------------------------------+
```

### 4.4 Mejoras
```
+------------------------------------------------+
| MEJORAS                 💎 120 [ + ]     [⚙]   |
|------------------------------------------------|
| Caña   Lv2  Coste: 100c   [+]  (↑ tensión)     |
| Carrete Lv1  Coste: 150c   [+]  (↑ recup.)     |
| Anzuelo Lv1  Coste: 120c   [+]  (↑ rareza)     |
| Nevera Lv3   Coste: 200c   [+]  (↑ capacidad)  |
| — Te faltan 20c. Compra paquete de Monedas —   |
| [ IR A TIENDA ]                                 |
|------------------------------------------------|
| 🐟 Pescar | 🧊 Nevera | 🛒 Mercado | ⬆ Mejora | 🗺 Mapa |
+------------------------------------------------+
```

### 4.5 Mapa
```
+------------------------------------------------+
| MAPA                     💎 120 [ + ]    [⚙]   |
|------------------------------------------------|
| [ Orilla ✓ ]  [ Lago  🔒 ]  [ Río   🔒 ]        |
| [ Costa  🔒 ]  [ Mar   🔒 ]  [ Océano 🔒 ]       |
|------------------------------------------------|
| Info zona: Orilla  — Multiplicador x1.0        |
| Peces: Sardina, Boquerón, Carpa, Trucha…       |
| [ VIAJAR ]                                     |
|------------------------------------------------|
| 🐟 Pescar | 🧊 Nevera | 🛒 Mercado | ⬆ Mejora | 🗺 Mapa |
+------------------------------------------------+
```

### 4.6 Tienda (overlay modal)
```
+------------------------------------------------+
|                 TIENDA (modal)                 |
|  Monedas: 12,345      💎 120                   |
|------------------------------------------------|
| Paquetes de Gemas                               |
|  • 120 💎  — 0,99€   [ COMPRAR ]               |
|  • 650 💎  — 4,99€   [ COMPRAR ]               |
|  • 1,400 💎 — 9,99€  [ COMPRAR ]               |
|------------------------------------------------|
| Boosters (Gemas o Ads)                          |
|  • x2 Valor 5 min  [ 40💎 ]  [ VER ANUNCIO ]    |
|  • Auto‑fish 15 min [ 60💎 ]  [ VER ANUNCIO ]    |
|------------------------------------------------|
| Cosméticos (skins caña/barco/UI)               |
|  • Skin “Madera Pro”  [ 200💎 ]                 |
|------------------------------------------------|
| [ RESTAURAR COMPRAS ]      [ CERRAR ]          |
+------------------------------------------------+
```

---

## 5) UX/UI
- **TopBar**: Monedas (izq), **Gemas [ + ]** (centro‑izq), Zona (centro), ⚙ (der).
- **BottomTabs**: 5 pestañas fijas (48–56 dp); icono+texto; badges para avisos.
- **Acción principal**: **LANZAR** centrado/float; vibración leve y SFX.
- **Accesibilidad**: targets ≥48dp, contraste ≥4.5:1, modo zurdo (swap bottom).

---

## 6) Arquitectura Godot (pestañas + data‑driven)
### Estructura
```
res://
  scenes/core/
    Main.tscn            # Root: TopBar, ScreenManager, BottomTabs
    Dialogs.tscn         # Overlays: Ajustes, Confirm, Tienda
  scenes/views/
    Fishing.tscn
    Fridge.tscn
    Market.tscn
    Upgrades.tscn
    Map.tscn
  src/ui/
    TopBar.gd
    BottomTabs.gd        # Enruta pestañas (no autoload)
    ScreenManager.gd     # Enseña/oculta vistas; cachea; preload core
    StoreOverlay.gd      # Tienda modal (no pestaña)
  src/systems/
    FishingSystem.gd
    EconomySystem.gd
    InventorySystem.gd
    UpgradeSystem.gd
    TimeSystem.gd
    SaveSystem.gd
    StoreSystem.gd       # Gemas/IAP/ads recompensados
    ContentIndex.gd      # Escaneo y registro de `data/**`
  src/autoload/
    App.gd               # Orquestación y temas
    Save.gd, Time.gd, Economy.gd, Inventory.gd, FishingRNG.gd
    Content.gd           # Autoload que envuelve a ContentIndex
  data/
    fish/                # *.tres (FishDef)
    zones/               # *.tres (ZoneDef)
    loot_tables/         # *.tres (por zona)
    equipment/           # *.tres (ToolDef: rod/reel/hook)
    upgrades/            # *.tres (UpgradeDef)
    store/               # *.tres (StoreItemDef)
    config/              # balance.json, economy.json
    localization/        # strings.csv
```

### Normas
- **UI NO en autoload**. Autoloads = servicios/sistemas sin UI.
- Cambio de pestañas **sin recargar**: `visible=true/false` + `process_mode` OFF.
- `Content` (autoload) llama a `ContentIndex.load_all()` en arranque.

### Contratos (señales/APIs)
- `BottomTabs.gd` → `signal tab_selected(tab: int)`; enum `{ FISHING, FRIDGE, MARKET, UPGRADES, MAP }`.
- `ScreenManager.gd` → `func show(tab:int)`, `func preload_core()`.
- `StoreOverlay.gd` → `signal purchase_requested(sku:String)`, `signal ad_reward_requested(placement:String)`.
- `StoreSystem.gd` → `signal purchase_completed(sku:String)`, `signal reward_granted(id:String)`, `signal store_error(msg:String)`.
- `Content.gd` → `signal content_loaded()`, getters fuertes (`all_fish()`, `all_zones()`, `equipment(type)`, `upgrade_defs()`...).

### Rendimiento
- Vistas ocultas con `PROCESS_MODE_DISABLED`.
- Cargar sprites como **atlases**; UI con `Theme` + `NinePatchRect`.
- Shader de agua **ligero** (offset UV, sin loops pesados).

### Back/confirmaciones (Android)
- Back cierra overlay si existe; si no, desde **Pescar** abre “Salir”.

---

## 7) Datos (100% data‑driven)
> **Regla**: Añadir contenido = crear `.tres` en `data/**` y assets en `art/**`. **Nada** de tocar scripts/escenas.

### Tipos `Resource`
- `class_name FishDef : Resource`
  - `id:String`, `name:String`, `rarity:int (0..3)`, `base_price:int`, `size_min:float`, `size_max:float`, `sprite:Texture2D`
- `class_name ZoneDef : Resource`
  - `id`, `name`, `price_multiplier:float`, `entries:Array[LootEntry]`
- `class_name LootEntry : Resource`
  - `fish:FishDef`, `weight:int`
- `class_name ToolDef : Resource` (caña/reel/anzuelo)
  - `id`, `tool_type:String` ("rod"|"reel"|"hook"), `name`, `tier:int`, `effects:Dictionary`
- `class_name UpgradeDef : Resource`
  - `id`, `name`, `max_level:int`, `cost_base:int`, `cost_mult:float`, `effects:Dictionary`
- `class_name StoreItemDef : Resource`
  - `sku:String`, `kind:String` ("gems_pack"|"booster"|"cosmetic"|"coins_pack"), `title:String`, `desc:String`, `price_eur:float`, `gems:int`, `grant:Dictionary`, `ad_placement:String?`
- **Runtime**: `class_name FishInstance : Resource` → `def:FishDef`, `size`, `weight`, `rarity_roll`, `value`, `timestamp`.

### Convenciones de ficheros
- `data/fish/fish_<id>.tres`
- `data/zones/zone_<id>.tres`
- `data/loot_tables/zone_<id>_table.tres`
- `data/equipment/<type>/<type>_<id>.tres`
- `data/upgrades/upgrade_<id>.tres`
- `data/store/<sku>.tres`

### ContentIndex
- Escanea `data/**` con `DirAccess` + `ResourceLoader.load`.
- Valida campos mínimos; **loggea** avisos en `user://logs/content.log`.
- Expone catálogos; vistas generan UI desde estos catálogos (sin hardcode).

---

## 8) Guardado (user://save.json)
```json
{
  "schema": 1,
  "coins": 120,
  "gems": 15,
  "zone": "harbor",
  "upgrades": {"rod":2, "fridge":3},
  "equipment": {"rod":"rod_basic", "reel":"reel_1", "hook":"hook_1"},
  "inventory": [{"id":"sardina","size":20.5,"val":12,"ts":1724567890}],
  "purchases": ["gems_120"],
  "owned_cosmetics": [],
  "ad_cooldowns": {"booster_x2":"2025-08-25T19:00:00Z"},
  "last_played": 1724567890,
  "settings": {"vibration": true, "sfx": 0.8, "music": 0.4}
}
```
- **Atómico**: escribir a tmp → `fsync` → renombrar; copia `.bak`.
- **Migración** por `schema` en `Save.gd`.

---

## 9) Minijuego de pesca (MVP)
- **Bite/QTE**: barra con zona verde; aguja con drift aleatorio.
- **Duración**: ~3 s. `qte_score` (0..100) modula tamaño/rareza.
- **Parámetros** por zona + upgrades: `green_width`, `drift_speed`.

---

## 10) Balance & Configuración
- `data/config/balance.json`: constantes de fórmulas (rarity_mult, size_factor, cost_mult, loot_weights por zona).
- `data/config/economy.json`: precios packs, recompensas base, caps de ads.
- **Localización**: `data/localization/strings.csv` (usar `tr()`).

---

## 11) Checklist MVP
- [ ] Core loop estable a 60 fps.
- [ ] 1 bioma (Orilla), 10 peces con sprites placeholder.
- [ ] 4 mejoras operativas.
- [ ] Inventario (capacidad) + Mercado (vender todo/selección).
- [ ] Guardado atómico + migración `schema`.
- [ ] **TopBar con Gemas [ + ]** + **Tienda overlay** (UI + `StoreSystem` stub).
- [ ] **Content** autoload cargando `data/**` (sin hardcode).
- [ ] Ads recompensados **stub** (sin SDK real aún) y límites.
- [ ] Audio mínimo (1 música loop, 6 SFX) + vibración opcional.

---

## 12) Expansión modular 100% data‑driven (sin tocar código)
**Añadir un pez**
1. Sprite en `art/fish/`.
2. `data/fish/fish_<id>.tres` (`FishDef`).
3. Añadir a `data/loot_tables/zone_<id>_table.tres` deseado.

**Añadir una zona**
1. `data/zones/zone_<id>.tres` (`ZoneDef`) con `price_multiplier`.
2. Tabla de loot `data/loot_tables/zone_<id>_table.tres`.
3. (Opcional) fondo en `art/env/`.

**Añadir herramienta (caña/carrete/anzuelo)**
1. `data/equipment/<type>/<type>_<id>.tres` (`ToolDef`).
2. Definir `effects`: `{"bite_chance":+0.05,"green_width":-0.02,...}`.

**Añadir mejora**
1. `data/upgrades/upgrade_<id>.tres` (`UpgradeDef`).

**Añadir item de tienda**
1. `data/store/<sku>.tres` (`StoreItemDef`): packs de gemas/monedas, boosters, cosméticos.

> Al arrancar, `Content` registra todo y las vistas generan listas desde estos catálogos. Orden/visibilidad por flags en los `.tres` (`is_visible`, `min_zone_id`, `tag`…), **no** por código.

---

## 13) Monetización no intrusiva (detallado)
- **Divisas**: Monedas (soft) y Gemas (hard) visibles en TopBar; `[ + ]` abre Tienda.
- **IAP**: Google Play Billing (stub). SKUs como `gems_120`, `gems_650`, `gems_1400`.
- **Boosters**: x2 valor 5 min, Auto‑fish 15 min → pagables con Gemas **o** **ad recompensado**. Caps: 10 ads/día, cool‑down 10 min.
- **Cosméticos**: solo visual; sin ventaja de juego.
- **Política UX**: sin intersticiales forzados; CTAs discretos en Mercado/Mejoras; confirmación en compras; botón **Restaurar**.

---

## 14) Telemetría, QA y Debug
- Logger en `user://logs/` (niveles DEBUG/INFO/WARN).
- Panel debug (`F1` en PC): monedas/gemas, PPM estimado, zona, seeds RNG.
- Simulador offline para validar rendimientos.

---

## 15) Criterio de calidad (gate)
> Si para añadir pez, zona, herramienta, mejora o ítem de tienda hay que tocar algo fuera de `res://data/**` y los assets en `res://art/**`, **el diseño se considera fallido**.

