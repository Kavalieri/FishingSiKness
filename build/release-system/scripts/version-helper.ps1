# 🔧 Version Management Helper - FishingSiKness
# Script de utilidad para gestionar versiones fácilmente

param(
    [ValidateSet("show", "sync", "set", "test")]
    [string]$Action = "show",
    [string]$Version = "",
    [switch]$Force,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$syncScriptPath = Join-Path $PSScriptRoot "sync-version.ps1"

function Show-CurrentVersion {
    Write-Host "📋 Estado Actual de Versión" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor Cyan

    # Obtener versión desde SplashScreen
    $splashPath = Join-Path (Split-Path -Parent $PSScriptRoot | Split-Path -Parent | Split-Path -Parent) "project\src\views\SplashScreen.gd"
    if (Test-Path $splashPath) {
        $content = Get-Content $splashPath -Raw
        $versionMatch = [regex]::Match($content, 'version_label\.text\s*=\s*"([^"]*)"')
        if ($versionMatch.Success) {
            Write-Host "🎮 En SplashScreen: " -NoNewline -ForegroundColor Yellow
            Write-Host $versionMatch.Groups[1].Value -ForegroundColor Green
        }
    }

    # Obtener versión desde Git
    try {
        $gitTag = git describe --tags --abbrev=0 2>$null
        if ($gitTag) {
            Write-Host "🏷️  Git Tag actual: " -NoNewline -ForegroundColor Yellow
            Write-Host $gitTag -ForegroundColor Green
        }
    } catch {
        Write-Host "🏷️  Git Tag: " -NoNewline -ForegroundColor Yellow
        Write-Host "No disponible" -ForegroundColor Gray
    }

    # Intentar GitHub API
    try {
        $apiUrl = "https://api.github.com/repos/Kavalieri/FishingSiKness/releases/latest"
        $response = Invoke-RestMethod -Uri $apiUrl -Headers @{
            "User-Agent" = "FishingSiKness-Version-Helper"
            "Accept" = "application/vnd.github.v3+json"
        } -TimeoutSec 10
        Write-Host "🌐 GitHub Release: " -NoNewline -ForegroundColor Yellow
        Write-Host $response.tag_name -ForegroundColor Green
        if ($response.prerelease) {
            Write-Host "   └─ Es pre-release" -ForegroundColor Gray
        }
    } catch {
        Write-Host "🌐 GitHub Release: " -NoNewline -ForegroundColor Yellow
        Write-Host "No accesible" -ForegroundColor Gray
    }
}

function Sync-Version {
    Write-Host "🔄 Sincronizando versión..." -ForegroundColor Cyan

    $params = @()
    if ($Force) { $params += "-Force" }
    if ($Verbose) { $params += "-Verbose" }

    try {
        if ($params.Count -gt 0) {
            & $syncScriptPath @params
        } else {
            & $syncScriptPath
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Sincronización completada" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Sincronización completada con advertencias" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Error en sincronización: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Set-CustomVersion {
    if (-not $Version) {
        Write-Host "❌ Debes especificar una versión con -Version" -ForegroundColor Red
        Write-Host "Ejemplo: .\version-helper.ps1 -Action set -Version 'v1.0.0'" -ForegroundColor Gray
        return
    }

    Write-Host "🎯 Estableciendo versión personalizada: $Version" -ForegroundColor Cyan

    $params = @("-CustomVersion", $Version)
    if ($Force) { $params += "-Force" }
    if ($Verbose) { $params += "-Verbose" }

    try {
        & $syncScriptPath @params

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Versión personalizada establecida" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Versión establecida con advertencias" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Error al establecer versión: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Test-VersionSystem {
    Write-Host "🧪 Probando sistema de versionado..." -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan

    # Mostrar estado actual
    Show-CurrentVersion
    Write-Host ""

    # Probar sincronización dry-run
    Write-Host "🔄 Probando sincronización..." -ForegroundColor Yellow
    try {
        & $syncScriptPath -Verbose
        Write-Host "✅ Sistema de sincronización funcional" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error en sistema de sincronización: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "📊 Prueba completada" -ForegroundColor Cyan
}

# Main execution
switch ($Action.ToLower()) {
    "show" {
        Show-CurrentVersion
    }
    "sync" {
        Sync-Version
    }
    "set" {
        Set-CustomVersion
    }
    "test" {
        Test-VersionSystem
    }
    default {
        Write-Host "❓ Acción no reconocida: $Action" -ForegroundColor Red
        Write-Host ""
        Write-Host "Uso: .\version-helper.ps1 -Action <acción> [opciones]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Acciones disponibles:" -ForegroundColor Cyan
        Write-Host "  show    Mostrar estado actual de versiones" -ForegroundColor Gray
        Write-Host "  sync    Sincronizar con GitHub/Git tags" -ForegroundColor Gray
        Write-Host "  set     Establecer versión personalizada" -ForegroundColor Gray
        Write-Host "  test    Probar funcionamiento del sistema" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Ejemplos:" -ForegroundColor Yellow
        Write-Host "  .\version-helper.ps1 -Action show" -ForegroundColor Gray
        Write-Host "  .\version-helper.ps1 -Action sync -Verbose" -ForegroundColor Gray
        Write-Host "  .\version-helper.ps1 -Action set -Version 'v1.2.0-beta'" -ForegroundColor Gray
        Write-Host "  .\version-helper.ps1 -Action test" -ForegroundColor Gray
    }
}
