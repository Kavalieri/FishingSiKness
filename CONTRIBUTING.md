# 🤝 Guía de Contribuciones - FishingSiKness

¡Gracias por tu interés en contribuir a FishingSiKness! Este proyecto mantiene un enfoque experimental único de desarrollo asistido por IA, pero valoramos mucho las contribuciones de la comunidad.

## 🌟 Filosofía del Proyecto

**FishingSiKness es un experimento de desarrollo 100% asistido por IA**. Aunque las contribuciones humanas son bienvenidas, buscamos mantener esta naturaleza experimental y la coherencia arquitectónica establecida por los agentes IA.

---

## 🚀 Formas de Contribuir

### 🐛 **Reportar Bugs**

¿Encontraste un error? ¡Ayúdanos a mejorarlo!

**Antes de reportar:**
- ✅ Verifica que no exista un issue similar
- ✅ Asegúrate de usar la versión más reciente
- ✅ Reproduce el error en un entorno limpio

**Template de Bug Report:**
```markdown
## 🐛 Descripción del Bug
[Descripción clara y concisa del problema]

## 🔄 Pasos para Reproducir
1. Ir a '...'
2. Hacer clic en '...'
3. Ver error

## ✅ Comportamiento Esperado
[Qué debería ocurrir]

## 📱 Entorno
- OS: [Windows/Android/Web]
- Versión del juego: [v0.1.0-alpha]
- Dispositivo: [Si es móvil]

## 📋 Información Adicional
- Screenshots
- Logs (si disponibles)
- Pasos adicionales intentados
```

### 💡 **Sugerir Características**

¡Las ideas son siempre bienvenidas!

**Template de Feature Request:**
```markdown
## 🎯 Descripción de la Característica
[Descripción clara de la funcionalidad propuesta]

## 💭 Motivación
[¿Por qué sería útil? ¿Qué problema resuelve?]

## 🔧 Solución Propuesta
[Cómo imaginas que funcionaría]

## 🎨 Alternativas Consideradas
[Otras formas de resolver el mismo problema]

## 📊 Contexto Adicional
[Screenshots, mockups, referencias, etc.]
```

### 🔧 **Contribuciones de Código**

#### **Tipos de Contribuciones Aceptadas**

✅ **Correcciones de bugs críticos**
✅ **Mejoras de rendimiento**
✅ **Correcciones de typos en documentación**
✅ **Mejoras en testing**
✅ **Optimizaciones de código existente**

⚠️ **Requieren Discusión Previa**
- Nuevas características importantes
- Cambios en la arquitectura principal
- Modificaciones en el sistema de guardado
- Alteraciones en la UI principal

❌ **No Aceptadas**
- Cambios que rompan la arquitectura IA-driven
- Reescrituras completas de sistemas
- Cambios de estilo que no sigan las convenciones existentes

#### **Proceso de Pull Request**

1. **🍴 Fork del repositorio**
   ```bash
   git clone https://github.com/tu-usuario/FishingSiKness.git
   cd FishingSiKness
   ```

2. **🌿 Crear rama de trabajo**
   ```bash
   git checkout -b fix/descripcion-del-fix
   # o
   git checkout -b feature/descripcion-feature
   ```

3. **💻 Realizar cambios**
   - Sigue las convenciones de código existentes
   - Añade tests si es aplicable
   - Actualiza documentación si es necesario

4. **🧪 Testing**
   ```bash
   # Tests unitarios
   godot --headless --test project/tests/unit/

   # Tests de integración
   godot --headless --test project/tests/integration/

   # Build test
   godot --headless --export-debug "Windows Debug" build/test.exe
   ```

5. **📝 Commit**
   ```bash
   git add .
   git commit -m "🐛 Fix: descripción clara del cambio

   - Detalle específico 1
   - Detalle específico 2
   - Cierra #numero-de-issue"
   ```

6. **📤 Push y PR**
   ```bash
   git push origin tu-rama
   ```
   - Crear PR en GitHub con descripción detallada
   - Usar el template de PR proporcionado

---

## 📋 Estándares y Convenciones

### 🎯 **Estilo de Código**

#### **GDScript**
```gdscript
# ✅ Correcto
class_name PlayerInventory
extends Node

signal item_added(item: Item)
signal inventory_full()

const MAX_SLOTS: int = 20
var current_items: Array[Item] = []

func add_item(item: Item) -> bool:
    if current_items.size() >= MAX_SLOTS:
        inventory_full.emit()
        return false

    current_items.append(item)
    item_added.emit(item)
    return true

# ❌ Incorrecto
func addItem(item):  # CamelCase incorrecto, sin tipos
    currentItems.push_back(item)  # push_back en lugar de append
```

#### **Naming Conventions**
- **Variables**: `snake_case`
- **Functions**: `snake_case`
- **Constants**: `UPPER_SNAKE_CASE`
- **Signals**: `snake_case`
- **Classes**: `PascalCase`

#### **Comentarios y Documentación**
```gdscript
## Gestiona el inventario del jugador con slots limitados
##
## Proporciona funcionalidad para añadir, remover y organizar items
## con validación automática de capacidad y emisión de señales.
class_name PlayerInventory
extends Node

## Añade un item al inventario si hay espacio disponible
##
## @param item El item a añadir al inventario
## @return true si se añadió exitosamente, false si no hay espacio
func add_item(item: Item) -> bool:
    # Implementación...
```

### 🗂️ **Estructura de Archivos**

```
project/
├── src/
│   ├── autoload/          # Singletons y servicios globales
│   ├── systems/           # Lógica de juego
│   ├── ui/               # Componentes de interfaz
│   └── views/            # Vistas principales
├── scenes/               # Archivos .tscn
├── data/                # Recursos .tres (contenido)
└── art/                 # Assets visuales y audio
```

### 📝 **Commits**

Utilizamos [Conventional Commits](https://www.conventionalcommits.org/) con emojis:

```
🎯 feat: nueva característica
🐛 fix: corrección de bug
📝 docs: cambios en documentación
🎨 style: cambios de formato/estilo
♻️ refactor: refactoring de código
🧪 test: añadir o corregir tests
🔧 chore: tareas de mantenimiento
```

**Ejemplos:**
```
🐛 fix: corregir cálculo de valor de inventario en SaveManagerView

- El valor total no se actualizaba correctamente al cargar slots
- Añadida validación para items nulos
- Cierra #23

🎯 feat: añadir sistema de logros básico

- Nueva clase Achievement con tipos y recompensas
- Integration con sistema de guardado existente
- UI placeholder para futura implementación
```

---

## 🧪 Testing

### **Ejecutar Tests**
```bash
# Todos los tests
godot --headless --test project/tests/

# Solo unitarios
godot --headless --test project/tests/unit/

# Test específico
godot --headless --test project/tests/unit/test_save_system.gd
```

### **Escribir Tests**
```gdscript
# test_inventory.gd
extends GdUnitTestSuite

func test_add_item_success():
    # Arrange
    var inventory = PlayerInventory.new()
    var item = Item.new()
    item.name = "Test Fish"

    # Act
    var result = inventory.add_item(item)

    # Assert
    assert_true(result)
    assert_int(inventory.get_item_count()).is_equal(1)

func test_inventory_full_signal():
    # Arrange
    var inventory = PlayerInventory.new()
    var signal_monitor = monitor_signals(inventory)

    # Fill inventory to max
    for i in range(inventory.MAX_SLOTS):
        inventory.add_item(Item.new())

    # Act
    var result = inventory.add_item(Item.new())

    # Assert
    assert_false(result)
    assert_signal(inventory).is_emitted("inventory_full")
```

---

## 🤖 Desarrollo con IA

### **Principios IA-Driven**

1. **Mantener Coherencia Arquitectónica**: Los cambios deben seguir los patrones establecidos por IA
2. **Data-Driven Design**: Preferir configuración en archivos `.tres` sobre código hardcodeado
3. **Señales sobre Referencias Directas**: Usar el sistema de señales para comunicación entre componentes
4. **Separación de Responsabilidades**: Cada script debe tener un propósito claro y específico

### **Consultar con IA**

Para cambios importantes, considera usar herramientas IA para:
- **Code Review**: Verificar que el código sigue las convenciones
- **Testing Strategy**: Generar ideas para casos de test
- **Documentation**: Mejorar comentarios y documentación
- **Optimization**: Identificar posibles mejoras de rendimiento

---

## 📞 Contacto y Comunidad

### **Canales de Comunicación**

- 🐛 **Issues**: Reportes de bugs y solicitudes de características
- 💬 **Discussions**: Preguntas generales y discusión de ideas
- 📧 **Email**: [kavateuve@gmail.com](mailto:kavateuve@gmail.com) (solo temas importantes)

### **Código de Conducta**

Este proyecto sigue el [Contributor Covenant](https://www.contributor-covenant.org/). En resumen:

- 🤝 **Ser respetuoso** con todos los participantes
- 💬 **Comunicación constructiva** en issues y PRs
- 🎯 **Foco en el proyecto** y sus objetivos
- 🌍 **Inclusividad** y bienvenida a todos los niveles de experiencia

### **Reconocimientos**

Los contribuidores son reconocidos en:
- 📋 **CHANGELOG.md** - Menciones en releases
- 🏆 **README.md** - Lista de contribuidores
- 💬 **Release Notes** - Créditos específicos por características

---

## 📈 Roadmap y Prioridades

### **v0.2.0 - Core Gameplay** (Próximo)
- Sistema de pesca funcional
- Mecánicas de progresión básicas
- Balancing inicial

### **v0.3.0 - Features Avanzadas**
- Sistema de logros
- Múltiples zonas de pesca
- Mejoras visuales

### **Áreas que Necesitan Ayuda**
- 🧪 **Testing**: Cobertura de tests
- 📱 **Mobile UX**: Optimización para móviles
- 🌐 **Localización**: Soporte multi-idioma
- 🎨 **Arte**: Sprites y animaciones adicionales
- 🔊 **Audio**: Efectos de sonido y música

---

<div align="center">

**¡Gracias por contribuir a este experimento único de desarrollo con IA! 🤖🎣**

*Juntos estamos creando el futuro del desarrollo de videojuegos*

</div>
