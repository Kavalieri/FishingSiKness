# Changelog

## [v0.1.0-alpha] - Pre-Release - 2025-08-28

### 🎉 Nueva Funcionalidad
- **Sistema de guardado multi-slot**: Gestión completa de múltiples partidas simultáneas
- **TopBar mejorado**: Interfaz de usuario profesional con información de recursos en tiempo real
- **Sistema de pantalla de carga**: SplashScreen con transiciones suaves
- **Gestor de ventanas flotantes**: Sistema base para diálogos y menús emergentes
- **Sistema de debug avanzado**: Panel de depuración con logs detallados (F1)

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
- **Debug panel**: Acceso rápido a información de desarrollo (F1)

---

**Notas importantes:**
- Esta es una versión pre-release destinada a validación de arquitectura
- El sistema RopePanel se preserva para uso futuro pero está desactivado
- Todos los errores de exportación han sido resueltos
- El proyecto sigue el GDD oficial en `docs/GDD/GDD_0.1.0.md`
