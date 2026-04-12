import 'package:flutter/material.dart';

/// Service pour gérer le chargement optimisé des assets lourds
/// 
/// **Problèmes identifiés :**
/// - Images JPG très lourdes (7-12 MB chacune)
/// - Vidéo MP4 de 24.7 MB
/// 
/// **Solutions :**
/// - Lazy loading : charger uniquement quand nécessaire
/// - Précache sélectif : charger les images critiques au démarrage
/// - Libération mémoire : nettoyer les images non utilisées
class AssetOptimizationService {
  static final AssetOptimizationService _instance = AssetOptimizationService._internal();
  factory AssetOptimizationService() => _instance;
  AssetOptimizationService._internal();

  /// Images critiques à précharger au démarrage de l'app
  static const List<String> criticalAssets = [
    'assets/images/sahanalytics.png',
    'assets/images/splash.png',
    'assets/images/logo.png',
  ];

  /// Images lourdes à charger en lazy (seulement quand affichées)
  static const List<String> heavyAssets = [
    'assets/images/story_1.jpg',      // 12.9 MB
    'assets/images/exposant.jpg',     // 12.9 MB
    'assets/images/carousel_4.jpg',   // 10.6 MB
    'assets/images/story_4.jpg',      // 10.6 MB
    'assets/images/carousel_bottom_2.jpg', // 10.3 MB
    'assets/images/story_2.jpg',      // 10.3 MB
    'assets/images/carousel_5.jpg',   // 10.0 MB
    'assets/images/story_3.jpg',      // 10.0 MB
    'assets/images/profile_banner.jpg', // 9.8 MB
    'assets/images/carousel_1.jpg',   // 9.8 MB
  ];

  /// Précharger les images critiques (petites et importantes)
  Future<void> precacheCriticalAssets(BuildContext context) async {
    try {
      await Future.wait(
        criticalAssets.map((asset) {
          return precacheImage(
            AssetImage(asset),
            context,
          );
        }),
      );
      print('✅ Images critiques précachées');
    } catch (e) {
      print('⚠️  Erreur précache critical assets: $e');
    }
  }

  /// Charger une image lourde seulement quand nécessaire
  /// Utiliser cacheWidth/cacheHeight pour réduire l'empreinte mémoire
  Widget loadHeavyAsset(
    String assetPath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      
      // CRITIQUE : Limiter la taille en mémoire
      // Ne charge pas l'image à sa résolution native
      cacheWidth: width != null ? (width * 2).toInt() : 800,
      cacheHeight: height != null ? (height * 2).toInt() : 800,
      
      // Gestion d'erreur
      errorBuilder: (context, error, stackTrace) {
        print('❌ Erreur chargement asset: $assetPath');
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image_outlined),
        );
      },
    );
  }

  /// Nettoyer les images de la mémoire après utilisation
  void clearImageCache() {
    // Vider le cache d'images Flutter
    imageCache.clear();
    imageCache.clearLiveImages();
    print('✅ Cache d\'images Flutter vidé');
  }

  /// Obtenir la taille actuelle du cache Flutter
  int getCurrentCacheSize() {
    return imageCache.currentSize;
  }

  /// Obtenir le nombre d'images en cache
  int getCachedImageCount() {
    return imageCache.liveImageCount + imageCache.pendingImageCount;
  }

  /// Configurer les limites du cache Flutter (à appeler au démarrage)
  void configureCacheLimits() {
    // Limite le cache à 100 images max
    imageCache.maximumSize = 100;
    
    // Limite le cache à 50 MB max (en bytes)
    imageCache.maximumSizeBytes = 50 * 1024 * 1024;
    
    print('✅ Limites du cache configurées: 100 images, 50 MB max');
  }
}

/// Widget optimisé pour afficher les images lourdes des assets
class HeavyAssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const HeavyAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final service = AssetOptimizationService();
    
    Widget image = service.loadHeavyAsset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}

/// Extension pour faciliter l'utilisation
extension AssetOptimizationExtension on BuildContext {
  /// Précharger les assets critiques au démarrage
  Future<void> precacheCriticalAssets() {
    return AssetOptimizationService().precacheCriticalAssets(this);
  }
}
