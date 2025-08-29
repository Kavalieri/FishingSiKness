# 🌐 BUILD WEB - FishingSiKness (HTML5 + WebAssembly)
param(
    [string]$Version = "0.2.1-alpha",
    [switch]$Serve,
    [int]$Port = 8080,
    [switch]$Open,
    [switch]$Deploy          # Deployar automáticamente a Vercel producción
)

Write-Host "🌐 FishingSiKness - Build Web v$Version" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Cyan

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
function New-WebTimestampedDir {
    param($Timestamp)

    $webDir = Join-Path $BuildDir "web"
    $timestampDir = Join-Path $webDir $Timestamp

    New-Item -ItemType Directory -Force -Path $timestampDir | Out-Null

    return $timestampDir
}

# Función para actualizar directorio latest
function Update-LatestDir {
    param($TimestampDir)

    $webDir = Split-Path $TimestampDir -Parent
    $latestDir = Join-Path $webDir "latest"

    if (Test-Path $latestDir) {
        Remove-Item $latestDir -Force -Recurse -ErrorAction SilentlyContinue
    }

    try {
        New-Item -ItemType SymbolicLink -Path $latestDir -Target $TimestampDir -ErrorAction Stop | Out-Null
        Write-Host "   🔗 Symlink 'latest' creado" -ForegroundColor Gray
    }
    catch {
        Copy-Item $TimestampDir $latestDir -Recurse -Force
        Write-Host "   📁 Directorio 'latest' copiado" -ForegroundColor Gray
    }

    # Copiar archivos de configuración para deploy
    Copy-ConfigFiles $latestDir
}

# Función para copiar archivos de configuración al directorio de build
function Copy-ConfigFiles {
    param($TargetDir)

    # Obtener directorio raíz del proyecto (3 niveles arriba desde scripts/)
    $rootDir = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName
    $vercelFile = Join-Path $rootDir "vercel.json"

    if (Test-Path $vercelFile) {
        Copy-Item $vercelFile $TargetDir -Force
        Write-Host "   ⚙️ vercel.json copiado para configuración UTF-8" -ForegroundColor Gray
    }
    else {
        Write-Host "   ⚠️ vercel.json no encontrado en $rootDir" -ForegroundColor Yellow
    }
}

$timestampDir = New-WebTimestampedDir $timestamp

# BUILD WEB (HTML5 + WebAssembly)
Write-Host "`n🌐 COMPILANDO WEB (HTML5 + WebAssembly)..." -ForegroundColor Cyan
$webIndexPath = Join-Path $timestampDir "index.html"
Write-Host "Output: $webIndexPath" -ForegroundColor Gray

# Configurar template HTML personalizado para UTF-8/emojis
$customShellPath = Join-Path $ProjectRoot "custom_shell.html"
if (Test-Path $customShellPath) {
    Write-Host "   🎨 Usando template HTML personalizado para UTF-8/emojis" -ForegroundColor Gray
}
else {
    Write-Host "   ⚠️ Template HTML personalizado no encontrado en: $customShellPath" -ForegroundColor Yellow
}

try {
    $arguments = '--path "' + $ProjectRoot + '" --headless --export-release "Web" "' + $webIndexPath + '"'
    Write-Host "Ejecutando: $GodotPath [args]" -ForegroundColor Gray

    $process = Start-Process -FilePath $GodotPath -ArgumentList $arguments.Split(' ', [StringSplitOptions]::RemoveEmptyEntries) -PassThru -Wait -NoNewWindow

    if ($process.ExitCode -eq 0 -and (Test-Path $webIndexPath)) {
        # Verificar archivos generados
        $webFiles = Get-ChildItem $timestampDir -File
        $totalSize = ($webFiles | Measure-Object -Property Length -Sum).Sum
        $totalSizeMB = [math]::Round($totalSize / 1MB, 2)

        Write-Host "✅ BUILD WEB exitoso!" -ForegroundColor Green
        Write-Host "📦 Archivos generados ($totalSizeMB MB):" -ForegroundColor White

        $webFiles | Sort-Object Name | ForEach-Object {
            $sizeMB = [math]::Round($_.Length / 1MB, 2)
            $icon = switch ($_.Extension) {
                ".html" { "🌐" }
                ".js" { "⚙️" }
                ".wasm" { "🔧" }
                ".pck" { "📦" }
                default { "📄" }
            }
            Write-Host "   $icon $($_.Name) ($sizeMB MB)" -ForegroundColor Gray
        }

        # Actualizar directorio latest
        Update-LatestDir $timestampDir

        # Información adicional
        Write-Host "`n🚀 LISTO PARA DESPLIEGUE WEB" -ForegroundColor Green
        Write-Host "📍 Ubicación: $timestampDir" -ForegroundColor Gray
        Write-Host "📂 Acceso rápido: builds\web\latest\" -ForegroundColor Gray
        Write-Host "🌍 Para probar: Servir desde un servidor HTTP" -ForegroundColor Yellow


        # Servidor local si se solicita
        if ($Serve) {
            Write-Host "`n�️ INICIANDO SERVIDOR LOCAL..." -ForegroundColor Cyan
            Write-Host "🌐 Servidor disponible en: http://localhost:$Port" -ForegroundColor Green
            Write-Host "⚠️  Presiona Ctrl+C para detener el servidor" -ForegroundColor Yellow

            # Abrir navegador si se solicita
            if ($Open) {
                Start-Process "http://localhost:$Port"
            }

            # Servidor Python simple
            Set-Location $timestampDir
            try {
                if (Get-Command "python" -ErrorAction SilentlyContinue) {
                    Write-Host "🐍 Usando Python HTTP Server" -ForegroundColor Gray
                    python -m http.server $Port
                }
                elseif (Get-Command "python3" -ErrorAction SilentlyContinue) {
                    Write-Host "🐍 Usando Python3 HTTP Server" -ForegroundColor Gray
                    python3 -m http.server $Port
                }
                else {
                    Write-Host "❌ Python no encontrado. Instala Python para servidor automático" -ForegroundColor Red
                    Write-Host "💡 Alternativa: Usar Live Server de VS Code" -ForegroundColor White
                }
            }
            finally {
                Set-Location $PSScriptRoot
            }
        }
        else {
            Write-Host "`n💡 Para probar localmente:" -ForegroundColor Cyan
            Write-Host "   .\build-web.ps1 -Serve -Open" -ForegroundColor White
            Write-Host "   O usar Live Server de VS Code" -ForegroundColor White
        }

    }
    else {
        Write-Host "❌ Error en Web build (código: $($process.ExitCode))" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "❌ Error ejecutando Web build: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Deploy automático a Vercel si se especifica
if ($Deploy) {
    Write-Host "`n🚀 Iniciando deploy a Vercel..." -ForegroundColor Cyan

    # Usar directorio "latest" para el deploy (ya configurado en Vercel)
    $webDir = Split-Path $timestampDir -Parent
    $latestDir = Join-Path $webDir "latest"

    $deployScript = Join-Path $PSScriptRoot "deploy-vercel-simple.ps1"

    if (Test-Path $deployScript) {
        try {
            & $deployScript -ProjectPath $latestDir -Prod
            Write-Host "✅ Deploy a Vercel completado exitosamente!" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Error durante el deploy: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "💡 Puedes hacer deploy manual con: .\deploy-vercel-simple.ps1 -ProjectPath `"$latestDir`" -Prod" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "❌ Script de deploy no encontrado: $deployScript" -ForegroundColor Red
        Write-Host "💡 Asegúrate de que deploy-vercel-simple.ps1 esté en la misma carpeta" -ForegroundColor Yellow
    }
}

Write-Host "`n🌐 BUILD WEB COMPLETADO!" -ForegroundColor Green

# Volver al directorio raíz del proyecto
Set-Location $RootDir

# Salir con código exitoso
exit 0
