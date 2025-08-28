# Copilot Instructions — Fishing-SiKness

## Big Picture & Architecture
- Proyecto Godot 4.4, 100% data-driven: todo contenido (peces, zonas, loot, upgrades, tienda) se define en `.tres` bajo `data/` y assets en `art/`.
- Estructura modular: `src/autoload/` (servicios/singletons), `src/systems/` (lógica de juego), `src/ui/` (UI), `scenes/core/` (Main, Dialogs), `scenes/views/` (pestañas principales).
- El GDD oficial está en `docs/GDD/GDD_0.1.0.md` y define reglas, flujos y contratos entre sistemas.
- Fondos visuales por zona se asignan en los recursos `.tres` de cada zona.

## Developer Workflows
- Builds y tests se gestionan vía Godot CLI (`godot` en PATH).
- Tests unitarios/integración en `project/tests/` (usar GdUnit4). Ejecutar con `godot --headless --test project/tests/unit/` y `project/tests/integration/`.
- No modificar código/escenas para añadir contenido: solo crear nuevos `.tres` y assets.
- Validación visual y QA en varias resoluciones; accesibilidad y modo zurdo en UI.
- Logger y panel debug accesibles (F2 en PC, logs en `user://logs/`).

## Naming Conventions
- Variables: snake_case
- Functions: snake_case
- Constants: UPPER_SNAKE_CASE
- Signals: snake_case
- Classes: PascalCase

## Project-Specific Conventions
- No usar `class_name` en scripts autoload (conflicto con singletons).
- Usar tipado estático y el style guide oficial de Godot.
- Los assets de producción van en `art/`; los de test en `project/tests/fixtures/`.
- Los fondos de zona se referencian en la propiedad `background` de cada `.tres` de zona.
- Los tests de pipeline/exportación van en `build/tests/`.
- Documentación y tareas en `docs/` (`tasklist/`, `summary/`, `GDD/`).

## Integration Points & Patterns
- Comunicación entre sistemas vía señales (ej: `tab_selected`, `content_loaded`, `ad_reward_requested`).
- El sistema de guardado es atómico y migrable (`Save.gd`).
- Ads recompensados y monetización implementados como stub en `StoreSystem.gd`.
- Audio y vibración integrados en eventos clave vía autoload `SFX.gd`.

## Key Files & Directories
- `src/autoload/`: singletons y servicios globales.
- `src/systems/`: lógica de juego y economía.
- `src/ui/`: componentes UI y panel debug.
- `data/`: recursos `.tres` para contenido del juego.
- `art/`: sprites, fondos, audio.
- `project/tests/`: tests unitarios/integración.
- `.vscode/tasks.json`: tareas automáticas para builds/tests.

---
Para agentes IA: sigue la arquitectura data-driven, respeta las convenciones y consulta siempre el GDD y la documentación en `docs/` antes de proponer cambios estructurales. Si detectas patrones no documentados, actualiza este archivo y notifica al equipo.
