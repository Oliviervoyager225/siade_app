import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Gère la présence en ligne des utilisateurs dans Firestore.
///
/// Champs mis à jour dans `users/{uid}` :
///   - `isOnline`  : bool
///   - `lastSeen`  : Timestamp
///
/// Règle : un utilisateur visible dans la barre = `lastSeen > now - 3h`
class PresenceService {
  static final PresenceService _i = PresenceService._();
  factory PresenceService() => _i;
  PresenceService._();

  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'native-db',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Marque l'utilisateur comme en ligne.
  /// À appeler au démarrage de l'app et au retour au premier plan.
  Future<void> setOnline() async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  /// Marque l'utilisateur comme hors ligne.
  /// À appeler lors du passage en arrière-plan ou de la fermeture.
  Future<void> setOffline() async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}
