# Script PowerShell pour compresser la vidéo avec FFmpeg
#
# Installation FFmpeg :
# winget install Gyan.FFmpeg
#
# OU télécharge depuis : https://ffmpeg.org/download.html

param(
    [string]$VideoPath = "assets/videos/video.mp4",
    [int]$CRF = 28,  # Qualité : 18 (excellente) à 28 (bonne), 23 = défaut
    [switch]$DryRun = $false
)

Write-Host "🎥 Script de Compression Vidéo - SIADE2" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier si FFmpeg est installé
$ffmpegCmd = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpegCmd) {
    Write-Host "❌ FFmpeg n'est pas installé !" -ForegroundColor Red
    Write-Host ""
    Write-Host "Pour installer FFmpeg :" -ForegroundColor Yellow
    Write-Host "  1. Ouvrir PowerShell en admin" -ForegroundColor White
    Write-Host "  2. Exécuter : winget install Gyan.FFmpeg" -ForegroundColor White
    Write-Host ""
    Write-Host "Ou télécharger depuis : https://ffmpeg.org/download.html" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "⚠️  ALTERNATIVE RECOMMANDÉE :" -ForegroundColor Yellow
    Write-Host "   Héberger la vidéo sur Firebase Storage ou YouTube" -ForegroundColor Yellow
    Write-Host "   au lieu de la bundler dans l'APK (gain : -24.7 MB)" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ FFmpeg détecté : $($ffmpegCmd.Source)" -ForegroundColor Green
Write-Host ""

# Chemin complet
$fullPath = Join-Path $PSScriptRoot $VideoPath
if (-not (Test-Path $fullPath)) {
    Write-Host "❌ Vidéo introuvable : $fullPath" -ForegroundColor Red
    exit 1
}

$videoFile = Get-Item $fullPath
$originalSizeMB = [math]::Round($videoFile.Length / 1MB, 2)

Write-Host "📁 Fichier : $($videoFile.Name)" -ForegroundColor Cyan
Write-Host "💾 Taille actuelle : $originalSizeMB MB" -ForegroundColor Yellow
Write-Host "⚙️  CRF (qualité) : $CRF (18=excellente, 28=bonne)" -ForegroundColor Cyan
Write-Host ""

if ($originalSizeMB -gt 10) {
    Write-Host "⚠️  ATTENTION : Cette vidéo est très lourde !" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Recommandations :" -ForegroundColor Yellow
    Write-Host "   1. 🌐 Héberger sur Firebase Storage/YouTube (meilleur)" -ForegroundColor Green
    Write-Host "   2. 🗜️  Compresser avec ce script (gain ~70-80%)" -ForegroundColor Yellow
    Write-Host ""
}

if ($DryRun) {
    Write-Host "📊 MODE DRY RUN : Analyse seulement" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Estimation de compression :" -ForegroundColor Cyan
    $estimatedSizeMB = $originalSizeMB * 0.25  # Environ 75% de réduction
    Write-Host "   - Taille estimée : ~$([math]::Round($estimatedSizeMB, 2)) MB" -ForegroundColor White
    Write-Host "   - Économie estimée : ~$([math]::Round($originalSizeMB - $estimatedSizeMB, 2)) MB" -ForegroundColor Green
    Write-Host ""
    exit 0
}

# Demander confirmation
$confirmation = Read-Host "Voulez-vous compresser cette vidéo ? (o/N)"
if ($confirmation -ne 'o' -and $confirmation -ne 'O') {
    Write-Host "❌ Opération annulée" -ForegroundColor Red
    exit 0
}

Write-Host ""

# Créer backup
$backupPath = "$fullPath.backup"
Copy-Item $fullPath -Destination $backupPath
Write-Host "💾 Backup créé : $backupPath" -ForegroundColor Cyan
Write-Host ""

# Fichier de sortie temporaire
$outputFile = "$fullPath.compressed.mp4"

Write-Host "🔄 Compression en cours..." -ForegroundColor Yellow
Write-Host "   (Cela peut prendre plusieurs minutes)" -ForegroundColor Gray
Write-Host ""

try {
    # Commande FFmpeg optimisée pour mobile
    & ffmpeg -i $fullPath `
        -vcodec libx264 `
        -crf $CRF `
        -preset medium `
        -movflags +faststart `
        -vf "scale='min(1280,iw)':'min(720,ih)':force_original_aspect_ratio=decrease" `
        -acodec aac `
        -b:a 128k `
        -y `
        $outputFile
    
    if (Test-Path $outputFile) {
        $newSize = (Get-Item $outputFile).Length
        $newSizeMB = [math]::Round($newSize / 1MB, 2)
        $savedMB = [math]::Round(($videoFile.Length - $newSize) / 1MB, 2)
        $percentSaved = [math]::Round((($videoFile.Length - $newSize) / $videoFile.Length) * 100, 1)
        
        Write-Host ""
        Write-Host "✅ Compression réussie !" -ForegroundColor Green
        Write-Host "   - Taille originale : $originalSizeMB MB" -ForegroundColor White
        Write-Host "   - Taille compressée : $newSizeMB MB" -ForegroundColor Green
        Write-Host "   - Économie : $savedMB MB (-$percentSaved%)" -ForegroundColor Green
        Write-Host ""
        
        # Remplacer l'original
        $replace = Read-Host "Remplacer l'original par la version compressée ? (o/N)"
        if ($replace -eq 'o' -or $replace -eq 'O') {
            Move-Item $outputFile $fullPath -Force
            Write-Host "✅ Original remplacé" -ForegroundColor Green
            Write-Host "   Backup disponible : $backupPath" -ForegroundColor Cyan
        } else {
            Write-Host "📁 Version compressée sauvegardée : $outputFile" -ForegroundColor Cyan
        }
    } else {
        Write-Host "❌ Échec de la compression" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Erreur : $_" -ForegroundColor Red
} finally {
    # Nettoyer le fichier temporaire si nécessaire
    if (Test-Path $outputFile -and (Test-Path $fullPath)) {
        # L'original existe toujours, on peut proposer de supprimer
    }
}

Write-Host ""
Write-Host "💡 Alternative recommandée :" -ForegroundColor Yellow
Write-Host "   Héberger la vidéo sur Firebase Storage pour réduire la taille de l'APK" -ForegroundColor Yellow
Write-Host ""
