# Save — Fishing SiKness

## Descripción
Sistema de guardado atómico y migración por `schema`.
- Guarda en `user://save.json` y copia de seguridad `.bak`.
- Migración automática si cambia el schema.

## Contrato
- Funciones: `save(data: Dictionary)`, `load() -> Dictionary`, `migrate(data: Dictionary) -> Dictionary`

## Progreso
- Implementado y testeado con integración y fixture.

## Referencias
- GDD sección 8.
- Tasklist Fase 1, punto 5.
