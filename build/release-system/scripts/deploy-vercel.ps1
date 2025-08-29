# FishingSiKness - Deploy Vercel
# Despliega el build web a Vercel con manejo de errores y logs

param(
    [switch]$Production = $false,  # Deploy a producción (por defecto preview)
    [switch]$Open = $false,        # Abrir URL después del deploy
    [string]$BuildDir = "",        # Directorio específico de build (opcional)
    [switch]$SkipBuild = $false    # Saltar build y usar último disponible
)

# Configuración
$RootDir = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
if (-not $BuildDir) {
    $BuildDir = Join-Path $RootDir "build\builds\web\latest"
}

# Colores para output
function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Info { param($Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host $Message -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host $Message -ForegroundColor Red }

# Header
Write-Host ""
Write-Host "🚀 FishingSiKness - Deploy Vercel" -ForegroundColor Magenta
Write-Host "===============================" -ForegroundColor Magenta
Write-Host "📅 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
if ($Production) {
    Write-Host "🎯 Modo: PRODUCCIÓN" -ForegroundColor Red
}
else {
    Write-Host "🔍 Modo: PREVIEW" -ForegroundColor Yellow
}
Write-Host ""

try {
    # Verificar que Vercel CLI esté disponible
    $vercelCheck = try { & vercel --version 2>$null } catch { $null }
    if (-not $vercelCheck) {
        Write-Error "❌ Vercel CLI no encontrado. Instala con: npm install -g vercel"
        exit 1
    }
    Write-Info "✅ Vercel CLI: $($vercelCheck.Split("`n")[0])"

    # Verificar login
    Write-Info "🔍 Verificando login en Vercel..."
    $whoamiOutput = try {
        Write-Host "   ⏳ Ejecutando: vercel whoami" -ForegroundColor Gray
        & vercel whoami 2>&1
    }
    catch {
        Write-Error "   ❌ Error ejecutando vercel whoami: $($_.Exception.Message)"
        $null
    }

    Write-Host "   📋 Output de whoami:" -ForegroundColor Gray
    if ($whoamiOutput) {
        $whoamiOutput | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
    }
    else {
        Write-Host "      (vacío o null)" -ForegroundColor DarkGray
    }

    if (-not $whoamiOutput -or ($whoamiOutput -is [array] -and $whoamiOutput -match "Error")) {
        Write-Error "❌ No estás logueado en Vercel. Ejecuta: vercel login"
        exit 1
    }

    # Extraer username del output
    Write-Info "🔍 Procesando información del usuario..."
    $username = "desconocido"
    if ($whoamiOutput -is [array]) {
        # La segunda línea suele ser el username
        if ($whoamiOutput.Count -ge 2) {
            $username = $whoamiOutput[1].Trim()
        }
    }
    else {
        $username = $whoamiOutput.Trim()
    }
    Write-Info "👤 Usuario: $username"

    # Verificar que existe el directorio de build
    if (-not (Test-Path $BuildDir)) {
        if ($SkipBuild) {
            Write-Error "❌ No se encontró build en: $BuildDir"
            Write-Warning "💡 Ejecuta primero: .\build-web.ps1"
            exit 1
        }
        else {
            Write-Warning "⚠️ No se encontró build, ejecutando build web..."
            $buildScript = Join-Path $PSScriptRoot "build-web.ps1"
            & $buildScript
            if (-not (Test-Path $BuildDir)) {
                Write-Error "❌ Build falló. No se puede continuar con deploy."
                exit 1
            }
        }
    }

    # Verificar archivos esenciales
    $indexPath = Join-Path $BuildDir "index.html"
    $wasmPath = Join-Path $BuildDir "index.wasm"
    $pckPath = Join-Path $BuildDir "index.pck"

    if (-not (Test-Path $indexPath) -or -not (Test-Path $wasmPath) -or -not (Test-Path $pckPath)) {
        Write-Error "❌ Build incompleto. Faltan archivos esenciales."
        Write-Info "💡 Archivos requeridos: index.html, index.wasm, index.pck"
        exit 1
    }

    # Información del build
    $buildFiles = Get-ChildItem $BuildDir -File
    $totalSize = ($buildFiles | Measure-Object -Property Length -Sum).Sum
    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)

    Write-Info "📦 Build encontrado:"
    Write-Host "   📍 Ubicación: $BuildDir" -ForegroundColor Gray
    Write-Host "   📏 Tamaño total: $totalSizeMB MB" -ForegroundColor Gray
    Write-Host "   📄 Archivos: $($buildFiles.Count)" -ForegroundColor Gray

    # Cambiar al directorio de build para el deploy
    Write-Info "📁 Cambiando al directorio de build para deploy..."
    Push-Location $BuildDir

    Write-Info "`n🚀 Iniciando deploy desde directorio de build..."

    # Preparar comando de deploy
    $deployArgs = @()
    $deployArgs += "--yes"  # No preguntar confirmaciones
    $deployArgs += "--cwd"  # Especificar directorio actual
    $deployArgs += $RootDir  # Usar directorio raíz para configuración .vercel

    if ($Production) {
        $deployArgs += "--prod"
        Write-Info "🎯 Desplegando a PRODUCCIÓN..."
    }
    else {
        Write-Info "🔍 Desplegando PREVIEW..."
    }

    # Ejecutar deploy
    Write-Info "⏳ Ejecutando: vercel $($deployArgs -join ' ')"
    Write-Host "   📍 Directorio actual: $(Get-Location)" -ForegroundColor Gray
    Write-Host "   📍 Directorio de configuración: $RootDir" -ForegroundColor Gray

    # Usar Start-Process para mejor control del proceso
    $processArgs = $deployArgs -join ' '
    Write-Host "   🔧 Comando completo: vercel $processArgs" -ForegroundColor Gray

    # Usar & para ejecutar comandos de PowerShell correctamente
    try {
        $deployOutput = & vercel @deployArgs 2>&1
        $deployExitCode = $LASTEXITCODE
    }
    catch {
        Write-Error "Error ejecutando vercel: $($_.Exception.Message)"
        $deployExitCode = 1
        $deployOutput = @("Error: $($_.Exception.Message)")
    }

    Write-Host "   📋 Código de salida: $deployExitCode" -ForegroundColor Gray
    Write-Host "   📋 Output completo:" -ForegroundColor Gray
    $deployOutput | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }    if ($deployExitCode -ne 0) {
        Write-Error "❌ Deploy falló (código: $deployExitCode)"
        Write-Error "💬 Output:"
        $deployOutput | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
        exit 1
    }

    # Extraer URL del deploy
    $deployUrl = ""
    $deployOutput | ForEach-Object {
        if ($_ -match "https://.*\.vercel\.app") {
            $deployUrl = $matches[0]
        }
    }

    if ($deployUrl) {
        Write-Success "`n✅ DEPLOY EXITOSO!"
        Write-Host "🌐 URL: $deployUrl" -ForegroundColor Green

        if ($Production) {
            Write-Host "🎯 Deploy de PRODUCCIÓN completado" -ForegroundColor Green
        }
        else {
            Write-Host "🔍 Deploy PREVIEW completado" -ForegroundColor Yellow
        }

        # Información adicional
        Write-Info "`n📊 INFORMACIÓN:"
        Write-Host "   📦 Tamaño: $totalSizeMB MB" -ForegroundColor Gray
        Write-Host "   ⏱️  Tiempo: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
        Write-Host "   🌍 CDN: Global (Vercel Edge Network)" -ForegroundColor Gray

        # Abrir navegador si se solicita
        if ($Open) {
            Write-Info "🔗 Abriendo en navegador..."
            Start-Process $deployUrl
        }

        Write-Info "`n💡 SIGUIENTE PASO:"
        Write-Host "   🎮 Prueba tu juego en: $deployUrl" -ForegroundColor White

        if (-not $Production) {
            Write-Host "   🚀 Para producción: .\deploy-vercel.ps1 -Production" -ForegroundColor White
        }

    }
    else {
        Write-Warning "⚠️ Deploy completado pero no se pudo extraer la URL"
        Write-Host "💬 Output completo:" -ForegroundColor Yellow
        $deployOutput | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
    }

}
catch {
    Write-Error "❌ Error inesperado durante el deploy:"
    Write-Error $_.Exception.Message
    exit 1
}
finally {
    # Volver al directorio original
    Pop-Location
}

Write-Host "`n🚀 DEPLOY VERCEL COMPLETADO!" -ForegroundColor Magenta
