# 🧹 Plan de Limpieza - Bar-Sik

## 📂 ESTRUCTURA ACTUAL (DESORGANIZADA)

### ❌ **Archivos a ELIMINAR:**
```
build-all.ps1                    # Corrupto con markdown
build-all-clean.ps1             # Duplicado
build-debug.ps1                 # Testing temporal
build-debug-simple.ps1          # Testing temporal
build-history.ps1               # Testing temporal
build-quick.ps1                 # Testing temporal
build-simple.ps1                # Testing temporal
debug-build.ps1                 # Testing temporal
debug-vscode-correct.ps1        # Testing temporal
auto-setup-android.ps1          # Setup temporal
install-android-sdk.ps1         # Setup temporal
install-complete-android.ps1    # Setup temporal
diagnose-android.ps1            # Diagnóstico temporal
setup-export.ps1                # Setup temporal
launch-and-debug.ps1            # Testing temporal
run-game.bat                    # Duplicado
run-game.ps1                    # Duplicado
```

### ❌ **Documentación a ELIMINAR:**
```
BUILD-README.md                 # Duplicada
BUILD_SYSTEM_READY.md          # Temporal
CORRECCIONES_ERRORES_SINTAXIS.md # Temporal
INSTALL_TEMPLATES.md           # Temporal
MEJORAS_VISUALES_PROFESIONALES.md # Temporal
MIGRACION_SISTEMA_MODULAR.md   # Temporal
SETUP_FINAL.md                 # Temporal
docs/EXPORT_CONFIG.md          # Duplicada
docs/EXPORT_GUIDE.md           # Duplicada
docs/PREREQUISITES.md          # Duplicada
docs/QUICK_COMMANDS.md         # Duplicada
docs/SETUP_STEP_BY_STEP.md     # Duplicada
```

### ❌ **Archivos de Backup a ELIMINAR:**
```
project/export_presets.cfg.backup
project/scripts/*_New.gd       # Scripts de testing
project/scripts/*_new.gd       # Scripts de testing
project/test_*.gd              # Scripts de testing
project/scripts/GameScene_clean.gd
```

---

## ✅ **ESTRUCTURA FINAL LIMPIA:**

### **📁 release-system/ (MANTENER)**
```
release-system/
├── scripts/
│   ├── build-web.ps1          # Build web + servidor
│   ├── build-android.ps1      # Build Android APK/AAB
│   └── clean-builds.ps1       # Limpieza de builds
├── docs/
│   └── RELEASE_PROCESS.md     # Proceso completo
└── README.md                  # Guía principal
```

### **📁 project/ (LIMPIAR)**
```
project/
├── export_presets.cfg         # Solo este
├── project.godot             # Configuración principal
├── scenes/                   # Solo escenas finales
├── scripts/                  # Solo scripts finales
└── singletons/               # Solo singletons finales
```

### **📁 builds/ (MANTENER ORGANIZADO)**
```
builds/
├── windows/latest/           # Solo último build
├── android/latest/           # Solo último build
└── web/latest/              # Solo último build
```

---

## 🚀 **COMANDOS DE LIMPIEZA:**

### **1. Eliminar archivos temporales:**
```powershell
# Scripts temporales
Remove-Item build-all*.ps1, build-debug*.ps1, build-quick.ps1, build-simple.ps1
Remove-Item debug-*.ps1, auto-setup-*.ps1, install-*.ps1, diagnose-*.ps1
Remove-Item setup-export.ps1, launch-and-debug.ps1, run-game.*

# Documentación temporal
Remove-Item BUILD*.md, INSTALL_TEMPLATES.md, SETUP_FINAL.md
Remove-Item CORRECCIONES_*.md, MEJORAS_*.md, MIGRACION_*.md

# Backups y tests
Remove-Item project/export_presets.cfg.backup
Remove-Item project/test_*.gd, project/scripts/*_New.gd, project/scripts/*_new.gd
```

### **2. Organizar builds:**
```powershell
# Mantener solo últimos builds
.\release-system\scripts\clean-builds.ps1 -KeepLast 1
```

### **3. Commit limpieza:**
```powershell
git add .
git commit -m "chore: Limpieza post-release - estructura organizada"
git push origin main
```

---

## 📋 **RESULTADO FINAL:**
- ✅ Scripts esenciales en `release-system/`
- ✅ Documentación centralizada
- ✅ Estructura de proyecto limpia
- ✅ Builds organizados
- ✅ Ready para próximas releases
