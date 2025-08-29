# 🤖 BUILD ANDROID - FishingSiKness (APK + AAB para Google Play Store)
param(
    [string]$Version = "0.2.1-alpha",
    [switch]$APKOnly,
    [switch]$AABOnly
)

Write-Host "📱 FishingSiKness - Build Android v$Version" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Cyan

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$RootDir = Get-Location
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\project")
$BuildDir = Resolve-Path (Join-Path $PSScriptRoot "..\..\builds")
$GodotPath = "godot"

Write-Host "📅 Timestamp: $timestamp" -ForegroundColor Gray
Write-Host "📁 Proyecto: $ProjectRoot" -ForegroundColor Gray

# Verificaciones
try {
    $null = & $GodotPath --version 2>$null
}
catch {
    Write-Host "❌ Godot no encontrado en PATH. Asegúrate de que 'godot' esté disponible." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $ProjectRoot)) {
    Write-Host "❌ Proyecto no encontrado en: $ProjectRoot" -ForegroundColor Red
    exit 1
}

# Función para crear directorio timestamped
function New-AndroidTimestampedDir {
    param($Timestamp)

    $androidDir = Join-Path $BuildDir "android"
    $timestampDir = Join-Path $androidDir $Timestamp
    New-Item -ItemType Directory -Force -Path $timestampDir | Out-Null
    return $timestampDir
}

$timestampDir = New-AndroidTimestampedDir $timestamp
$buildSuccess = 0
$buildErrors = @()

# BUILD APK (para testing y distribución directa)
if (-not $AABOnly) {
    Write-Host "`n📱 COMPILANDO ANDROID APK..." -ForegroundColor Cyan
    $apkPath = Join-Path $timestampDir "FishingSiKness.apk"
    Write-Host "Output: $apkPath" -ForegroundColor Gray

    try {
        $arguments = '--path "' + $ProjectRoot + '" --headless --export-release "Android APK" "' + $apkPath + '"'
        Write-Host "Ejecutando: $GodotPath [args]" -ForegroundColor Gray

        $process = Start-Process -FilePath $GodotPath -ArgumentList $arguments.Split(' ', [StringSplitOptions]::RemoveEmptyEntries) -PassThru -Wait -NoNewWindow

        if ($process.ExitCode -eq 0 -and (Test-Path $apkPath)) {
            $fileSize = (Get-Item $apkPath).Length
            $fileSizeMB = [math]::Round($fileSize / 1MB, 2)

            Write-Host "✅ BUILD APK exitoso!" -ForegroundColor Green
            Write-Host "📦 Archivo: FishingSiKness.apk ($fileSizeMB MB)" -ForegroundColor White
            $buildSuccess++
        }
        else {
            $errorMsg = "❌ Error en APK build (código: $($process.ExitCode))"
            Write-Host $errorMsg -ForegroundColor Red
            $buildErrors += $errorMsg
        }
    }
    catch {
        $errorMsg = "❌ Error ejecutando APK build: $($_.Exception.Message)"
        Write-Host $errorMsg -ForegroundColor Red
        $buildErrors += $errorMsg
    }
}

# BUILD AAB (para Google Play Store)
if (-not $AABOnly) {
    Write-Host "`n🏪 COMPILANDO ANDROID AAB (Google Play Store)..." -ForegroundColor Cyan
    $aabPath = Join-Path $timestampDir "FishingSiKness.aab"
    Write-Host "Output: $aabPath" -ForegroundColor Gray

    try {
        $arguments = '--path "' + $ProjectRoot + '" --headless --export-release "Android AAB" "' + $aabPath + '"'
        Write-Host "Ejecutando: $GodotPath [args]" -ForegroundColor Gray

        $process = Start-Process -FilePath $GodotPath -ArgumentList $arguments.Split(' ', [StringSplitOptions]::RemoveEmptyEntries) -PassThru -Wait -NoNewWindow

        if ($process.ExitCode -eq 0 -and (Test-Path $aabPath)) {
            $fileSize = (Get-Item $aabPath).Length
            $fileSizeMB = [math]::Round($fileSize / 1MB, 2)

            Write-Host "✅ BUILD AAB exitoso!" -ForegroundColor Green
            Write-Host "📦 Archivo: FishingSiKness.aab ($fileSizeMB MB)" -ForegroundColor White
            Write-Host "🏪 Listo para Google Play Store" -ForegroundColor Yellow
            $buildSuccess++
        }
        else {
            $errorMsg = "❌ Error en AAB build (código: $($process.ExitCode))"
            Write-Host $errorMsg -ForegroundColor Red
            $buildErrors += $errorMsg
        }
    }
    catch {
        $errorMsg = "❌ Error ejecutando AAB build: $($_.Exception.Message)"
        Write-Host $errorMsg -ForegroundColor Red
        $buildErrors += $errorMsg
    }
}

# RESUMEN FINAL
Write-Host "`n🤖 RESUMEN ANDROID BUILDS" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Cyan

if ($buildSuccess -gt 0) {
    Write-Host "✅ Builds exitosos: $buildSuccess" -ForegroundColor Green
    Write-Host "📍 Ubicación: $timestampDir" -ForegroundColor Gray

    # Actualizar directorio latest después de generar los archivos
    $androidDir = Join-Path $BuildDir "android"
    $latestDir = Join-Path $androidDir "latest"

    if (Test-Path $latestDir) {
        Remove-Item $latestDir -Force -Recurse -ErrorAction SilentlyContinue
    }

    try {
        New-Item -ItemType SymbolicLink -Path $latestDir -Target $timestampDir -ErrorAction Stop | Out-Null
        Write-Host "   🔗 Directorio 'latest' actualizado (symlink)" -ForegroundColor Gray
    }
    catch {
        Copy-Item $timestampDir $latestDir -Recurse -Force
        Write-Host "   📁 Directorio 'latest' actualizado (copia)" -ForegroundColor Gray
    }

    Write-Host "📂 Acceso rápido: builds\android\latest\" -ForegroundColor Gray

    Write-Host "`n📋 ARCHIVOS GENERADOS:" -ForegroundColor Cyan
    Get-ChildItem $timestampDir -Filter "*.apk" -ErrorAction SilentlyContinue | ForEach-Object {
        $sizeMB = [math]::Round($_.Length / 1MB, 2)
        Write-Host "   📱 $($_.Name) ($sizeMB MB)" -ForegroundColor White
    }
    Get-ChildItem $timestampDir -Filter "*.aab" -ErrorAction SilentlyContinue | ForEach-Object {
        $sizeMB = [math]::Round($_.Length / 1MB, 2)
        Write-Host "   🏪 $($_.Name) ($sizeMB MB) ← Google Play Store" -ForegroundColor Yellow
    }

    Write-Host "`n🚀 BUILD ANDROID COMPLETADO!" -ForegroundColor Green

    # Volver al directorio raíz del proyecto
    Set-Location $RootDir
}
else {
    Write-Host "❌ No se generaron builds exitosos" -ForegroundColor Red

    Write-Host "`n💡 POSIBLES SOLUCIONES:" -ForegroundColor Yellow
    Write-Host "   1. Instalar Android SDK y configurar ANDROID_HOME" -ForegroundColor White
    Write-Host "   2. Descargar export templates: Project > Export > Install Android Build Template" -ForegroundColor White
    Write-Host "   3. Configurar keystore para signing en Godot Export settings" -ForegroundColor White

    exit 1
}

# Volver al directorio raíz del proyecto
Set-Location $RootDir

# Salir con código exitoso
exit 0
