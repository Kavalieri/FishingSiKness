# 🎨 Formato de Themes - IMPORTANTE

## ⚠️ Error Común Resuelto: .theme vs .tres

### Problema Identificado
Los archivos `.theme` causan errores de compilación en Godot 4.4:
```
Unrecognized binary resource file: 'res://themes/app.theme'
```

### Solución Confirmada por Documentación Oficial
**Godot 4.4 usa exclusivamente `.tres` para recursos Theme:**

1. **Documentación oficial**: Los Theme son Resources que se guardan como `.tres` por defecto
2. **Proceso correcto**: FileSystem → New Resource → Theme → se crea automáticamente como `.tres`
3. **Theme Editor**: Se abre automáticamente al seleccionar un recurso Theme `.tres`

### Convención del Proyecto
```
❌ INCORRECTO (causaba errores):
res://themes/app.theme
res://themes/card.theme

✅ CORRECTO (formato oficial Godot 4.4):
res://themes/app_theme.tres
res://themes/card_theme.tres
```

### Archivos Actualizados
- [x] `app_theme.tres` - tema principal creado correctamente
- [x] Documentación actualizada con formato correcto
- [x] Referencias en `.tscn` limpiadas (eliminadas dependencias corruptas)

### Próximos Pasos
1. Crear themes adicionales como `.tres` según necesidades
2. Configurar `app_theme.tres` como theme global del proyecto
3. Implementar StyleBox específicos para componentes UI

---
**Referencia**: [Godot 4.4 Theme Class Documentation](https://docs.godotengine.org/en/4.4/classes/class_theme.html)
