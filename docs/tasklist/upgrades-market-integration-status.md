# Estado Integración Upgrades y Market - Septiembre 26, 2025

## ✅ Completado

### 1. UpgradesScreen: setup_screen() se llama automáticamente
- **Implementado**: `CentralHost._setup_upgrades_screen()` → `screen.setup_screen()`
- **Ubicación**: `project/src/ui_new/CentralHost.gd:141-145`
- **Flujo**: Al cambiar a pestaña "upgrades" → CentralHost carga screen → invoca setup automático

### 2. UpgradesPanel: mostrar efectos actuales y siguientes
- **Implementado**: `_create_upgrade_card()` muestra efectos via `UpgradeSystem.get_upgrade_info()`
- **Ubicación**: `project/src/ui_new/components/UpgradesPanel.gd:126-169`
- **Características**:
  - 🔹 Nivel actual: X/MAX
  - 🔹 Efecto actual: x2.5 / 15%
  - 🔸 Próximo efecto: x3.0 / 20%
  - ✨ ¡Nivel máximo alcanzado! (cuando aplique)
  - Botón deshabilitado para upgrades en nivel máximo (verde atenuado)

### 3. Card.gd: sobrecarga de setup_card()
- **Implementado**: Soporte tanto para `Dictionary` como parámetros separados
- **Ubicación**: `project/src/ui_new/components/Card.gd:27-44`
- **Compatibilidad**: Mantiene API existente y añade flexibilidad

### 4. UpgradeSystem: efectos y migración legacy
- **Implementado**:
  - `PRIMARY_EFFECT_KEY_BY_ID` para mapeo correcto de efectos
  - `_migrate_legacy_upgrades()` para bait_quality→bait, fishing_speed→reel
  - Aplicación automática de efectos al cargar partida
- **Ubicación**: `project/src/systems/UpgradeSystem.gd`
- **Migración**: Idempotente, preserva max level, no duplica

### 5. Flujo de compra y persistencia
- **Implementado**: `UpgradesScreen._on_upgrade_purchased()` → `UpgradeSystem.purchase_upgrade()` → `setup_screen()` refresh
- **Persistencia**: Via `Save` autoload, aplicación de efectos diferida en `_ready()`

### 6. Market-Inventario: señales en tiempo real
- **Implementado**: `MarketScreen` conectado a `UnifiedInventorySystem.inventory_updated`
- **Ubicación**: `project/src/ui_new/screens/MarketScreen.gd:90-124`
- **Comportamiento**: Al vender → inventario cambia → market se refresca automáticamente

### 7. Compilación exitosa
- **Verificado**: `godot --headless --check-only` sin errores
- **Linter**: Errores corregidos (max-line-length, no-elif-return, class-definitions-order)

## ⏳ Pendiente

### 8. Smoke test completo
- **Estado**: Juego ejecutándose, esperando validación manual
- **Casos**:
  - Abrir pestaña Upgrades → ver cartas con efectos
  - Comprar upgrade → monedas bajan, nivel sube, persiste tras reinicio
  - Market → vender pez → lista se actualiza + monedas TopBar

### 9. Tests automatizados
- **Requerido**: Tests GdUnit4 para migración legacy upgrades
- **Cobertura**:
  - Migración idempotente (bait_quality→bait, fishing_speed→reel)
  - Aplicación correcta de efectos
  - Persistencia cross-session

### 10. Estados límite y UX polish
- **Pendiente**:
  - Mostrar "Sin dinero suficiente" cuando can_afford = false
  - Tooltips para efectos complejos
  - Animaciones de compra exitosa

### 11. Limpieza legacy references
- **Pendiente**:
  - Buscar y aislar referencias a `UpgradesView.gd` legacy
  - Verificar que no se cargan sistemas antiguos paralelos

## 🎯 Criterios de Aceptación

1. **Funcionalidad Básica**:
   - [✅] Pestaña upgrades abre y muestra cartas
   - [⏳] Comprar upgrade descuenta dinero y sube nivel
   - [⏳] Reiniciar preserva progreso y aplica efectos

2. **UX/UI**:
   - [✅] Efectos actuales/siguientes visibles en cartas
   - [✅] Estados deshabilitados para upgrades máximos/insuficiente dinero
   - [⏳] Actualizaciones UI en tiempo real (monedas TopBar)

3. **Integración Sistema**:
   - [✅] UpgradeSystem como autoridad única
   - [✅] Migración legacy sin pérdida de progreso
   - [✅] Market-Inventario señales conectadas

4. **Calidad Código**:
   - [✅] Compilación limpia
   - [⏳] Tests para casos edge
   - [✅] Logging apropiado para debug

## 🚀 Próximos Pasos

1. **Inmediato**: Validar smoke test manual (compra upgrade + persistencia)
2. **Corto plazo**: Escribir tests automatizados migración legacy
3. **Medio plazo**: Polish UX (tooltips, animaciones, estados error)

---

**Commit sugerido**: `feat: integrar upgrade system con nueva UI y migración legacy`

**Notas técnicas**:
- Effect key mapping resuelve mismatch entre UpgradeDef.get_effect_at_level() y system logic
- Card.gd sobrecarga mantiene compatibilidad con componentes existentes (Map, Market, Store)
- Migración legacy idempotente permite updates sin resetear progreso de jugadores existentes
