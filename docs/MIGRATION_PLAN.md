## PLAN DE MIGRACIÓN: Sistema de Ventanas Flotantes

### 🎯 OBJETIVO
Crear un sistema de ventanas flotantes completamente nuevo y modular sin romper el sistema actual.

### 🏗️ ARQUITECTURA FINAL
```
Sistema 1 (Pestañas Principales) - INTACTO
├── ScreenManager
├── BottomTabs (Pescar, Mercado, Mejoras, Mapa, Prestigio)
└── TopBar (básico)

Sistema 2 (Ventanas Flotantes) - NUEVO
├── FloatingWindowManager (Singleton)
├── BaseFloatingWindow (Clase base)
└── Ventanas específicas:
    ├── StoreWindow
    ├── CaptureCard
    ├── MilestonesWindow
    ├── PauseWindow
    ├── SettingsWindow
    ├── SaveManagerWindow
    └── InventoryWindow
```

### 🚀 ESTRATEGIA DE MIGRACIÓN

#### FASE 1: Sistema Paralelo (ACTUAL)
- [✅] FloatingWindowManager creado como singleton
- [✅] BaseFloatingWindow como clase base
- [✅] StoreWindow y CaptureCard como ejemplos
- [❌] ScreenManager sigue usando sistema anterior (FUNCIONAL)

#### FASE 2: Integración Gradual
- [ ] Crear botón de prueba para StoreWindow
- [ ] Probar nuevo sistema en paralelo
- [ ] Crear todas las ventanas específicas
- [ ] Validar UX y fondos consistentes

#### FASE 3: Reemplazo Gradual
- [ ] Reemplazar show_store() con nuevo sistema
- [ ] Reemplazar show_milestones_panel() con nuevo sistema
- [ ] Reemplazar show_pause_menu() con nuevo sistema
- [ ] Mantener fallbacks por si falla

#### FASE 4: Limpieza Final
- [ ] Eliminar clases antiguas no utilizadas
- [ ] Documentar nuevo sistema
- [ ] Commit final

### 🔧 RESPONSABILIDADES CLARAS

#### FloatingWindowManager
- Gestión de stack de ventanas
- Animaciones entrada/salida
- Control de modal/no-modal
- Manejo de ESC y click en fondo
- Z-index automático

#### BaseFloatingWindow
- Estructura UI estándar por tipo
- Fondos automáticos (BackgroundManager)
- Botón cerrar estándar
- Responsividad

#### Ventanas Específicas
- Solo contenido y lógica propia
- Herencia de BaseFloatingWindow
- Sin conocimiento de otros sistemas

#### ScreenManager
- Mantiene sistema de pestañas
- Gradualmente adopta FloatingWindowManager
- NO toca lógica de ventanas individuales

### ⚠️ PRINCIPIOS CLAVE
1. **NO ROMPER** funcionalidad existente
2. **AISLAMIENTO** total entre Sistema 1 y Sistema 2
3. **MODULARIDAD** - cada ventana es independiente
4. **FALLBACKS** - sistema anterior como respaldo
5. **TESTING** incremental en cada paso
