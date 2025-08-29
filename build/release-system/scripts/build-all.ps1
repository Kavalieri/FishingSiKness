# =============================================================================
# FishingSiKness - Build All Platforms
# =============================================================================
# Construye el juego para todas las plataformas disponibles:
# - Windows (standalone executable)
# - Android (APK + AAB)
# - Web (HTML5 + WebAssembly) con deploy automático a Vercel
# =============================================================================

param(
    [switch]$Deploy,  # Si incluir deploy web a Vercel
    [switch]$Clean    # Si limpiar builds anteriores
)

# Configuración
$rootDir = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName
$scriptsDir = $PSScriptRoot
$buildsDir = Join-Path $rootDir "build\builds"

Write-Host "🚀 FishingSiKness - Build ALL Platforms" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "📁 Proyecto: $rootDir"
Write-Host "📂 Scripts: $scriptsDir"
Write-Host ""

# Limpiar builds anteriores si se solicita
if ($Clean) {
    Write-Host "🧹 Limpiando builds anteriores..." -ForegroundColor Yellow
    if (Test-Path $buildsDir) {
        Remove-Item $buildsDir -Recurse -Force
        Write-Host "✅ Builds anteriores eliminados" -ForegroundColor Green
    }
    Write-Host ""
}

# Variables para tracking
$successCount = 0
$failCount = 0
$results = @()

# =============================================================================
# BUILD WINDOWS
# =============================================================================
Write-Host "🖥️  INICIANDO BUILD WINDOWS..." -ForegroundColor Magenta
$windowsScript = Join-Path $scriptsDir "build-windows.ps1"

try {
    & $windowsScript
    if ($LASTEXITCODE -eq 0) {
        $successCount++
        $results += "✅ Windows Build: EXITOSO"
        Write-Host "✅ Windows Build completado" -ForegroundColor Green
    }
    else {
        $failCount++
        $results += "❌ Windows Build: FALLÓ"
        Write-Host "❌ Windows Build falló" -ForegroundColor Red
    }
}
catch {
    $failCount++
    $results += "❌ Windows Build: ERROR - $($_.Exception.Message)"
    Write-Host "❌ Error en Windows Build: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# =============================================================================
# BUILD ANDROID
# =============================================================================
Write-Host "🤖 INICIANDO BUILD ANDROID..." -ForegroundColor Green
$androidScript = Join-Path $scriptsDir "build-android.ps1"

try {
    & $androidScript
    if ($LASTEXITCODE -eq 0) {
        $successCount++
        $results += "✅ Android Build: EXITOSO"
        Write-Host "✅ Android Build completado" -ForegroundColor Green
    }
    else {
        $failCount++
        $results += "❌ Android Build: FALLÓ"
        Write-Host "❌ Android Build falló" -ForegroundColor Red
    }
}
catch {
    $failCount++
    $results += "❌ Android Build: ERROR - $($_.Exception.Message)"
    Write-Host "❌ Error en Android Build: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# =============================================================================
# BUILD WEB
# =============================================================================
Write-Host "🌐 INICIANDO BUILD WEB..." -ForegroundColor Blue
$webScript = Join-Path $scriptsDir "build-web.ps1"

try {
    if ($Deploy) {
        & $webScript -Deploy
    }
    else {
        & $webScript
    }

    if ($LASTEXITCODE -eq 0) {
        $successCount++
        if ($Deploy) {
            $results += "✅ Web Build + Deploy: EXITOSO"
        }
        else {
            $results += "✅ Web Build: EXITOSO"
        }
        Write-Host "✅ Web Build completado" -ForegroundColor Green
    }
    else {
        $failCount++
        if ($Deploy) {
            $results += "❌ Web Build + Deploy: FALLÓ"
        }
        else {
            $results += "❌ Web Build: FALLÓ"
        }
        Write-Host "❌ Web Build falló" -ForegroundColor Red
    }
}
catch {
    $failCount++
    $results += "❌ Web Build: ERROR - $($_.Exception.Message)"
    Write-Host "❌ Error en Web Build: $($_.Exception.Message)" -ForegroundColor Red
}

# =============================================================================
# RESUMEN FINAL
# =============================================================================
Write-Host ""
Write-Host "🎯 RESUMEN FINAL DE BUILDS" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host "✅ Exitosos: $successCount" -ForegroundColor Green
Write-Host "❌ Fallidos: $failCount" -ForegroundColor Red
Write-Host ""

foreach ($result in $results) {
    Write-Host "   $result"
}

Write-Host ""

if ($successCount -eq 3) {
    Write-Host "🎉 ¡TODOS LOS BUILDS COMPLETADOS EXITOSAMENTE!" -ForegroundColor Green
    Write-Host "📁 Builds disponibles en: $buildsDir" -ForegroundColor Gray

    if ($Deploy) {
        Write-Host "🌐 Web desplegado en Vercel" -ForegroundColor Blue
    }
}
else {
    Write-Host "⚠️  Algunos builds fallaron. Revisa los logs anteriores." -ForegroundColor Yellow

    if ($failCount -gt 0) {
        Write-Host ""
        Write-Host "💡 CONSEJOS PARA SOLUCIONAR PROBLEMAS:" -ForegroundColor Cyan
        Write-Host "   • Windows: Verificar que Godot esté en PATH" -ForegroundColor White
        Write-Host "   • Android: Configurar Android SDK y export templates" -ForegroundColor White
        Write-Host "   • Web: Verificar export presets y configuración UTF-8" -ForegroundColor White
    }
}

Write-Host ""

# Retornar código de salida apropiado
if ($failCount -eq 0) {
    exit 0
}
else {
    exit 1
}
