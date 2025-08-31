# 🔄 Automatización de Versionado para Builds
# Sincroniza la versión mostrada en SplashScreen con la última release de GitHub

param(
    [switch]$Force,
    [switch]$Verbose,
    [string]$CustomVersion = ""
)

# Configuración
$ErrorActionPreference = "Stop"
$RepoOwner = "Kavalieri"
$RepoName = "FishingSiKness"
$SplashScreenPath = "project/src/views/SplashScreen.gd"
$ProjectRoot = Split-Path -Parent $PSScriptRoot | Split-Path -Parent | Split-Path -Parent

function Write-Info {
    param($Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Success {
    param($Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Get-LatestGitHubRelease {
    try {
        Write-Info "Obteniendo última release de GitHub..."
        $apiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/releases/latest"
        $response = Invoke-RestMethod -Uri $apiUrl -Headers @{
            "User-Agent" = "FishingSiKness-Build-System"
            "Accept"     = "application/vnd.github.v3+json"
        }

        $version = $response.tag_name
        $isPrerelease = $response.prerelease

        if ($Verbose) {
            Write-Info "Release encontrada: $version"
            Write-Info "Es pre-release: $isPrerelease"
            Write-Info "Fecha publicación: $($response.published_at)"
        }

        return @{
            Version      = $version
            IsPrerelease = $isPrerelease
            Name         = $response.name
            PublishedAt  = $response.published_at
        }
    }
    catch {
        Write-Warning "No se pudo obtener la release desde GitHub API: $($_.Exception.Message)"

        # Fallback: intentar obtener desde git tags local
        try {
            Write-Info "Intentando obtener versión desde git tags locales..."
            $gitTag = git describe --tags --abbrev=0 2>$null
            if ($gitTag) {
                Write-Info "Tag local encontrado: $gitTag"
                return @{
                    Version      = $gitTag
                    IsPrerelease = $gitTag -match "(alpha|beta|rc|pre)"
                    Name         = $gitTag
                    PublishedAt  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                }
            }
        }
        catch {
            Write-Warning "No se pudieron obtener tags locales: $($_.Exception.Message)"
        }

        # Último fallback: versión por defecto
        Write-Warning "Usando versión por defecto"
        return @{
            Version      = "v0.1.0"
            IsPrerelease = $true
            Name         = "v0.1.0 (default)"
            PublishedAt  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
    }
}

function Get-CurrentVersionFromSplash {
    $splashPath = Join-Path $ProjectRoot $SplashScreenPath

    if (-not (Test-Path $splashPath)) {
        throw "No se encontró el archivo SplashScreen.gd en: $splashPath"
    }

    $content = Get-Content $splashPath -Raw
    $versionMatch = [regex]::Match($content, 'version_label\.text\s*=\s*"([^"]*)"')

    if ($versionMatch.Success) {
        return $versionMatch.Groups[1].Value
    }

    return $null
}

function Update-SplashScreenVersion {
    param(
        [string]$NewVersion,
        [bool]$IsPrerelease
    )

    $splashPath = Join-Path $ProjectRoot $SplashScreenPath

    if (-not (Test-Path $splashPath)) {
        throw "No se encontró el archivo SplashScreen.gd en: $splashPath"
    }

    # Crear el texto de versión formateado
    if ($IsPrerelease) {
        # Detectar el tipo de pre-release desde la versión
        $prereleaseType = ""
        if ($NewVersion -match "(alpha|beta|rc|pre)") {
            $prereleaseType = $matches[1]
        }
        else {
            $prereleaseType = "alpha"  # default fallback
        }
        $versionSuffix = " pre-release"
    }
    else {
        $versionSuffix = ""
    }
    $newVersionText = "Fishing SiKness $NewVersion$versionSuffix"

    # Leer el contenido del archivo
    $content = Get-Content $splashPath -Raw

    # Hacer el reemplazo
    $pattern = '(version_label\.text\s*=\s*")[^"]*(")'
    $replacement = "`${1}$newVersionText`${2}"
    $newContent = [regex]::Replace($content, $pattern, $replacement)

    # Verificar que se hizo el reemplazo
    if ($content -eq $newContent) {
        throw "No se pudo actualizar la versión en SplashScreen.gd. Patrón no encontrado."
    }

    # Guardar el archivo
    $newContent | Set-Content $splashPath -NoNewline
    Write-Success "Versión actualizada en SplashScreen.gd: '$newVersionText'"

    return $newVersionText
}

function Main {
    Write-Info "🔄 Iniciando sincronización de versión..."
    Write-Info "Repositorio: $RepoOwner/$RepoName"
    Write-Info "Directorio: $ProjectRoot"

    try {
        # Obtener versión actual del splash
        $currentVersion = Get-CurrentVersionFromSplash
        Write-Info "Versión actual en splash: '$currentVersion'"

        # Usar versión personalizada si se especifica
        if ($CustomVersion) {
            Write-Info "Usando versión personalizada: $CustomVersion"
            $releaseInfo = @{
                Version      = $CustomVersion
                IsPrerelease = $CustomVersion -match "(alpha|beta|rc|pre)"
                Name         = $CustomVersion
                PublishedAt  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            }
        }
        else {
            # Obtener última release de GitHub
            $releaseInfo = Get-LatestGitHubRelease
        }

        $latestVersion = $releaseInfo.Version
        Write-Info "Versión objetivo: $latestVersion"

        # Verificar si necesita actualización
        $needsUpdate = $Force -or (-not $currentVersion) -or ($currentVersion -notlike "*$latestVersion*")

        if ($needsUpdate) {
            Write-Info "Actualizando versión..."
            $updatedText = Update-SplashScreenVersion -NewVersion $latestVersion -IsPrerelease $releaseInfo.IsPrerelease

            Write-Success "🎉 Versión sincronizada exitosamente!"
            Write-Success "Texto final: '$updatedText'"

            return @{
                Success     = $true
                OldVersion  = $currentVersion
                NewVersion  = $latestVersion
                UpdatedText = $updatedText
            }
        }
        else {
            Write-Success "✨ La versión ya está actualizada"
            return @{
                Success        = $true
                OldVersion     = $currentVersion
                NewVersion     = $latestVersion
                UpdatedText    = $currentVersion
                NoUpdateNeeded = $true
            }
        }
    }
    catch {
        Write-Error "Error durante la sincronización: $($_.Exception.Message)"
        if ($Verbose) {
            Write-Error "Stack trace: $($_.Exception.StackTrace)"
        }
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}

# Ejecutar si se invoca directamente
if ($MyInvocation.InvocationName -ne '.') {
    Write-Host "🎮 Fishing SiKness - Sincronizador de Versión" -ForegroundColor Magenta
    Write-Host "================================================" -ForegroundColor Magenta

    $result = Main

    if (-not $result.Success) {
        exit 1
    }

    if ($result.NoUpdateNeeded) {
        exit 0
    }

    Write-Host ""
    Write-Host "📋 Resumen:" -ForegroundColor Yellow
    Write-Host "  Versión anterior: $($result.OldVersion)" -ForegroundColor Gray
    Write-Host "  Versión nueva: $($result.NewVersion)" -ForegroundColor Green
    Write-Host "  Texto actualizado: '$($result.UpdatedText)'" -ForegroundColor Green

    exit 0
}
