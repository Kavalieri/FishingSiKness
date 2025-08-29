# Changelog

## [0.3.0-alpha](https://github.com/Kavalieri/FishingSiKness/compare/v0.2.1-alpha...v0.3.0-alpha) (2025-08-29)


### Features

* añadir adjunto automático de builds a releases ([72f622a](https://github.com/Kavalieri/FishingSiKness/commit/72f622a33a60ccadef81885cc028725b24eab59a))


### Bug Fixes

* completar merge con release automática ([87ce743](https://github.com/Kavalieri/FishingSiKness/commit/87ce74336826e7eeed4948def5cb3079aedbbbec))
* reconstruir workflow release-please corrompido ([d383efd](https://github.com/Kavalieri/FishingSiKness/commit/d383efd34d7a0dadfb0c833c80b6cecace934378))
* restaurar version.txt para release-please y mantener sync con version.json ([9a96fd3](https://github.com/Kavalieri/FishingSiKness/commit/9a96fd3038b9b327511c1879771657b32aa9ccae))
* restaurar workflow release-please funcional ([e7bda53](https://github.com/Kavalieri/FishingSiKness/commit/e7bda534c75977504e1d5d275797f3f6607777a4))
* unificar sistema de versiones en build/version.json ([de5960b](https://github.com/Kavalieri/FishingSiKness/commit/de5960b57d73107c99a89bf6f2429542e54f6b53))

## [0.2.1-alpha](https://github.com/Kavalieri/FishingSiKness/compare/v0.2.0-alpha...v0.2.1-alpha) (2025-08-29)


### Features

* adaptar sistema de build completo para FishingSiKness ([6024402](https://github.com/Kavalieri/FishingSiKness/commit/6024402d8ed6f2ed2c842562e9ea0cd055ba072c))
* añadir cabecera personalizada y forzado de prerelease a releases ([7a6fbae](https://github.com/Kavalieri/FishingSiKness/commit/7a6fbaee9ef6dd7870229f17499c20cebd875ab0))
* complete build system overhaul with web deployment ([b1b50dc](https://github.com/Kavalieri/FishingSiKness/commit/b1b50dc39d616a3b11d8150f9c95c73873a8be0b))


### Bug Fixes

* aplicar estrategia always-bump-patch para desarrollo alpha gradual ([1094379](https://github.com/Kavalieri/FishingSiKness/commit/109437989a9b8b88840c7df1d6616c1cd2b26131))
* corregir nombre de configuración versioning para release-please v4 ([82d23e5](https://github.com/Kavalieri/FishingSiKness/commit/82d23e5382a39157cf2b75c7be9581eba7afbbc9))
* establecer baseline correcta para desarrollo alpha ([cd1d735](https://github.com/Kavalieri/FishingSiKness/commit/cd1d735130ef5423f273449e3ec4dbacc7440fe6))

## [0.2.0-alpha](https://github.com/Kavalieri/FishingSiKness/compare/v0.1.0-alpha...v0.2.0-alpha) (2025-08-29)


### Features

* implementar sistema de releases automáticas con release-please ([f33ab39](https://github.com/Kavalieri/FishingSiKness/commit/f33ab39465cdab3159dc35c483452d9ff1da1faa))

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
