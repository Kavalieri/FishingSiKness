# 🚀 BUILD WINDOWS - Bar-Sik
# Versión optimizada para máxima compatibilidad en otros PCs

Write-Host "🚀 Bar-Sik - Build Windows" -ForegroundColor Green
Write-Host "===========================" -ForegroundColor Cyan
Write-Host "💡 Optimizado para compatibilidad máxima" -ForegroundColor Yellow

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\project")
$BuildDir = Resolve-Path (Join-Path $PSScriptRoot "..\..\builds")
$GodotPath = "E:\2- Descargas\Godot_v4.4.1-stable_win64.exe\Godot_v4.4.1-stable_win64.exe"

Write-Host "📅 Timestamp: $timestamp" -ForegroundColor Gray
Write-Host "📁 Proyecto: $ProjectRoot" -ForegroundColor Gray

# Verificar que Godot existe
if (-not (Test-Path $GodotPath)) {
    Write-Host "❌ Godot no encontrado en: $GodotPath" -ForegroundColor Red
    exit 1
}

# Verificar que el proyecto existe
if (-not (Test-Path $ProjectRoot)) {
    Write-Host "❌ Proyecto no encontrado en: $ProjectRoot" -ForegroundColor Red
    exit 1
}

# Crear directorio de builds
$windowsDir = Join-Path $BuildDir "windows"
$timestampDir = Join-Path $windowsDir $timestamp
New-Item -ItemType Directory -Force -Path $timestampDir | Out-Null

$exePath = Join-Path $timestampDir "bar-sik.exe"

Write-Host "`n🔧 Modificando configuración temporal para máxima compatibilidad..." -ForegroundColor Yellow

# Backup de export_presets.cfg
$exportPresetsPath = Join-Path $ProjectRoot "export_presets.cfg"
$backupPath = Join-Path $ProjectRoot "export_presets.cfg.backup"
Copy-Item $exportPresetsPath $backupPath -Force

# Leer configuración actual
$exportConfig = Get-Content $exportPresetsPath -Raw

# Modificar para máxima compatibilidad
$newConfig = $exportConfig -replace 'debug/export_console_wrapper=0', 'debug/export_console_wrapper=1'
$newConfig = $newConfig -replace 'export_path="../builds/windows/bar-sik.exe"', 'export_path="../builds/windows/bar-sik.exe"'

# Aplicar configuración temporal
Set-Content $exportPresetsPath $newConfig -NoNewline

Write-Host "`n🔨 Ejecutando build con configuración standalone..." -ForegroundColor Yellow

# Build con preset 0 (Windows Desktop)
$godotArgs = "--headless --export-release `"Windows Desktop`" `"$exePath`" --path `"$ProjectRoot`""
$process = Start-Process -FilePath $GodotPath -ArgumentList $godotArgs -Wait -PassThru -NoNewWindow

# Restaurar configuración original
Copy-Item $backupPath $exportPresetsPath -Force
Remove-Item $backupPath -Force

# Verificar resultado
if (Test-Path $exePath) {
    $exeInfo = Get-Item $exePath
    Write-Host "`n✅ BUILD COMPLETADO!" -ForegroundColor Green
    Write-Host "📁 Ubicación: $exePath" -ForegroundColor Cyan
    Write-Host "📏 Tamaño: $([math]::Round($exeInfo.Length/1MB, 2)) MB" -ForegroundColor Cyan

    # Copiar a latest
    $latestDir = Join-Path $windowsDir "latest"
    $latestPath = Join-Path $latestDir "bar-sik.exe"
    New-Item -ItemType Directory -Force -Path $latestDir | Out-Null
    Copy-Item $exePath $latestPath -Force

    Write-Host "`n💡 RECOMENDACIONES PARA COMPATIBILIDAD:" -ForegroundColor Yellow
    Write-Host "  ✅ PCK embedido - No necesita archivos adicionales" -ForegroundColor Green
    Write-Host "  ✅ Console wrapper habilitado - Mejor debuging" -ForegroundColor Green
    Write-Host "  ⚠️  Visual C++ 2019/2022 Redistributable puede ser necesario" -ForegroundColor Yellow
    Write-Host "  💡 Incluir vcredist_x64.exe con la distribución" -ForegroundColor Cyan

    Write-Host "`n🌐 URLs de descarga para VC++ Redistributable:" -ForegroundColor Cyan
    Write-Host "  https://aka.ms/vs/17/release/vc_redist.x64.exe" -ForegroundColor Blue

} else {
    Write-Host "`n❌ Error: No se pudo generar el ejecutable" -ForegroundColor Red
    exit 1
}

Write-Host "`n🎯 Build Windows listo para distribución!" -ForegroundColor Green
