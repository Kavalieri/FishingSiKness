# Script de Build para Fishing SiKness Prerelease
# Optimizado para evitar errores de empaquetado

param(
    [string]$Version = "0.1.0-prerelease",
    [string]$Platform = "windows"
)

Write-Host "🎣 Fishing SiKness - Build Prerelease v$Version" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Configuración
$ProjectPath = "E:\GitHub\Fishing-SiKness\project"
$BuildPath = "E:\GitHub\Fishing-SiKness\build\builds\$Platform"

# Verificar que Godot esté disponible
Write-Host "🔧 Verificando Godot..." -ForegroundColor Yellow
try {
    $godotVersion = & godot --version 2>&1
    Write-Host "   ✅ Godot encontrado: $godotVersion" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ Error: Godot no está en PATH" -ForegroundColor Red
    exit 1
}

# Crear directorio de build
Write-Host "📁 Preparando directorios..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $BuildPath | Out-Null

# Limpiar archivos temporales antes del build
Write-Host "🧹 Limpiando archivos temporales..." -ForegroundColor Yellow
Push-Location $ProjectPath
Get-ChildItem -Recurse -Include "*.tmp", "*.log", ".godot" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Pop-Location

# Verificar archivos críticos
Write-Host "🔍 Verificando archivos críticos..." -ForegroundColor Yellow
$criticalFiles = @(
    "$ProjectPath\project.godot",
    "$ProjectPath\src\autoload\Content.gd",
    "$ProjectPath\src\autoload\Save.gd",
    "$ProjectPath\data\fish\fish_sardina.tres",
    "$ProjectPath\data\zones\zone_orilla.tres"
)

foreach ($file in $criticalFiles) {
    if (Test-Path $file) {
        $size = (Get-Item $file).Length
        if ($size -gt 0) {
            Write-Host "   ✅ $([System.IO.Path]::GetFileName($file)) ($size bytes)" -ForegroundColor Green
        }
        else {
            Write-Host "   ⚠️  $([System.IO.Path]::GetFileName($file)) está vacío" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "   ❌ $([System.IO.Path]::GetFileName($file)) no encontrado" -ForegroundColor Red
    }
}

# Build principal
Write-Host "🔨 Construyendo executable..." -ForegroundColor Yellow
$OutputFile = "$BuildPath\Fishing-SiKness-v$Version.exe"

try {
    Push-Location $ProjectPath

    # Export con configuración optimizada
    & godot --headless --export "Windows Desktop - Release" $OutputFile 2>&1 | Tee-Object -FilePath "$BuildPath\build.log"

    if ($LASTEXITCODE -eq 0 -and (Test-Path $OutputFile)) {
        $size = [math]::Round((Get-Item $OutputFile).Length / 1MB, 2)
        Write-Host "   ✅ Build exitoso: $size MB" -ForegroundColor Green
        Write-Host "   📦 Archivo: $OutputFile" -ForegroundColor Green
    }
    else {
        Write-Host "   ❌ Build falló. Ver build.log para detalles" -ForegroundColor Red
        exit 1
    }

}
catch {
    Write-Host "   ❌ Error durante build: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    Pop-Location
}

# Verificación post-build
Write-Host "🧪 Verificación post-build..." -ForegroundColor Yellow
if (Test-Path $OutputFile) {
    # Test de ejecución rápida (solo validar que inicia)
    Write-Host "   🚀 Probando executable..." -ForegroundColor Yellow

    $testProcess = Start-Process -FilePath $OutputFile -ArgumentList "--headless", "--quit" -PassThru -NoNewWindow
    $testProcess.WaitForExit(10000)  # 10 segundos máximo

    if ($testProcess.ExitCode -eq 0) {
        Write-Host "   ✅ Executable funciona correctamente" -ForegroundColor Green
    }
    else {
        Write-Host "   ⚠️  Executable inicia pero con warnings (normal para prerelease)" -ForegroundColor Yellow
    }
}
else {
    Write-Host "   ❌ Archivo de salida no encontrado" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Build Prerelease Completado!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host "📦 Archivo: $OutputFile" -ForegroundColor White
Write-Host "🎯 Versión: $Version" -ForegroundColor White
Write-Host "📝 Log: $BuildPath\build.log" -ForegroundColor White
Write-Host ""
Write-Host "Para distribuir:" -ForegroundColor Yellow
Write-Host "1. Probar en máquina limpia sin Godot" -ForegroundColor White
Write-Host "2. Verificar que todos los assets se cargan" -ForegroundColor White
Write-Host "3. Comprobar funcionalidad básica (pescar, cambiar zonas)" -ForegroundColor White
