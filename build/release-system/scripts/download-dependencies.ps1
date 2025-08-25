# 📦 DESCARGA VC++ REDISTRIBUTABLE - Bar-Sik
# Script para descargar automáticamente las dependencias necesarias

Write-Host "📦 Descargando Visual C++ Redistributable..." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan

$vcredistUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
$downloadDir = Join-Path $PSScriptRoot "..\..\builds\dependencies"
$vcredistPath = Join-Path $downloadDir "vc_redist.x64.exe"

# Crear directorio de dependencias
New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null

Write-Host "🌐 Descargando desde: $vcredistUrl" -ForegroundColor Cyan
Write-Host "📁 Guardando en: $vcredistPath" -ForegroundColor Cyan

try {
    # Descargar VC++ Redistributable
    Invoke-WebRequest -Uri $vcredistUrl -OutFile $vcredistPath -UseBasicParsing

    if (Test-Path $vcredistPath) {
        $fileInfo = Get-Item $vcredistPath
        Write-Host "`n✅ DESCARGA COMPLETADA!" -ForegroundColor Green
        Write-Host "📏 Tamaño: $([math]::Round($fileInfo.Length/1MB, 2)) MB" -ForegroundColor Cyan
        Write-Host "📁 Ubicación: $vcredistPath" -ForegroundColor Cyan

        Write-Host "`n💡 INSTRUCCIONES DE DISTRIBUCIÓN:" -ForegroundColor Yellow
        Write-Host "  1. Incluir vc_redist.x64.exe con tu juego" -ForegroundColor White
        Write-Host "  2. Instruir al usuario que ejecute primero vc_redist.x64.exe" -ForegroundColor White
        Write-Host "  3. Luego ya puede ejecutar bar-sik-standalone.exe" -ForegroundColor White

        Write-Host "`n📋 CONTENIDO EN builds/dependencies/:" -ForegroundColor Cyan
        Get-ChildItem $downloadDir | Format-Table Name, Length -AutoSize

    } else {
        Write-Host "`n❌ Error: No se pudo descargar el archivo" -ForegroundColor Red
    }
} catch {
    Write-Host "`n❌ Error durante la descarga: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Descarga manual desde: $vcredistUrl" -ForegroundColor Yellow
}

Write-Host "`n🎯 Dependencies setup completado!" -ForegroundColor Green
