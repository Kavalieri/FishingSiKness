# Changelog

## [1.0.0-alpha](https://github.com/Kavalieri/FishingSiKness/compare/v0.1.0-alpha...v1.0.0-alpha) (2025-08-29)


### ⚠ BREAKING CHANGES

* Cambiamos a workflow de desarrollo continuo en main

### Bug Fixes

* actualizar manifest a 0.1.0 base para versioning correcto ([68fb5bf](https://github.com/Kavalieri/FishingSiKness/commit/68fb5bf1589948a8f5bc9a45cac0680dd4d3c3b5))
* corregir workflow release-please y configurar pre-releases alpha ([61c44fa](https://github.com/Kavalieri/FishingSiKness/commit/61c44fab9c99cc6e3cc2eef527081b3c8ae57c51))
* desactivar bump-minor-pre-major para mantener versionado 0.x.x-alpha ([3ac2831](https://github.com/Kavalieri/FishingSiKness/commit/3ac2831b00e40239b12bb454f2e98bda94fdd1ec))
* mover manifest file a la raíz para que release-please lo encuentre ([86ff11e](https://github.com/Kavalieri/FishingSiKness/commit/86ff11ec19ec42846b228fdd97d8a4800fa70b5b))


### Reverts

* eliminar BREAKING CHANGE para mantener versionado 0.1.x-alpha ([e9e779a](https://github.com/Kavalieri/FishingSiKness/commit/e9e779aa4faf4173000bfc40ce94334287ecf0ea))


### Continuous Integration

* implementar release-please y CI automation ([52586a6](https://github.com/Kavalieri/FishingSiKness/commit/52586a6864471736474df09fcfef4b556becd1a4))

## [v0.1.0-alpha] - Pre-Release - 2025-08-28

### 🎉 Nueva Funcionalidad
- **Sistema de guardado multi-slot**: Gestión completa de múltiples partidas simultáneas
- **TopBar mejorado**: Interfaz de usuario profesional con información de recursos en tiempo real
- **Sistema de pantalla de carga**: SplashScreen con transiciones suaves
- **Gestor de ventanas flotantes**: Sistema base para diálogos y menús emergentes
- **Sistema de debug avanzado**: Panel de depuración con logs detallados (F2)

### 🔧 Mejoras Técnicas
- **Arquitectura data-driven**: Todo el contenido se define en archivos `.tres` bajo `data/`
- **Sistema de señales mejorado**: Comunicación optimizada entre componentes UI
- **Auto-guardado**: Guardado automático al salir del juego
- **Gestión de slots**: Indicador visual del slot activo y valor del inventario
- **ContentIndex híbrido**: Carga optimizada para desarrollo vs. versión empaquetada

### 🧹 Limpieza y Optimización
- **Eliminación de archivos obsoletos**: Removidos archivos `.tscn` que causaban errores de exportación
- **Corrección de jerarquía de nodos**: Solucionados problemas de parent/child en scenes
- **Sistema RopePanel**: Preservado para uso futuro (movido a carpeta temporal)
- **Configuración .gitignore**: Actualizada para excluir builds y ejecutables

### 🐛 Correcciones de Errores
- **Errores de exportación**: Eliminados todos los errores de compilación/exportación
- **Parse errors**: Corregidos archivos `.tscn` con formato incorrecto
- **Referencias rotas**: Solucionadas rutas de recursos inexistentes
- **Nodos sin padre**: Corregida jerarquía en SaveManagerView y otros archivos

### 📁 Estructura del Proyecto
```
project/
├── src/autoload/          # Servicios globales y singletons
├── src/systems/           # Lógica de juego y economía
├── src/ui/               # Componentes de interfaz de usuario
├── scenes/core/          # Escenas principales (Main, Dialogs)
├── scenes/views/         # Pestañas y vistas principales
├── data/                 # Recursos de contenido (.tres)
├── art/                  # Assets visuales y de audio
└── tests/                # Tests unitarios e integración
```

### 🎮 Funcionalidades de Juego
- **Gestión de inventario**: Sistema de peces con valores calculados automáticamente
- **Sistema de zonas**: Fondos dinámicos por zona de pesca
- **Audio y SFX**: Integración de efectos de sonido y música de fondo
- **Configuración**: Panel de opciones con controles de audio y accesibilidad

### 🔄 Sistemas de Guardado
- **Slot único activo**: Gestión simplificada con persistencia de último slot usado
- **Validación de datos**: Verificación automática de integridad de guardados
- **Migración automática**: Sistema preparado para actualizaciones futuras
- **Ubicación unificada**: Todos los guardados en `user://savegame/`

### ⚡ Rendimiento
- **Carga optimizada**: ContentIndex con carga híbrida para mejor rendimiento
- **Señales eficientes**: Reducido acoplamiento entre sistemas
- **Auto-refresh UI**: Actualización automática de interfaces sin polling manual

### 📱 Compatibilidad
- **Resoluciones múltiples**: Interfaz adaptable a diferentes tamaños de pantalla
- **Modo zurdo**: Preparado para implementación de accesibilidad
- **Exportación limpia**: Compatible con Windows, Android y Web

### 🛠️ Herramientas de Desarrollo
- **Tasks automatizadas**: Configuración VS Code para builds y tests
- **Tests unitarios**: Framework GdUnit4 configurado
- **Logger integrado**: Sistema de logs con archivos en `user://logs/`
- **Debug panel**: Acceso rápido a información de desarrollo (F2)

---

**Notas importantes:**
- Esta es una versión pre-release destinada a validación de arquitectura
- El sistema RopePanel se preserva para uso futuro pero está desactivado
- Todos los errores de exportación han sido resueltos
