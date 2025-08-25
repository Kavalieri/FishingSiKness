# 🚀 Proceso de Release - Bar-Sik

## 📋 RESUMEN RELEASE v0.3.0-pre

### ✅ **Release Exitosa Creada:**
- **URL**: https://github.com/Kavalieri/bar-sik/releases/tag/v0.3.0-pre
- **Tipo**: Pre-release
- **Fecha**: 19 Agosto 2025

### 📦 **Archivos Incluidos:**
- **bar-sik.exe**: 93.23 MB (Windows Desktop)
- **bar-sik.apk**: 24.66 MB (Android, firmado)

---

## 🔧 PROCESO COMPLETO DE RELEASE

### 1. **Preparación de Builds**
```powershell
# Android APK
.\build-android.ps1 -APKOnly

# Web Build
.\build-web.ps1

# Verificar builds generados
ls builds/android/ -Recurse -Filter "*.apk"
ls builds/windows/*/bar-sik.exe
```

### 2. **Gestión de Ramas**
```powershell
# Desde rama de desarrollo
git push origin release/v0.3.0-epic-rewrite

# Crear PR
gh pr create --title "Release v0.3.0 - Epic Rewrite + Sistema Builds" --base main

# Merge PR
gh pr merge --merge --delete-branch

# Cambiar a main
git checkout main
git pull origin main
```

### 3. **Crear Release**
```powershell
# Crear tag
git tag v0.3.0-pre -m "Pre-release v0.3.0"
git push origin v0.3.0-pre

# Crear release con archivos
gh release create v0.3.0-pre \
  --title "Bar-Sik v0.3.0 Pre-Release - Epic Rewrite" \
  --notes "[CONTENIDO_NOTAS]" \
  --prerelease \
  "builds/windows/[TIMESTAMP]/bar-sik.exe" \
  "builds/android/[TIMESTAMP]/bar-sik.apk"
```

### 4. **Verificación**
```powershell
gh release view v0.3.0-pre
gh release list
```

---

## 📱 CONFIGURACIÓN ANDROID

### **Prerequisitos:**
- Java 17 JDK instalado
- Android SDK configurado en Godot Editor
- Keystore creado para firma

### **Paths Configurados:**
- **Java SDK**: `C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot`
- **Android SDK**: `C:\Android\sdk`
- **Keystore**: `E:\GitHub\bar-sik\bar-sik-release.keystore`

### **Credenciales Keystore:**
- **Archivo**: `bar-sik-release.keystore`
- **Alias**: `bar-sik`
- **Password**: `bar-sik123`

---

## 🏗️ BUILDS MULTIPLATAFORMA

### **Windows Desktop**
- **Tamaño**: ~93MB
- **Formato**: EXE nativo
- **Template**: Windows Desktop export preset

### **Android APK**
- **Tamaño**: ~24MB
- **Firmado**: Sí (con keystore propio)
- **Arquitectura**: ARM64-v8a
- **Template**: Android export preset

### **Web HTML5**
- **Tamaño**: ~42MB
- **Formato**: WebAssembly + HTML
- **Servidor**: Integrado para testing local
- **Puerto**: 8080

---

## 🧹 LIMPIEZA POST-RELEASE

### **Archivos a Mantener:**
- `release-system/scripts/` → Scripts esenciales
- `builds/` → Builds organizados por timestamp
- `project/export_presets.cfg` → Configuración export
- `bar-sik-release.keystore` → Keystore Android

### **Archivos a Limpiar:**
- Scripts de testing temporales
- Documentación duplicada
- Builds antiguos (mantener solo últimos 3)
- Archivos de debug y diagnóstico

---

## 🎯 PRÓXIMAS RELEASES

### **Para v0.3.1:**
1. Ejecutar builds con scripts del `release-system/`
2. Seguir mismo proceso de PR + merge
3. Crear nueva release con timestamp actualizado

### **Para Release Estable:**
- Cambiar `--prerelease` por release normal
- Actualizar changelog completo
- Testing exhaustivo en todas las plataformas
