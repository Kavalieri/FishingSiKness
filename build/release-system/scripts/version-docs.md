# 🔄 Sistema de Versionado Automático

## 📋 Descripción

Sistema automatizado que sincroniza la versión mostrada en la SplashScreen del juego con las releases de GitHub o tags de Git antes de cada build.

## 🎯 Objetivo

- **Consistencia**: Asegurar que la versión mostrada en el juego coincida con la release actual
- **Automatización**: Eliminar actualizaciones manuales de versión en el código
- **Integración**: Funciona automáticamente con todos los scripts de build

## 📁 Archivos del Sistema

```
build/release-system/scripts/
├── sync-version.ps1        # Motor principal de sincronización
├── version-helper.ps1      # Utilidad de gestión manual
└── version-docs.md         # Esta documentación
```

## 🔧 Funcionamiento

### Flujo de Sincronización

1. **Obtener versión objetivo**:
   - Primero intenta GitHub API (`/releases/latest`)
   - Si falla, usa git tags local (`git describe --tags --abbrev=0`)
   - Como último recurso, usa versión por defecto (`v0.1.0`)

2. **Verificar versión actual**:
   - Lee `project/src/views/SplashScreen.gd`
   - Extrae el texto actual de `version_label.text`

3. **Actualizar si necesario**:
   - Compara versiones y actualiza el archivo
   - Detecta automáticamente si es pre-release
   - Formatea: `"Fishing SiKness v1.2.3 pre-release alpha"`

### Integración con Builds

Todos los scripts de build llaman automáticamente la sincronización:

```powershell
# Ejemplo de integración en build-windows.ps1
$syncResult = & $syncScriptPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Advertencia: No se pudo sincronizar la versión"
}
```

## 🛠️ Uso Manual

### Herramienta version-helper.ps1

```powershell
# Ver estado actual
.\build\release-system\scripts\version-helper.ps1 -Action show

# Sincronizar con GitHub/Git
.\build\release-system\scripts\version-helper.ps1 -Action sync

# Establecer versión personalizada
.\build\release-system\scripts\version-helper.ps1 -Action set -Version "v1.0.0-beta"

# Probar sistema completo
.\build\release-system\scripts\version-helper.ps1 -Action test
```

### Script sync-version.ps1 directo

```powershell
# Sincronización normal
.\build\release-system\scripts\sync-version.ps1

# Forzar actualización
.\build\release-system\scripts\sync-version.ps1 -Force

# Versión personalizada
.\build\release-system\scripts\sync-version.ps1 -CustomVersion "v2.0.0"

# Modo verbose
.\build\release-system\scripts\sync-version.ps1 -Verbose
```

## 📊 Detección de Pre-release

El sistema detecta automáticamente pre-releases basado en:

- **GitHub API**: Campo `prerelease` de la release
- **Git tags**: Presencia de keywords: `alpha`, `beta`, `rc`, `pre`
- **Versión personalizada**: Misma detección por keywords

Formato resultante:
- **Release**: `"Fishing SiKness v1.0.0"`
- **Pre-release**: `"Fishing SiKness v1.0.0-alpha pre-release alpha"`

## 🚀 Scripts de Build Integrados

Los siguientes scripts llaman automáticamente a la sincronización:

- `build-windows.ps1` - Build Windows EXE
- `build-android.ps1` - Build Android APK/AAB
- `build-web.ps1` - Build Web HTML5
- `build-all.ps1` - Build todas las plataformas

## 🔍 Troubleshooting

### Problemas Comunes

**404 GitHub API**:
- Normal si no hay releases públicas
- El script usa git tags como fallback
- No afecta el funcionamiento

**Error de permisos**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Archivo SplashScreen.gd no encontrado**:
- Verificar estructura del proyecto
- El script busca en: `project/src/views/SplashScreen.gd`

### Verificación Manual

```powershell
# Verificar que el patrón de versión es correcto
Get-Content project/src/views/SplashScreen.gd | Select-String "version_label.text"

# Verificar git tags
git tag --list | Sort-Object -Descending

# Verificar última release GitHub (si existe)
Invoke-RestMethod "https://api.github.com/repos/Kavalieri/FishingSiKness/releases/latest"
```

## 📝 Formato del Archivo SplashScreen.gd

El sistema busca y modifica esta línea específica:

```gdscript
# ANTES
version_label.text = "Fishing SiKness v0.1.0 pre-release alpha"

# DESPUÉS (ejemplo)
version_label.text = "Fishing SiKness v0.2.5-alpha pre-release alpha"
```

**Patrón regex utilizado**:
```regex
(version_label\.text\s*=\s*")[^"]*(")`
```

## ✅ Validación

Para verificar que todo funciona correctamente:

1. **Ejecutar test completo**:
   ```powershell
   .\build\release-system\scripts\version-helper.ps1 -Action test
   ```

2. **Verificar integración en build**:
   ```powershell
   .\build\release-system\scripts\build-windows.ps1
   # Debe mostrar "✅ Versión sincronizada correctamente"
   ```

3. **Revisar manualmente SplashScreen**:
   - Abrir `project/src/views/SplashScreen.gd`
   - Verificar línea ~241 tiene la versión correcta

---

## 📚 Referencias

- **GitHub API**: https://docs.github.com/en/rest/releases
- **Git Tags**: `git tag --help`
- **SemVer**: https://semver.org/
- **PowerShell Regex**: https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_regular_expressions

---

**✨ Sistema funcional y listo para producción**
