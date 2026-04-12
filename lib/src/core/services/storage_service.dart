import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

/// Service de gestion du stockage Firebase Storage
/// 
/// **Fonctionnalités :**
/// - Upload d'images pour les posts
/// - Upload d'avatars utilisateurs
/// - Suppression d'images
/// - Génération d'URLs publiques
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Upload une image de post
  /// Retourne l'URL publique de l'image uploadée
  Future<String?> uploadPostImage(File imageFile) async {
    try {
      print('🟡 [StorageService] Début uploadPostImage()');
      
      if (currentUserId == null) {
        print('❌ [StorageService] Utilisateur non connecté');
        return null;
      }
      print('✅ [StorageService] UserId: $currentUserId');

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final storagePath = 'posts/$currentUserId/$fileName';
      print('🟡 [StorageService] Chemin: $storagePath');
      
      final ref = _storage.ref().child(storagePath);

      // Vérifier que le fichier existe
      final fileExists = await imageFile.exists();
      print('🟡 [StorageService] Fichier existe: $fileExists');
      if (!fileExists) {
        print('❌ [StorageService] Fichier introuvable: ${imageFile.path}');
        return null;
      }
      
      final fileSize = await imageFile.length();
      print('🟡 [StorageService] Taille: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Upload avec metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': currentUserId!,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      print('🟡 [StorageService] Démarrage upload...');
      final uploadTask = ref.putFile(imageFile, metadata);

      // Suivre la progression
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('📤 [StorageService] Upload en cours: ${progress.toStringAsFixed(1)}%');
      });

      // Attendre la fin de l'upload
      await uploadTask;
      print('✅ [StorageService] Upload terminé');

      // Obtenir l'URL publique
      print('🟡 [StorageService] Récupération de l\'URL...');
      final downloadUrl = await ref.getDownloadURL();
      print('✅ [StorageService] URL obtenue: ${downloadUrl.substring(0, 50)}...');
      
      return downloadUrl;
    } catch (e, stackTrace) {
      print('❌ [StorageService] Erreur uploadPostImage:');
      print('❌ [StorageService] Message: $e');
      print('❌ [StorageService] Type: ${e.runtimeType}');
      print('❌ [StorageService] Stack: $stackTrace');
      return null;
    }
  }

  /// Upload plusieurs images en parallèle
  Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    try {
      print('\n🔵 [StorageService] ========== UPLOAD MULTIPLE ==========');
      print('🔵 [StorageService] Nombre d\'images: ${imageFiles.length}');
      
      final uploadFutures = imageFiles.map((file) => uploadPostImage(file));
      print('🔵 [StorageService] Lancement des uploads en parallèle...');
      
      final results = await Future.wait(uploadFutures);
      print('🔵 [StorageService] Tous les uploads terminés');
      print('🔵 [StorageService] Résultats: ${results.length} réponses');
      
      // Filtrer les null values
      final validUrls = results.where((url) => url != null).cast<String>().toList();
      print('✅ [StorageService] URLs valides: ${validUrls.length}/${results.length}');
      print('🔵 [StorageService] ========== FIN UPLOAD ==========\n');
      
      return validUrls;
    } catch (e, stackTrace) {
      print('❌ [StorageService] Erreur upload multiple images:');
      print('❌ [StorageService] Message: $e');
      print('❌ [StorageService] Stack: $stackTrace');
      return [];
    }
  }

  /// Upload une image d'avatar utilisateur
  Future<String?> uploadAvatarImage(File imageFile) async {
    try {
      if (currentUserId == null) return null;

      final fileName = 'avatar_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('avatars/$fileName');

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      
      print('✅ Avatar uploadé: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Erreur upload avatar: $e');
      return null;
    }
  }

  /// Supprimer une image par son URL
  Future<bool> deleteImageByUrl(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      
      print('✅ Image supprimée: $imageUrl');
      return true;
    } catch (e) {
      print('❌ Erreur suppression image: $e');
      return false;
    }
  }

  /// Supprimer plusieurs images
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    for (var url in imageUrls) {
      await deleteImageByUrl(url);
    }
  }

  /// Obtenir la taille d'un fichier dans Storage
  Future<int?> getFileSize(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      final metadata = await ref.getMetadata();
      return metadata.size;
    } catch (e) {
      print('❌ Erreur récupération taille: $e');
      return null;
    }
  }
}
