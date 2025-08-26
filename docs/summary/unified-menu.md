# Sistema de Menú Unificado - Fishing SiKness

## 📋 **Resumen**
Sistema de menú unificado que reemplaza la fragmentación entre `SettingsMenu.gd` y `PauseMenu.gd`, proporcionando una experiencia de usuario coherente y eliminando duplicaciones de instancias.

## 🎯 **Problema Resuelto**
- **Múltiples instancias**: Los menús se abrían varias veces sin control de instancia única
- **UX inconsistente**: Diferentes menús en splash screen vs juego principal
- **Código duplicado**: Funcionalidades repetidas entre SettingsMenu y PauseMenu
- **Gestión compleja**: Múltiples sistemas de menú independientes

## ⚡ **Solución Implementada**

### **UnifiedMenu.gd**
- **Ruta**: `src/views/UnifiedMenu.gd`
- **Clase**: `UnifiedMenu extends Control`
- **Tipos de menú**:
  - `MenuType.PAUSE`: Menú de pausa del juego principal
  - `MenuType.SPLASH_OPTIONS`: Menú de opciones completo desde splash screen

### **Características Clave**
- **Control de instancia única**: Previene múltiples menús simultáneos
- **Centrado dinámico**: Se adapta automáticamente a diferentes tamaños de pantalla
- **Contenido contextual**: Diferente funcionalidad según el contexto de uso
- **Gestión unificada**: Todas las opciones en un solo sistema

## 🛠 **Funcionalidades**

### **Menú de Pausa (PAUSE)**
- **Continuar**: Cierra menú y vuelve al juego
- **Configuraciones**: Cambia a modo opciones completas
- **Gestor de Partidas**: Acceso al sistema de guardado
- **Guardar y Salir**: Guarda automáticamente y cierra el juego

### **Menú de Opciones (SPLASH_OPTIONS)**
- **Audio**: Controles de volumen (General, Música, Efectos), toggle vibración
- **Jugabilidad**: Modo zurdo, animaciones reducidas
- **Datos de Juego**: Gestor de partidas, información de guardado
- **Información**: Versión del juego, estadísticas del jugador, copyright

### **Controles de Interfaz**
- **Scroll**: Opciones en scroll container para adaptabilidad
- **Sliders**: Controles de volumen con feedback visual en porcentaje
- **Checkboxes**: Configuraciones booleanas con estado persistente
- **Botones**: Acciones principales con iconos descriptivos

## 🔄 **Integración del Sistema**

### **SplashScreen.gd**
```gdscript
func _on_options_pressed():
    var UnifiedMenuClass = preload("res://src/views/UnifiedMenu.gd")
    var options_menu = UnifiedMenuClass.create_options_menu()
    # Conectar señales y agregar al árbol
```

### **ScreenManager.gd**
```gdscript
func show_pause_menu():
    var UnifiedMenuClass = preload("res://src/views/UnifiedMenu.gd")
    pause_menu = UnifiedMenuClass.create_pause_menu()
    # Gestión unificada de overlays
```

## 📊 **Beneficios Conseguidos**

### **UX Mejorado**
- ✅ **Coherencia visual**: Mismo diseño en splash y juego principal
- ✅ **Sin duplicaciones**: Una sola instancia por vez garantizada
- ✅ **Centrado perfecto**: Adaptación automática a resoluciones
- ✅ **Navegación intuitiva**: Flujo lógico entre diferentes contextos

### **Código Optimizado**
- ✅ **DRY Principle**: Eliminación de código duplicado
- ✅ **Single Responsibility**: Un sistema, una responsabilidad
- ✅ **Mantenibilidad**: Cambios centralizados en un solo archivo
- ✅ **Extensibilidad**: Fácil agregar nuevos tipos de menú

### **Gestión Simplificada**
- ✅ **Control de instancia**: `static var current_instance` previene múltiples menús
- ✅ **Limpieza automática**: Liberación correcta de recursos
- ✅ **Señales unificadas**: Sistema de comunicación consistente

## 🔧 **Detalles Técnicos**

### **Control de Instancia Única**
```gdscript
static var current_instance: UnifiedMenu = null

func _init(type: MenuType = MenuType.PAUSE):
    if current_instance:
        current_instance.queue_free()
    current_instance = self
```

### **Centrado Dinámico**
```gdscript
func _center_panel(panel: PanelContainer):
    var viewport_size = get_viewport().get_visible_rect().size
    var panel_size = Vector2(
        viewport_size.x * (0.6 if menu_type == MenuType.SPLASH_OPTIONS else 0.5),
        viewport_size.y * 0.7
    )
    panel.position = (viewport_size - panel_size) / 2
```

### **Métodos Estáticos de Creación**
```gdscript
static func create_pause_menu() -> UnifiedMenu:
    return UnifiedMenu.new(MenuType.PAUSE)

static func create_options_menu() -> UnifiedMenu:
    return UnifiedMenu.new(MenuType.SPLASH_OPTIONS)
```

## 🎨 **Integración con VersionInfo**

### **Información Dinámica**
- **Título**: Desde `VersionInfo.get_game_title()`
- **Versión**: Desde `VersionInfo.get_version()`
- **Compañía**: Desde `VersionInfo.get_company()`
- **Estadísticas**: Datos en tiempo real desde `Save` (monedas, gemas, nivel)

### **Copyright Contextual**
Mostrado únicamente en el menú de opciones desde splash screen para información completa del proyecto.

## 📈 **Resultado Final**

### **Antes**:
- Múltiples sistemas de menú inconsistentes
- Instancias duplicadas sin control
- UX fragmentada entre splash y juego
- Código duplicado difícil de mantener

### **Después**:
- ✅ Sistema unificado coherente
- ✅ Control absoluto de instancias
- ✅ UX consistente y centrada
- ✅ Código limpio y mantenible

---

## 🚀 **Próximos Pasos**
- **Temas visuales**: Posible personalización de estilos
- **Animaciones**: Transiciones suaves entre estados del menú
- **Accesibilidad**: Mejoras adicionales para diferentes dispositivos
- **Persistencia**: Recordar preferencias de tamaño de menú

---
*Documentación actualizada: 2025-01-02*
*Sistema implementado en: v0.1.0*
