# Tasklist Fase 1 — Fishing SiKness (MVP)

## 1. Estructura y base del proyecto
- [x] Crear estructura de carpetas y archivos según el GDD (scenes, src, data, autoload, art, tests)
- [x] Configurar autoloads básicos (`App.gd`, `Content.gd`, `Save.gd`, etc.)
- [x] Implementar `ContentIndex.gd` para escaneo y registro de recursos data-driven

## 2. Core loop y pantallas principales
- [x] Crear escena principal `Main.tscn` con TopBar, BottomTabs y ScreenManager
- [x] Implementar vistas: `Fishing.tscn`, `Fridge.tscn`, `Market.tscn`, `Upgrades.tscn`, `Map.tscn`
- [x] Programar navegación por pestañas y overlays (Tienda, Ajustes)

## 3. Sistemas y lógica
- [x] Desarrollar sistemas: `FishingSystem.gd`, `EconomySystem.gd`, `InventorySystem.gd`, `UpgradeSystem.gd`, `StoreSystem.gd`
- [x] Implementar el minijuego de pesca (QTE barra/aguja)
- [x] Integrar inventario y mercado (vender capturas, upgrades)

## 4. Data-driven y recursos
- [x] Crear recursos `.tres` para peces, zonas, loot tables, herramientas, upgrades y tienda
- [x] Implementar validación y carga automática de contenido desde `data/**`

## 5. Guardado y migración
- [x] Programar sistema de guardado atómico en `user://save.json` con migración por `schema` (completado 25/08/2025)

## 6. UI/UX y accesibilidad
- [x] Diseñar UI responsive y accesible (TopBar, BottomTabs, botones principales) (completado 25/08/2025)
- [x] Añadir vibración y SFX básicos (completado 25/08/2025)

## 7. Tests y calidad
- [x] Crear estructura de tests en `project/tests/` (unit, integration, fixtures) (completado 25/08/2025)
- [x] Añadir tests para cada sistema y vista implementada — tests de TopBar y BottomTabs creados 25/08/2025
- [x] Configurar tareas automáticas para ejecutar tests desde VS Code (completado 25/08/2025)

## 8. Documentación y checklist
- [x] Documentar cada sistema y escena en `docs/summary/` (completado 25/08/2025)
- [x] Mantener actualizada la checklist MVP y el GDD (completado 25/08/2025)
