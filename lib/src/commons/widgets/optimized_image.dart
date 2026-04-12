import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:siade2/src/core/services/image_cache_service.dart';
import 'package:siade2/src/utils/utils.dart';

/// Widget d'image optimisé avec cache intelligent
/// 
/// **Utilisation :**
/// ```dart
/// OptimizedImage(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 200,
///   height: 200,
///   fit: BoxFit.cover,
/// )
/// ```
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool isTemporary;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.isTemporary = false,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      
      // Utiliser le cache manager approprié
      cacheManager: isTemporary
          ? ImageCacheService.tempCacheManager
          : ImageCacheService.customCacheManager,
      
      // Placeholder pendant le chargement
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFF60438C)),
              ),
            ),
          ),
      
      // Widget d'erreur si l'image ne charge pas
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.grey[400],
              size: (width != null && height != null)
                  ? (width! < height! ? width! : height!) * 0.4
                  : 40,
            ),
          ),
      
      // Optimisation mémoire : fade in progressif
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 200),
      
      // Priorité de chargement
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      
      // Performance : limite la taille en mémoire
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );

    // Appliquer border radius si spécifié
    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}

/// Widget d'avatar optimisé avec cache
class OptimizedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double radius;
  final Color? backgroundColor;

  const OptimizedAvatar({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    this.radius = 20,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      // Pas d'image : afficher initiale
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? avatarColorForInitial(fallbackText),
        child: Text(
          fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.7,
          ),
        ),
      );
    }

    // Image avec cache
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? avatarColorForInitial(fallbackText),
      child: ClipOval(
        child: OptimizedImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: Container(
            color: backgroundColor ?? const Color(0xFF60438C),
            child: Center(
              child: Text(
                fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.7,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget d'image asset optimisé avec précache
class OptimizedAssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const OptimizedAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      
      // Cache asset images
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      
      // Erreur si asset manquant
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.grey[400],
          ),
        );
      },
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
