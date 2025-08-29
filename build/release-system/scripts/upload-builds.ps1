# =============================================================================
# FishingSiKness - Upload Builds to Latest Release
# =============================================================================
# Sube automáticamente los builds más recientes al último release de GitHub
# Reemplaza archivos existentes si ya están presentes
# =============================================================================

param(
    [string]$ReleaseTag,  # Tag específico del release (opcional)
    [switch]$DryRun       # Solo mostrar qué se haría sin ejecutar
)

# Configuración
$rootDir = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName
$buildsDir = Join-Path $rootDir "build\builds"

Write-Host "🚀 FishingSiKness - Upload Builds to Release" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "📁 Proyecto: $rootDir" -ForegroundColor Gray
Write-Host ""

# Verificar que gh CLI está disponible
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ GitHub CLI (gh) no está instalado o no está en PATH" -ForegroundColor Red
    Write-Host "💡 Instala GitHub CLI desde: https://cli.github.com/" -ForegroundColor Yellow
    exit 1
}

# Obtener el release más reciente si no se especifica tag
if (-not $ReleaseTag) {
    try {
        Write-Host "🔍 Obteniendo el release más reciente..." -ForegroundColor Yellow
        $latestRelease = gh release list --limit 1 --json tagName | ConvertFrom-Json
        if ($latestRelease -and $latestRelease.Count -gt 0) {
            $ReleaseTag = $latestRelease[0].tagName
            Write-Host "📦 Release encontrado: $ReleaseTag" -ForegroundColor Green
        }
        else {
            Write-Host "❌ No se encontraron releases en el repositorio" -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Host "❌ Error obteniendo releases: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "📦 Usando release especificado: $ReleaseTag" -ForegroundColor Green
}

# Verificar que el release existe
try {
    $releaseInfo = gh release view $ReleaseTag --json tagName, name, url
    Write-Host "✅ Release verificado: $($releaseInfo.name)" -ForegroundColor Green
    Write-Host "🔗 URL: $($releaseInfo.url)" -ForegroundColor Gray
}
catch {
    Write-Host "❌ El release '$ReleaseTag' no existe" -ForegroundColor Red
    exit 1
}

Write-Host ""

# =============================================================================
# BUSCAR BUILDS RECIENTES
# =============================================================================
$buildFiles = @()

# Windows builds
$windowsLatest = Join-Path $buildsDir "windows\latest"
if (Test-Path $windowsLatest) {
    $windowsFiles = Get-ChildItem $windowsLatest -File -Filter "*.exe"
    foreach ($file in $windowsFiles) {
        $buildFiles += @{
            Path     = $file.FullName
            Name     = $file.Name
            Platform = "Windows"
            Size     = [math]::Round($file.Length / 1MB, 2)
        }
    }
}

# Android builds
$androidLatest = Join-Path $buildsDir "android\latest"
if (Test-Path $androidLatest) {
    $androidFiles = Get-ChildItem $androidLatest -File -Filter "*.apk"
    foreach ($file in $androidFiles) {
        $buildFiles += @{
            Path     = $file.FullName
            Name     = $file.Name
            Platform = "Android"
            Size     = [math]::Round($file.Length / 1MB, 2)
        }
    }
}

# Mostrar archivos encontrados
Write-Host "📋 BUILDS ENCONTRADOS:" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

if ($buildFiles.Count -eq 0) {
    Write-Host "❌ No se encontraron builds en los directorios 'latest'" -ForegroundColor Red
    Write-Host "💡 Ejecuta primero los scripts de build para generar archivos" -ForegroundColor Yellow
    exit 1
}

foreach ($build in $buildFiles) {
    Write-Host "   📦 $($build.Name) [$($build.Platform)] - $($build.Size) MB" -ForegroundColor White
}

Write-Host ""

# =============================================================================
# SUBIR ARCHIVOS AL RELEASE
# =============================================================================
if ($DryRun) {
    Write-Host "🔍 MODO DRY-RUN - No se subirán archivos" -ForegroundColor Yellow
    Write-Host "Los siguientes comandos se ejecutarían:" -ForegroundColor Yellow
    Write-Host ""

    foreach ($build in $buildFiles) {
        Write-Host "   gh release upload $ReleaseTag `"$($build.Path)`" --clobber" -ForegroundColor Gray
    }
    Write-Host ""
    exit 0
}

Write-Host "📤 SUBIENDO BUILDS AL RELEASE..." -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta

$uploadSuccess = 0
$uploadFailed = 0
$uploadResults = @()

foreach ($build in $buildFiles) {
    Write-Host "📤 Subiendo $($build.Name)..." -ForegroundColor Yellow

    try {
        $uploadCmd = "gh release upload $ReleaseTag `"$($build.Path)`" --clobber"
        Invoke-Expression $uploadCmd

        if ($LASTEXITCODE -eq 0) {
            $uploadSuccess++
            $uploadResults += "✅ $($build.Name) - EXITOSO"
            Write-Host "   ✅ $($build.Name) subido correctamente" -ForegroundColor Green
        }
        else {
            $uploadFailed++
            $uploadResults += "❌ $($build.Name) - FALLÓ (código: $LASTEXITCODE)"
            Write-Host "   ❌ Error subiendo $($build.Name)" -ForegroundColor Red
        }
    }
    catch {
        $uploadFailed++
        $uploadResults += "❌ $($build.Name) - ERROR: $($_.Exception.Message)"
        Write-Host "   ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# =============================================================================
# RESUMEN FINAL
# =============================================================================
Write-Host ""
Write-Host "🎯 RESUMEN DE UPLOAD" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host "📦 Release: $ReleaseTag" -ForegroundColor White
Write-Host "✅ Exitosos: $uploadSuccess" -ForegroundColor Green
Write-Host "❌ Fallidos: $uploadFailed" -ForegroundColor Red
Write-Host ""

foreach ($result in $uploadResults) {
    Write-Host "   $result"
}

Write-Host ""

if ($uploadSuccess -gt 0) {
    Write-Host "🎉 ¡Builds subidos exitosamente!" -ForegroundColor Green
    Write-Host "🔗 Ver release: https://github.com/Kavalieri/FishingSiKness/releases/tag/$ReleaseTag" -ForegroundColor Blue
}

if ($uploadFailed -gt 0) {
    Write-Host "⚠️  Algunos uploads fallaron. Revisa los logs anteriores." -ForegroundColor Yellow
    exit 1
}
else {
    exit 0
}
