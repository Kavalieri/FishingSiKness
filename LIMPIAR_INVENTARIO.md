# Instrucciones para Limpiar Inventario

Para probar con datos limpios:

1. **Eliminar save existente**: Borrar el archivo de guardado en `user://savegame/`
2. **O usar el panel de debug**: Presionar F2 y usar la opción de limpiar inventario
3. **O reiniciar desde código**: Llamar a `UnifiedInventorySystem.clear_all_containers()`

Esto asegurará que solo se muestren peces capturados realmente por el jugador.