#!/usr/bin/env pwsh

# Script para reemplazar emojis en todos los archivos GDScript
# Ejecutar desde la raíz del proyecto: ./clean_emojis.ps1

param(
    [switch]$DryRun = $false
)

$emojiReplacements = @{
    '💰'  = 'COINS'
    '💎'  = 'GEMS'
    '🐟'  = 'FISH'
    '🛒'  = 'SHOP'
    '⬆'   = 'UP'
    '🗺️' = 'MAP'
    '🗺'  = 'MAP'
    '🌊'  = 'ZONE'
    '🎯'  = 'TARGET'
    '🔥'  = 'FIRE'
    '⭐'   = 'STAR'
    '✅'   = 'OK'
    '❌'   = 'ERROR'
    '🔄'  = 'REFRESH'
    '📏'  = 'SIZE'
    '📈'  = 'CHART'
    '📅'  = 'DATE'
    '⚙️'  = 'OPTIONS'
    '🚨'  = 'ALERT'
    '🛠'  = 'TOOLS'
    '🔧'  = 'WRENCH'
    '👤'  = 'USER'
    '🎮'  = 'GAME'
    '🎉'  = 'CELEBRATION'
    '💡'  = 'IDEA'
    '👑'  = 'CROWN'
    '❤️'  = 'HEART'
    '💋'  = 'KISS'
    '🏃'  = 'RUN'
    '👕'  = 'SHIRT'
    '💬'  = 'TALK'
    '😢'  = 'CRY'
    '✨'   = 'SPARKLE'
}

# Encontrar todos los archivos .gd
$gdFiles = Get-ChildItem -Path "project/src" -Recurse -Filter "*.gd"

$totalFiles = 0
$modifiedFiles = 0

foreach ($file in $gdFiles) {
    $totalFiles++
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $originalContent = $content

    # Aplicar reemplazos
    foreach ($emoji in $emojiReplacements.Keys) {
        if ($content.Contains($emoji)) {
            $content = $content.Replace($emoji, $emojiReplacements[$emoji])
            Write-Host "  Found '$emoji' in $($file.Name)"
        }
    }

    # Solo escribir si hay cambios
    if ($content -ne $originalContent) {
        $modifiedFiles++
        if (-not $DryRun) {
            Set-Content $file.FullName $content -Encoding UTF8 -NoNewline
            Write-Host "MODIFIED: $($file.FullName)" -ForegroundColor Green
        }
        else {
            Write-Host "WOULD MODIFY: $($file.FullName)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`nSummary:"
Write-Host "  Total files scanned: $totalFiles"
Write-Host "  Files with emojis: $modifiedFiles"

if ($DryRun) {
    Write-Host "  (Dry run - no changes made)"
}
