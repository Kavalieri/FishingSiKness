# 🧹 CLEAN BUILDS - FishingSiKness
# Limpieza de builds antiguos manteniendo los últimos N builds por plataforma

param(
    [int]$KeepLast = 5,
    [string]$Platform = "all",
    [switch]$DryRun
)

Write-Host "🧹 FishingSiKness - Clean Builds" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "💡 Manteniendo últimos $KeepLast builds por plataforma" -ForegroundColor Yellow

$BuildDir = Resolve-Path (Join-Path $PSScriptRoot "..\..\builds")
$platforms = @()

# Determinar plataformas a limpiar
switch ($Platform) {
    "all" { $platforms = @("windows", "android", "web") }
    default { $platforms = @($Platform) }
}

foreach ($platformName in $platforms) {
    $platformDir = Join-Path $BuildDir $platformName

    if (-not (Test-Path $platformDir)) {
        Write-Host "⚠️  Plataforma '$platformName' no encontrada" -ForegroundColor Yellow
        continue
    }

    Write-Host "`n📁 Limpiando builds de $platformName..." -ForegroundColor Cyan

    # Obtener directorios ordenados por fecha de creación (más recientes primero)
    $buildDirs = Get-ChildItem $platformDir -Directory |
                 Where-Object { $_.Name -match '\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}' } |
                 Sort-Object CreationTime -Descending

    $totalBuilds = $buildDirs.Count
    $toDelete = $buildDirs | Select-Object -Skip $KeepLast

    Write-Host "   📊 Total builds: $totalBuilds" -ForegroundColor Gray
    Write-Host "   🔒 Manteniendo: $KeepLast" -ForegroundColor Green
    Write-Host "   🗑️  Para eliminar: $($toDelete.Count)" -ForegroundColor Red

    if ($toDelete.Count -eq 0) {
        Write-Host "   ✨ No hay builds antiguos para eliminar" -ForegroundColor Green
        continue
    }

    foreach ($dir in $toDelete) {
        $dirSize = (Get-ChildItem $dir.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum
        $sizeInMB = [math]::Round($dirSize / 1MB, 2)

        if ($DryRun) {
            Write-Host "   [DRY RUN] Eliminaría: $($dir.Name) ($sizeInMB MB)" -ForegroundColor Yellow
        } else {
            Write-Host "   🗑️  Eliminando: $($dir.Name) ($sizeInMB MB)" -ForegroundColor Red
            Remove-Item $dir.FullName -Recurse -Force
        }
    }
}

if ($DryRun) {
    Write-Host "`n💡 Ejecuta sin -DryRun para aplicar los cambios" -ForegroundColor Yellow
} else {
    Write-Host "`n✅ Limpieza completada" -ForegroundColor Green
}
