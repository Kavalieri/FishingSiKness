# ContentIndex — Fishing SiKness

## Descripción
Sistema encargado de escanear y registrar todos los recursos data-driven en `data/**`.
- Valida campos mínimos y loguea avisos en `user://logs/content.log`.
- Expone catálogos para que las vistas generen UI desde estos datos.

## Contrato
- Función principal: `load_all()`
- Catálogos: `fish`, `zones`, `loot_tables`, `equipment`, `upgrades`, `store`

## Progreso
- Implementado y testeado con recursos de ejemplo.
- Integrado en el arranque vía autoload `Content`.

## Referencias
- GDD sección 7.
- Tasklist Fase 1, punto 4.
