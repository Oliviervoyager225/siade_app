# Script PowerShell pour compresser automatiquement les images lourdes
# 
# Ce script réduit la taille des images JPG/PNG sans perte significative de qualité
# Utilise ImageMagick (il faut l'installer d'abord)
#
# Installation ImageMagick :
# winget install ImageMagick.ImageMagick
#
# OU télécharger depuis : https://imagemagick.org/script/download.php

param(
    [string]$AssetsPath = "assets/images",
    [int]$Quality = 85,
    [int]$MaxWidth = 1920,
    [switch]$DryRun = $false
)

Write-Host "🚀 Script de Compression d'Images - SIADE2" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier si ImageMagick est installé
$magickCmd = Get-Command magick -ErrorAction SilentlyContinue
if (-not $magickCmd) {
    Write-Host "❌ ImageMagick n'est pas installé !" -ForegroundColor Red
    Write-Host ""
    Write-Host "Pour installer ImageMagick :" -ForegroundColor Yellow
    Write-Host "  1. Ouvrir PowerShell en admin" -ForegroundColor White
    Write-Host "  2. Exécuter : winget install ImageMagick.ImageMagick" -ForegroundColor White
    Write-Host ""
    Write-Host "Ou télécharger depuis : https://imagemagick.org/script/download.php" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ ImageMagick détecté : $($magickCmd.Source)" -ForegroundColor Green
Write-Host ""

# Chemin complet
$fullPath = Join-Path $PSScriptRoot $AssetsPath
if (-not (Test-Path $fullPath)) {
    Write-Host "❌ Dossier introuvable : $fullPath" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Dossier cible : $fullPath" -ForegroundColor Cyan
Write-Host "⚙️  Paramètres :" -ForegroundColor Cyan
Write-Host "   - Qualité : $Quality%" -ForegroundColor White
Write-Host "   - Largeur max : ${MaxWidth}px" -ForegroundColor White
Write-Host "   - Mode : $(if ($DryRun) {'DRY RUN (simulation)'} else {'PRODUCTION'})" -ForegroundColor $(if ($DryRun) {'Yellow'} else {'Green'})
Write-Host ""

# Trouver toutes les images lourdes (> 1 MB)
$heavyImages = Get-ChildItem -Path $fullPath -Include *.jpg,*.jpeg,*.png -Recurse | 
    Where-Object { $_.Length -gt 1MB } | 
    Sort-Object Length -Descending

if ($heavyImages.Count -eq 0) {
    Write-Host "✅ Aucune image > 1 MB trouvée. Tout est déjà optimisé !" -ForegroundColor Green
    exit 0
}

Write-Host "📊 Images lourdes détectées : $($heavyImages.Count)" -ForegroundColor Yellow
Write-Host ""

# Afficher la liste
$totalSize = 0
foreach ($img in $heavyImages) {
    $sizeMB = [math]::Round($img.Length / 1MB, 2)
    $totalSize += $img.Length
    Write-Host "   🔸 $($img.Name) : $sizeMB MB" -ForegroundColor White
}

$totalSizeMB = [math]::Round($totalSize / 1MB, 2)
Write-Host ""
Write-Host "💾 Taille totale : $totalSizeMB MB" -ForegroundColor Magenta
Write-Host ""

if ($DryRun) {
    Write-Host "⚠️  MODE DRY RUN : Aucune modification ne sera effectuée" -ForegroundColor Yellow
    Write-Host ""
}

# Demander confirmation
if (-not $DryRun) {
    $confirmation = Read-Host "Voulez-vous compresser ces images ? (o/N)"
    if ($confirmation -ne 'o' -and $confirmation -ne 'O') {
        Write-Host "❌ Opération annulée" -ForegroundColor Red
        exit 0
    }
    Write-Host ""
}

# Créer un dossier de backup
$backupPath = Join-Path $PSScriptRoot "assets_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
if (-not $DryRun) {
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    Write-Host "💾 Backup créé : $backupPath" -ForegroundColor Cyan
    Write-Host ""
}

# Compresser chaque image
$compressed = 0
$totalSaved = 0

foreach ($img in $heavyImages) {
    $originalSize = $img.Length
    $originalSizeMB = [math]::Round($originalSize / 1MB, 2)
    
    Write-Host "🔄 Traitement : $($img.Name) ($originalSizeMB MB)..." -NoNewline
    
    if (-not $DryRun) {
        # Backup de l'original
        Copy-Item $img.FullName -Destination $backupPath
        
        # Compression avec ImageMagick
        $tempFile = "$($img.FullName).tmp"
        
        try {
            # Commande ImageMagick optimisée
            & magick convert $img.FullName `
                -strip `
                -interlace Plane `
                -quality $Quality `
                -resize "${MaxWidth}x${MaxWidth}>" `
                $tempFile
            
            # Remplacer l'original si la compression a réussi
            if (Test-Path $tempFile) {
                $newSize = (Get-Item $tempFile).Length
                $newSizeMB = [math]::Round($newSize / 1MB, 2)
                $savedMB = [math]::Round(($originalSize - $newSize) / 1MB, 2)
                $percentSaved = [math]::Round((($originalSize - $newSize) / $originalSize) * 100, 1)
                
                Move-Item $tempFile $img.FullName -Force
                
                $totalSaved += ($originalSize - $newSize)
                $compressed++
                
                Write-Host " ✅ $newSizeMB MB (-$savedMB MB, -$percentSaved%)" -ForegroundColor Green
            } else {
                Write-Host " ❌ Échec" -ForegroundColor Red
            }
        } catch {
            Write-Host " ❌ Erreur : $_" -ForegroundColor Red
            if (Test-Path $tempFile) {
                Remove-Item $tempFile -Force
            }
        }
    } else {
        # Simulation
        $estimatedNewSize = $originalSize * ($Quality / 100.0)
        $estimatedSavedMB = [math]::Round(($originalSize - $estimatedNewSize) / 1MB, 2)
        Write-Host " 📊 Économie estimée : ~$estimatedSavedMB MB" -ForegroundColor Cyan
        $compressed++
    }
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan

if (-not $DryRun) {
    $totalSavedMB = [math]::Round($totalSaved / 1MB, 2)
    Write-Host "✅ Compression terminée !" -ForegroundColor Green
    Write-Host "   - Images compressées : $compressed" -ForegroundColor White
    Write-Host "   - Espace économisé : $totalSavedMB MB" -ForegroundColor White
    Write-Host "   - Backup : $backupPath" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 Conseil : Testez votre app pour vérifier la qualité des images" -ForegroundColor Yellow
    Write-Host "   Si tout est OK, vous pouvez supprimer le backup" -ForegroundColor Yellow
} else {
    Write-Host "📊 Simulation terminée" -ForegroundColor Cyan
    Write-Host "   - Images à compresser : $compressed" -ForegroundColor White
    Write-Host ""
    Write-Host "Pour exécuter réellement :" -ForegroundColor Yellow
    Write-Host "   .\compress_assets.ps1" -ForegroundColor White
}

Write-Host ""
