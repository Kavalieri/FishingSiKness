# Tasklist Fase 1 — Prevalidación y QA

## 1. Pruebas de integración completas
- [ ] Crear test de ciclo completo: pesca → inventario → venta → mejora → guardado/carga.
- [ ] Ejecutar y documentar resultados de los tests de integración.

## 2. Validación visual y funcional
- [ ] Revisar UI en diferentes resoluciones (1080x1920, 720x1280, 1440x2560).
- [ ] Validar targets táctiles y contraste según accesibilidad.
- [x] Documentar integración de fondos visuales en zonas y menús (completado 25/08/2025)
- [x] Validar visualmente y ajustar si es necesario (completado 25/08/2025)

## 3. Audio mínimo
- [x] Añadir 1 música loop en `art/music/` (completado 25/08/2025)
- [x] Añadir 8 SFX en `art/sfx/` (completado 25/08/2025)
- [x] Integrar audio real en el sistema SFX y música de fondo (completado 25/08/2025)
- [x] Vincular audio con eventos clave (QTE, botones, captura, venta, mejora, error) (completado 25/08/2025)

## 4. Ads recompensados stub
- [x] Implementar stub de sistema de ads recompensados (`StoreSystem.gd`) (completado 25/08/2025)
- [x] Añadir señales y límites de uso (10 ads/día, cooldown 10 min) (completado 25/08/2025)
- [~] Documentar integración y pruebas — en progreso

## 5. Panel debug y telemetría
- [x] Implementar panel debug accesible con F1 en PC (completado 25/08/2025)
- [x] Añadir logger en `user://logs/` con niveles DEBUG/INFO/WARN (completado 25/08/2025)
- [x] Documentar uso y ejemplos de logs (completado 25/08/2025)

## 6. Validación modularidad
- [x] Añadir sprites reales para peces en `art/fish/` (completado 25/08/2025)
- [x] Integrar sprites en recursos `.tres` y loot tables (completado 25/08/2025)
- [x] Validación modularidad: añadir pez solo requiere asset y .tres, sin tocar código/escenas (completado 25/08/2025)
- [ ] Documentar el proceso y resultado.

## 7. Prueba final y checklist
- [x] Ejecutar el juego y validar el flujo completo (completado 25/08/2025)
- [x] Revisar checklist MVP y GDD (completado 25/08/2025)
- [x] Documentar conclusiones y próximos pasos (completado 25/08/2025)
