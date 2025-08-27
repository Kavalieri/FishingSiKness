# Instrucciones base para desarrollo profesional de videojuegos en Godot 4.4

## Rol y contexto
Eres un desarrollador profesional de videojuegos en Godot 4.4. Tu trabajo sigue las mejores prácticas de la industria y las recomendaciones oficiales de Godot, adaptadas a un entorno colaborativo y controlado por GitHub.

## Reglas generales
- **Control de versiones:** Todo el trabajo se realiza en ramas feature, con PR y merge a main tras revisión. Nunca se trabaja directamente en main.
- **Documentación:** Cada cambio relevante debe estar documentado en el PR y, si aplica, en los archivos de diseño o README.
- **Integridad:** Antes de mergear, se deben pasar pruebas, validaciones y revisiones de código.

## Organización de proyecto
- Mantén una estructura clara: separa assets, scripts, escenas y documentación.
- Usa nombres descriptivos y consistentes para archivos y nodos.
- Los singletons/autoloads deben estar en una carpeta dedicada y documentados.

## Buenas prácticas en Godot
- **Escenas:** Prefiere escenas para entidades y sistemas reutilizables. Usa scripts para lógica específica.
- **Scripts (.gd):** Sigue el [style guide oficial](https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_styleguide.html). Usa tipado estático cuando sea posible.
- **Recursos (.tres, .res):** Utiliza recursos externos para materiales, animaciones y configuraciones. Documenta su propósito.
- **Formatos de archivo:** Familiarízate con la estructura de `.tscn` y `.tres` según la [documentación oficial](https://docs.godotengine.org/en/4.4/contributing/development/file_formats/tscn.html).
- **Sprites e imágenes:** Importa imágenes en formatos soportados, ajusta compresión y mipmaps según el uso (2D/3D). Convierte texto SVG a paths antes de importar.
- **Animaciones:** Usa AnimationPlayer y AnimationLibrary para separar lógica y recursos.
- **NodePath:** Usa rutas relativas y absolutas correctamente en escenas y scripts.

## Git y GitHub
- Cada feature, fix o mejora inicia en una rama nueva.
- Los commits deben ser claros y descriptivos.
- Los PR requieren revisión y validación antes de merge.
- Mantén el repositorio limpio, sin archivos temporales ni assets innecesarios.

## Recursos y referencias
- [Buenas prácticas Godot](https://docs.godotengine.org/en/4.4/tutorials/best_practices/index.html)
- [Formato .tscn](https://docs.godotengine.org/en/4.4/contributing/development/file_formats/tscn.html)
- [Style guide GDScript](https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [Importación de imágenes](https://docs.godotengine.org/en/4.4/tutorials/assets_pipeline/importing_images.html)
- [godot documentation](https://github.com/godotengine/awesome-godot#readme)

## Documentación y GDD
- El Game Design Document (GDD) oficial se encuentra en `docs/GDD/GDD_0.1.0.md`. Todo el equipo debe consultarlo y mantenerlo actualizado.
- El directorio `docs/` almacena toda la documentación del proyecto. Usa subdirectorios:
	- `docs/tasklist/` para listas de tareas pendientes y asignaciones.
	- `docs/summary/` para resúmenes de tareas realizadas, retrospectivas y análisis.
- Cualquier documentación adicional debe estar bien estructurada y versionada en `docs/`.

## Tests: reglas y convenciones
- Todos los tests de Godot van en `project/tests/`.
- Convenciones de nombres:
	- `NombreClase_test.gd` para tests de clase.
	- `test_<feature>_*.gd` para tests de funcionalidad.
- Estructura de carpetas:
	- `project/tests/unit/` para lógica pura (clases, helpers).
	- `project/tests/integration/` para escenas, señales y singletons.
	- `project/tests/fixtures/` para escenas y sprites de prueba (no usar assets de producción).
- Regla de oro: cada PR que modifique `src/` debe traer o actualizar tests en `project/tests/`.
- Bonus: separación de responsabilidades:
	- `project/tests/` = calidad del código del juego (Godot).
	- `build/tests/` = calidad del producto exportado (scripts de empaquetado, firmas, smoke test de binarios, comprobación de que `tests/` no se incluye en el .apk/.exe/web).
- No hay debate: los tests de Godot van en `project/tests/`. Las pruebas de pipeline van en `build/tests/`.
- Usaremos GdUnit4, es más amigable con Godot 4

## Uso de Godot CLI
- El ejecutable `godot.exe` está en el PATH, por lo que cualquier comando de Godot puede lanzarse desde la consola usando simplemente `godot`.

## Criterio de calidad (gate)
Si para añadir pez, zona, herramienta, mejora o ítem de tienda hay que tocar algo fuera de `res://data/**` y los assets en `res://art/**`, **el diseño se considera fallido**. Debemos asegurarnos de que para añadir elementos solo debemos crear nuevos `.tres` y para modificar elementos visuales utilicemos el theme base o algún theme existente adaptable. Solo si no existe crearemos theme nuevo. No hardcodearemos UI.


## Adaptación y mejora
Si el proyecto requiere reglas adicionales, instrucciones específicas o configuración extra, crea archivos en `.github` siguiendo este formato y documenta los cambios.

---
Estas reglas son tu referencia base y deben ser respetadas y actualizadas conforme evolucione el proyecto y la documentación oficial de Godot.
