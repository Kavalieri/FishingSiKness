# 🧹 LIMPIAR BUILDS ANTIGUOS - Bar-Sik
param(
    [int]$Keep = 3,
    [switch]$KeepOnlyLatest,
    [string]$Platform = "all",
    [switch]$DryRun
)

Write-Host "🧹 Bar-Sik - Limpiar Builds Antiguos" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "🔍 MODO DRY-RUN - Solo mostrar qué se eliminaría" -ForegroundColor Yellow
}

$BuildsDir = Join-Path $PSScriptRoot "builds"

if (-not (Test-Path $BuildsDir)) {
    Write-Host "❌ No se encontró directorio de builds" -ForegroundColor Red
    exit
}

$platforms = @("windows", "web", "android", "linux")
if ($Platform -ne "all") {
    $platforms = @($Platform)
}

$totalCleaned = 0
$totalSize = 0

foreach ($plat in $platforms) {
    $platDir = Join-Path $BuildsDir $plat

    if (-not (Test-Path $platDir)) {
        continue
    }

    Write-Host "`n🖥️ Procesando $($plat.ToUpper())" -ForegroundColor Cyan

    # Obtener directorios timestamped (excluyendo 'latest')
    $timestampDirs = Get-ChildItem $platDir -Directory | Where-Object { $_.Name -ne "latest" } | Sort-Object Name -Descending

    if ($timestampDirs.Count -eq 0) {
        Write-Host "   No hay builds timestamped" -ForegroundColor Gray
        continue
    }

    $toDelete = @()

    if ($KeepOnlyLatest) {
        $toDelete = $timestampDirs
        Write-Host "   Manteniendo solo 'latest', eliminando $($toDelete.Count) builds" -ForegroundColor Yellow
    } elseif ($timestampDirs.Count -gt $Keep) {
        $toDelete = $timestampDirs | Select-Object -Skip $Keep
        Write-Host "   Manteniendo últimos $Keep builds, eliminando $($toDelete.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "   Solo hay $($timestampDirs.Count) builds (menor o igual a $Keep), no se elimina nada" -ForegroundColor Green
        continue
    }

    foreach ($dir in $toDelete) {
        try {
            # Calcular tamaño antes de eliminar
            $dirSize = (Get-ChildItem $dir.FullName -Recurse -File | Measure-Object Length -Sum).Sum
            $dirSizeMB = [math]::Round($dirSize / 1MB, 2)

            if ($DryRun) {
                Write-Host "   🗑️ Se eliminaría: $($dir.Name) ($dirSizeMB MB)" -ForegroundColor Red
            } else {
                Write-Host "   🗑️ Eliminando: $($dir.Name) ($dirSizeMB MB)" -ForegroundColor Red
                Remove-Item $dir.FullName -Recurse -Force
                Write-Host "   ✅ Eliminado correctamente" -ForegroundColor Green
            }

            $totalCleaned++
            $totalSize += $dirSize
        } catch {
            Write-Host "   ❌ Error eliminando $($dir.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

$totalSizeMB = [math]::Round($totalSize / 1MB, 2)

Write-Host "`n📊 RESUMEN DE LIMPIEZA" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "Se eliminarían: $totalCleaned builds" -ForegroundColor Yellow
    Write-Host "Espacio liberado: $totalSizeMB MB" -ForegroundColor Yellow
    Write-Host "`n🚀 Para ejecutar realmente: quita el parámetro -DryRun" -ForegroundColor White
} else {
    Write-Host "Builds eliminados: $totalCleaned" -ForegroundColor White
    Write-Host "Espacio liberado: $totalSizeMB MB" -ForegroundColor White

    if ($totalCleaned -gt 0) {
        Write-Host "`n✅ Limpieza completada exitosamente" -ForegroundColor Green
    } else {
        Write-Host "`n💡 No había builds que limpiar" -ForegroundColor Cyan
    }
}

Write-Host "`n📜 Ver historial actualizado:" -ForegroundColor Gray
Write-Host "   .\build-history.ps1" -ForegroundColor White
