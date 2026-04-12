import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/io_client.dart';

/// HttpFileService avec bypass SSL (certificat intermédiaire manquant sur certains serveurs)
class _SslBypassFileService extends HttpFileService {
  _SslBypassFileService()
      : super(
          httpClient: IOClient(
            HttpClient()
              ..badCertificateCallback = (cert, host, port) => true,
          ),
        );
}

/// Service de gestion du cache d'images optimisé pour les performances
/// 
/// **Caractéristiques :**
/// - Cache intelligent avec expiration automatique
/// - Limite de taille du cache pour éviter saturation
/// - Nettoyage automatique des anciennes entrées
/// - Support multi-sources (network, Firebase Storage, etc.)
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  /// Cache Manager personnalisé avec durée de vie et taille optimisées
  static const key = 'siade2ImageCache';
  
  static final CacheManager customCacheManager = CacheManager(
    Config(
      key,
      // Durée de vie du cache : 30 jours (pour images statiques)
      stalePeriod: const Duration(days: 30),
      
      // Nombre maximum d'objets en cache : 200 images
      maxNrOfCacheObjects: 200,
      
      // Nettoyage automatique quand le cache dépasse la limite
      repo: JsonCacheInfoRepository(databaseName: key),
      
      // Stockage sur disque (persistant)
      fileService: _SslBypassFileService(),
    ),
  );

  /// Cache Manager pour images temporaires (stories, posts récents)
  static const tempKey = 'siade2TempImageCache';
  
  static final CacheManager tempCacheManager = CacheManager(
    Config(
      tempKey,
      // Durée de vie courte : 3 jours
      stalePeriod: const Duration(days: 3),
      
      // Cache plus petit pour contenu temporaire
      maxNrOfCacheObjects: 100,
      
      repo: JsonCacheInfoRepository(databaseName: tempKey),
      fileService: _SslBypassFileService(),
    ),
  );

  /// Vider tout le cache (utile pour libérer de l'espace)
  Future<void> clearCache() async {
    await customCacheManager.emptyCache();
    await tempCacheManager.emptyCache();
    print('✅ Cache d\'images vidé');
  }

  /// Vider uniquement le cache temporaire
  Future<void> clearTempCache() async {
    await tempCacheManager.emptyCache();
    print('✅ Cache temporaire vidé');
  }

  /// Obtenir la taille actuelle du cache
  /// Note: Calcul simplifié, retourne 0 (API limitée dans flutter_cache_manager 3.4.1)
  Future<int> getCacheSize() async {
    // La méthode retrieveAll() n'est pas disponible dans l'API publique
    // Le cache est limité automatiquement par maxNrOfCacheObjects
    return 0;
  }

  /// Formater la taille du cache en MB
  String formatCacheSize(int bytes) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Précharger une image importante (splash, logo, etc.)
  Future<void> precacheImage(String url, {bool temporary = false}) async {
    try {
      final manager = temporary ? tempCacheManager : customCacheManager;
      await manager.downloadFile(url);
      print('✅ Image précachée: $url');
    } catch (e) {
      print('⚠️  Erreur précache image: $e');
    }
  }

  /// Précharger plusieurs images en parallèle
  Future<void> precacheImages(List<String> urls, {bool temporary = false}) async {
    await Future.wait(
      urls.map((url) => precacheImage(url, temporary: temporary)),
    );
  }

  /// Supprimer une image spécifique du cache
  Future<void> removeFromCache(String url) async {
    await customCacheManager.removeFile(url);
    await tempCacheManager.removeFile(url);
  }
}
