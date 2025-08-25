# 🚀 Release System - Bar-Sik

Sistema de builds y distribución multiplataforma para Bar-Sik.

## 📦 **Scripts Principales**

### `scripts/build-windows.ps1`
- Build para Windows Desktop EXE
- Organización automática por timestamps
- Tamaño: ~93MB

### `scripts/build-web.ps1`
- Build para Web HTML5 + WebAssembly
- Servidor local integrado en puerto 8080
- Tamaño: ~42MB

### `scripts/build-android.ps1`
- Build Android APK firmado
- Soporte AAB para Google Play Store
- Tamaño: ~24MB

### `scripts/clean-builds.ps1`
- Limpieza de builds antiguos
- Mantiene últimos N builds por plataforma

## 📚 **Documentación**

### `docs/RELEASE_PROCESS.md`
- Proceso completo de release
- Comandos GitHub CLI
- Configuración Android

### `docs/CLEANUP_PLAN.md`
- Plan de limpieza post-release
- Archivos a eliminar
- Estructura final

## 🎯 **Uso Rápido**

### **Build Completo:**
```powershell
# Builds individuales
.\scripts\build-windows.ps1
.\scripts\build-web.ps1
.\scripts\build-android.ps1 -APKOnly

# Limpieza
.\scripts\clean-builds.ps1 -KeepLast 3
```

### **Release Nueva Versión:**
1. Hacer PR de rama desarrollo → main
2. Merge PR
3. Crear tag: `git tag v0.X.Y`
4. Release: `gh release create v0.X.Y --prerelease [archivos]`

## ⚙️ **Configuración Necesaria**

### **Android:**
- Java 17 JDK
- Android SDK en Godot Editor
- Keystore: `bar-sik-release.keystore`

### **Paths:**
- Java: `C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot`
- Android SDK: `C:\Android\sdk`

---

**Sistema probado y funcional en v0.3.0-pre** ✅
