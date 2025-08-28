# Script de Verificación Pre-Build para Fishing SiKness
# Detecta problemas comunes que pueden causar errores de empaquetado

param(
    [switch]$Fix = $false
)

Write-Host "🔍 Fishing SiKness - Verificación Pre-Build" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

$ProjectPath = "E:\GitHub\Fishing-SiKness\project"
$ErrorCount = 0

# Función para reportar errores
function Report-Issue {
    param($Message, $Severity = "Error")

    $color = switch($Severity) {
        "Error" { "Red"; $script:ErrorCount++ }
        "Warning" { "Yellow" }
        "Info" { "Green" }
    }

    $icon = switch($Severity) {
        "Error" { "❌" }
        "Warning" { "⚠️ " }
        "Info" { "✅" }
    }

    Write-Host "$icon $Message" -ForegroundColor $color
}

# 1. Verificar archivos vacíos o corruptos
Write-Host "`n📁 1. Verificando integridad de archivos..." -ForegroundColor Yellow

$criticalPaths = @(
    "data\fish\*.tres",
    "data\zones\*.tres",
    "data\loot_tables\*.tres",
    "scenes\core\*.tscn",
    "scenes\ui\*.tscn"
)

Push-Location $ProjectPath

foreach ($pattern in $criticalPaths) {
    Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Length -eq 0) {
            Report-Issue "Archivo vacío: $($_.Name)" "Error"
            if ($Fix) {
                Write-Host "   🔧 Eliminando archivo vacío..." -ForegroundColor Blue
                Remove-Item $_.FullName -Force
            }
        } elseif ($_.Length -lt 50) {
            Report-Issue "Archivo sospechosamente pequeño: $($_.Name) ($($_.Length) bytes)" "Warning"
        }
    }
}

# 2. Verificar referencias rotas
Write-Host "`n🔗 2. Verificando referencias de recursos..." -ForegroundColor Yellow

# Buscar ExtResource que puedan estar rotos
$brokenRefs = Select-String -Path "**\*.tscn", "**\*.tres" -Pattern 'ExtResource\(".*"\)' |
    Where-Object { $_.Line -match 'path="([^"]*)"' } |
    ForEach-Object {
        $filePath = $_.Matches[0].Groups[1].Value
        $basePath = Split-Path $_.Filename -Parent
        $fullPath = Join-Path $basePath $filePath

        if (!(Test-Path $fullPath)) {
            [PSCustomObject]@{
                File = $_.Filename
                MissingResource = $filePath
                Line = $_.LineNumber
            }
        }
    }

if ($brokenRefs) {
    $brokenRefs | ForEach-Object {
        Report-Issue "Referencia rota en $($_.File):$($_.Line) -> $($_.MissingResource)" "Error"
    }
}

# 3. Verificar rutas absolutas problemáticas
Write-Host "`n🛣️  3. Verificando rutas absolutas..." -ForegroundColor Yellow

$absolutePaths = Select-String -Path "**\*.gd", "**\*.tscn", "**\*.tres" -Pattern '[A-Z]:\\|/home/|/Users/' -ErrorAction SilentlyContinue

if ($absolutePaths) {
    $absolutePaths | ForEach-Object {
        Report-Issue "Ruta absoluta encontrada en $($_.Filename):$($_.LineNumber)" "Warning"
    }
}

# 4. Verificar archivos user:// en proyecto
Write-Host "`n💾 4. Verificando archivos user:// en proyecto..." -ForegroundColor Yellow

if (Test-Path "user:\\" -ErrorAction SilentlyContinue) {
    Report-Issue "Directorio user:// encontrado en proyecto - puede causar problemas de empaquetado" "Warning"
}

# 5. Verificar autoloads críticos
Write-Host "`n🚀 5. Verificando autoloads críticos..." -ForegroundColor Yellow

$autoloads = @("Content", "Save", "SFX", "Experience", "WindowManager")
$projectGodot = Get-Content "project.godot" -Raw

foreach ($autoload in $autoloads) {
    if ($projectGodot -notmatch "$autoload=") {
        Report-Issue "Autoload faltante: $autoload" "Error"
    } else {
        # Verificar que el archivo existe
        $autoloadPath = ($projectGodot -split "`n" | Where-Object { $_ -match "$autoload=" } | Select-Object -First 1) -replace ".*=`"\*(.*)`"", '$1'
        if (!(Test-Path $autoloadPath)) {
            Report-Issue "Archivo de autoload no encontrado: $autoload -> $autoloadPath" "Error"
        }
    }
}

# 6. Verificar recursos de arte críticos
Write-Host "`n🎨 6. Verificando assets críticos..." -ForegroundColor Yellow

$criticalAssets = @(
    "art\fish\sardina.png",
    "art\fish\trucha.png",
    "art\env\beach.png",
    "icon.svg"
)

foreach ($asset in $criticalAssets) {
    if (!(Test-Path $asset)) {
        Report-Issue "Asset crítico faltante: $asset" "Error"
    }
}

# 7. Verificar exportación está configurada
Write-Host "`n📦 7. Verificando configuración de export..." -ForegroundColor Yellow

if (!(Test-Path "export_presets.cfg")) {
    Report-Issue "Archivo export_presets.cfg faltante" "Error"
} else {
    $exportPresets = Get-Content "export_presets.cfg" -Raw
    if ($exportPresets -notmatch "Windows Desktop - Release") {
        Report-Issue "Preset de export 'Windows Desktop - Release' no encontrado" "Warning"
    }
}

Pop-Location

# Resumen
Write-Host "`n📊 Resumen de Verificación:" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

if ($ErrorCount -eq 0) {
    Report-Issue "Proyecto listo para build prerelease" "Info"
    Write-Host "`n🚀 Para construir ejecutar: .\build-prerelease.ps1" -ForegroundColor Green
} else {
    Report-Issue "Se encontraron $ErrorCount errores que deben solucionarse" "Error"
    Write-Host "`n🔧 Para intentar correcciones automáticas ejecutar: .\verify-prerelease.ps1 -Fix" -ForegroundColor Yellow
}

exit $ErrorCount
