# FishingSiKness - Deploy Vercel (Simplificado)
param(
    [string]$ProjectPath = "E:\GitHub\Fishing-SiKness\build\builds\web\latest",
    [switch]$Prod = $false,
    [switch]$Production = $false,
    [switch]$Open = $false
)

# Usar ProjectPath si se proporciona, sino usar el directorio por defecto
$BuildDir = if ($ProjectPath) { $ProjectPath } else { "E:\GitHub\Fishing-SiKness\build\builds\web\latest" }
$RootDir = "E:\GitHub\Fishing-SiKness"

Write-Host "🚀 Deploy FishingSiKness a Vercel" -ForegroundColor Magenta

# Verificar que existe el build
if (-not (Test-Path $BuildDir)) {
    Write-Host "❌ No se encontró build en: $BuildDir" -ForegroundColor Red
    exit 1
}

Write-Host "📦 Build encontrado: $BuildDir" -ForegroundColor Green

# Copiar configuración de Vercel al directorio de build
$vercelConfigSource = Join-Path $RootDir ".vercel"
$vercelConfigTarget = Join-Path $BuildDir ".vercel"

if (Test-Path $vercelConfigSource) {
    if (Test-Path $vercelConfigTarget) {
        Remove-Item $vercelConfigTarget -Recurse -Force
    }
    Copy-Item $vercelConfigSource $vercelConfigTarget -Recurse -Force
    Write-Host "⚙️ Configuración .vercel copiada al build" -ForegroundColor Cyan
}

# Cambiar al directorio de build para el deploy
Set-Location $BuildDir
Write-Host "📁 Directorio de deploy: $(Get-Location)" -ForegroundColor Cyan

# Deploy con confirmación automática
$useProduction = $Production -or $Prod
if ($useProduction) {
    Write-Host "🚀 Desplegando a PRODUCCIÓN desde: $BuildDir" -ForegroundColor Yellow
    vercel --prod --yes
}
else {
    Write-Host "🔍 Desplegando PREVIEW desde: $BuildDir" -ForegroundColor Yellow
    vercel --yes
}

Write-Host "✅ Deploy completado!" -ForegroundColor Green
