# 🚀 BUILD WINDOWS - FishingSiKness
# Versión optimizada para máxima compatibilidad en otros PCs

Write-Host "🚀 FishingSiKness - Build Windows" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "💡 Optimizado para compatibilidad máxima" -ForegroundColor Yellow

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$RootDir = Get-Location
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\project")
$BuildDir = Resolve-Path (Join-Path $PSScriptRoot "..\..\builds")
$GodotPath = "godot"

Write-Host "📅 Timestamp: $timestamp" -ForegroundColor Gray
Write-Host "📁 Proyecto: $ProjectRoot" -ForegroundColor Gray

# Verificar que Godot existe en PATH
try {
    $null = & $GodotPath --version 2>$null
}
catch {
    Write-Host "❌ Godot no encontrado en PATH. Asegúrate de que 'godot' esté disponible." -ForegroundColor Red
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

$exePath = Join-Path $timestampDir "FishingSiKness.exe"

Write-Host "`n🔧 Modificando configuración temporal para máxima compatibilidad..." -ForegroundColor Yellow

# Backup de export_presets.cfg
$exportPresetsPath = Join-Path $ProjectRoot "export_presets.cfg"
$backupPath = Join-Path $ProjectRoot "export_presets.cfg.backup"
Copy-Item $exportPresetsPath $backupPath -Force

# Leer configuración actual
$exportConfig = Get-Content $exportPresetsPath -Raw

# Modificar para máxima compatibilidad
$newConfig = $exportConfig -replace 'debug/export_console_wrapper=0', 'debug/export_console_wrapper=1'
$newConfig = $newConfig -replace 'export_path="../builds/windows/FishingSiKness.exe"', "export_path=`"$exePath`""

# Aplicar configuración temporal
Set-Content $exportPresetsPath $newConfig -NoNewline

Write-Host "`n🔨 Ejecutando build con configuración standalone..." -ForegroundColor Yellow

# Build con preset 0 (Windows Desktop - Release)
$godotArgs = "--headless --export-release `"Windows Desktop - Release`" `"$exePath`" --path `"$ProjectRoot`""
$process = Start-Process -FilePath $GodotPath -ArgumentList $godotArgs -PassThru -NoNewWindow

# Esperar con timeout de 5 minutos
$timeout = 300 # 5 minutos en segundos
if (-not $process.WaitForExit($timeout * 1000)) {
    Write-Host "⚠️ Timeout alcanzado, forzando cierre del proceso..." -ForegroundColor Yellow
    $process.Kill()
    $process.WaitForExit()
}

# Restaurar configuración original
Copy-Item $backupPath $exportPresetsPath -Force
Remove-Item $backupPath -Force

# Verificar resultado
if (Test-Path $exePath) {
    $exeInfo = Get-Item $exePath
    Write-Host "`n✅ BUILD COMPLETADO!" -ForegroundColor Green
    Write-Host "📁 Ubicación: $exePath" -ForegroundColor Cyan
    Write-Host "📏 Tamaño: $([math]::Round($exeInfo.Length/1MB, 2)) MB" -ForegroundColor Cyan

    # Crear symlink latest
    $latestDir = Join-Path $windowsDir "latest"

    if (Test-Path $latestDir) {
        Remove-Item $latestDir -Force -Recurse -ErrorAction SilentlyContinue
    }

    try {
        # Intentar crear symlink del directorio completo
        New-Item -ItemType SymbolicLink -Path $latestDir -Target $timestampDir -ErrorAction Stop | Out-Null
        Write-Host "   🔗 Symlink 'latest' creado apuntando a $timestampDir" -ForegroundColor Green
    }
    catch {
        # Fallback: copiar directorio
        Copy-Item $timestampDir $latestDir -Recurse -Force
        Write-Host "   📁 Directorio 'latest' copiado (symlink falló)" -ForegroundColor Yellow
    }

    Write-Host "`n💡 RECOMENDACIONES PARA COMPATIBILIDAD:" -ForegroundColor Yellow
    Write-Host "  ✅ PCK embedido - No necesita archivos adicionales" -ForegroundColor Green
    Write-Host "  ✅ Console wrapper habilitado - Mejor debuging" -ForegroundColor Green
    Write-Host "  ⚠️  Visual C++ 2019/2022 Redistributable puede ser necesario" -ForegroundColor Yellow
    Write-Host "  💡 Incluir vcredist_x64.exe con la distribución" -ForegroundColor Cyan

    Write-Host "`n🌐 URLs de descarga para VC++ Redistributable:" -ForegroundColor Cyan
    Write-Host "  https://aka.ms/vs/17/release/vc_redist.x64.exe" -ForegroundColor Blue

}
else {
    Write-Host "`n❌ Error: No se pudo generar el ejecutable" -ForegroundColor Red
    exit 1
}

Write-Host "`n🎯 Build Windows listo para distribución!" -ForegroundColor Green

# Volver al directorio raíz del proyecto
Set-Location $RootDir

# Salir con código exitoso
exit 0
