# 🌐 BUILD WEB - Bar-Sik (HTML5 + WebAssembly)
param(
    [string]$Version = "0.3.0",
    [switch]$Serve,
    [int]$Port = 8080,
    [switch]$Open
)

Write-Host "🌐 Bar-Sik - Build Web v$Version" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Cyan

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ProjectRoot = "E:\GitHub\bar-sik\project"
$BuildDir = "E:\GitHub\bar-sik\builds"
$GodotPath = "E:\2- Descargas\Godot_v4.4.1-stable_win64.exe\Godot_v4.4.1-stable_win64.exe"

Write-Host "📅 Timestamp: $timestamp" -ForegroundColor Gray
Write-Host "📁 Proyecto: $ProjectRoot" -ForegroundColor Gray

# Verificaciones
if (-not (Test-Path $GodotPath)) {
    Write-Host "❌ Godot no encontrado en: $GodotPath" -ForegroundColor Red
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
    $latestDir = Join-Path $webDir "latest"

    New-Item -ItemType Directory -Force -Path $timestampDir | Out-Null

    if (Test-Path $latestDir) {
        Remove-Item $latestDir -Force -Recurse -ErrorAction SilentlyContinue
    }

    try {
        New-Item -ItemType SymbolicLink -Path $latestDir -Target $timestampDir -ErrorAction Stop | Out-Null
        Write-Host "   🔗 Symlink 'latest' creado" -ForegroundColor Gray
    } catch {
        Copy-Item $timestampDir $latestDir -Recurse -Force
        Write-Host "   📁 Directorio 'latest' copiado" -ForegroundColor Gray
    }

    return $timestampDir
}

$timestampDir = New-WebTimestampedDir $timestamp

# BUILD WEB (HTML5 + WebAssembly)
Write-Host "`n🌐 COMPILANDO WEB (HTML5 + WebAssembly)..." -ForegroundColor Cyan
$webIndexPath = Join-Path $timestampDir "index.html"
Write-Host "Output: $webIndexPath" -ForegroundColor Gray

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
                } elseif (Get-Command "python3" -ErrorAction SilentlyContinue) {
                    Write-Host "🐍 Usando Python3 HTTP Server" -ForegroundColor Gray
                    python3 -m http.server $Port
                } else {
                    Write-Host "❌ Python no encontrado. Instala Python para servidor automático" -ForegroundColor Red
                    Write-Host "💡 Alternativa: Usar Live Server de VS Code" -ForegroundColor White
                }
            } finally {
                Set-Location $PSScriptRoot
            }
        } else {
            Write-Host "`n💡 Para probar localmente:" -ForegroundColor Cyan
            Write-Host "   .\build-web.ps1 -Serve -Open" -ForegroundColor White
            Write-Host "   O usar Live Server de VS Code" -ForegroundColor White
        }

    } else {
        Write-Host "❌ Error en Web build (código: $($process.ExitCode))" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error ejecutando Web build: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n🌐 BUILD WEB COMPLETADO!" -ForegroundColor Green
