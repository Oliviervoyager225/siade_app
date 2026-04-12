import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

enum CallType { audio, video }

/// Gestion des appels audio/vidéo via Firestore comme couche de signalisation.
///
/// Structure d'un document `calls/{callId}`:
/// ```
/// callerId: uid
/// callerName: string
/// callerPhoto: string
/// calleeId: uid
/// calleeName: string
/// calleePhoto: string
/// channelName: string  (nom du channel Agora)
/// type: 'audio' | 'video'
/// status: 'ringing' | 'active' | 'ended' | 'rejected' | 'missed'
/// createdAt: Timestamp
/// ```
class CallService {
  static final CallService _i = CallService._();
  factory CallService() => _i;
  CallService._();

  final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'native-db',
  );
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─── Créer un appel ───────────────────────────────────────────────────────

  /// Crée un document d'appel dans Firestore et renvoie (callId, channelName).
  Future<(String, String)?> createCall({
    required String calleeId,
    required String calleeName,
    required String? calleePhoto,
    required CallType type,
  }) async {
    final uid = _uid;
    if (uid == null) return null;

    final user = _auth.currentUser!;

    // Annuler tout appel en sonnerie déjà lancé
    await _endMyRingingCalls();

    final channelName =
        'call_${uid}_${calleeId}_${DateTime.now().millisecondsSinceEpoch}';

    final ref = _db.collection('calls').doc();
    await ref.set({
      'callerId': uid,
      'callerName': user.displayName ?? 'Utilisateur',
      'callerPhoto': user.photoURL ?? '',
      'calleeId': calleeId,
      'calleeName': calleeName,
      'calleePhoto': calleePhoto ?? '',
      'channelName': channelName,
      'type': type.name,
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return (ref.id, channelName);
  }

  // ─── Changer le statut ────────────────────────────────────────────────────

  Future<void> acceptCall(String callId) =>
      _db.collection('calls').doc(callId).update({'status': 'active'});

  Future<void> rejectCall(String callId) =>
      _db.collection('calls').doc(callId).update({'status': 'rejected'});

  Future<void> endCall(String callId) =>
      _db.collection('calls').doc(callId).update({'status': 'ended'});

  Future<void> markMissed(String callId) =>
      _db.collection('calls').doc(callId).update({'status': 'missed'});

  // ─── Streams ──────────────────────────────────────────────────────────────

  /// Stream du premier appel entrant en sonnerie pour l'utilisateur courant.
  Stream<QueryDocumentSnapshot<Map<String, dynamic>>?> watchIncomingCall() {
    final uid = _uid;
    if (uid == null) return Stream.value(null);
    return _db
        .collection('calls')
        .where('calleeId', isEqualTo: uid)
        .where('status', isEqualTo: 'ringing')
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty ? null : snap.docs.first);
  }

  /// Stream du statut d'un appel spécifique.
  Stream<String?> watchCallStatus(String callId) => _db
      .collection('calls')
      .doc(callId)
      .snapshots()
      .map((s) => s.data()?['status'] as String?);

  Future<Map<String, dynamic>?> getCall(String callId) async {
    final doc = await _db.collection('calls').doc(callId).get();
    return doc.exists ? doc.data() : null;
  }

  // ─── Nettoyage ────────────────────────────────────────────────────────────

  Future<void> _endMyRingingCalls() async {
    final uid = _uid;
    if (uid == null) return;
    final snap = await _db
        .collection('calls')
        .where('callerId', isEqualTo: uid)
        .where('status', isEqualTo: 'ringing')
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'status': 'ended'});
    }
    await batch.commit();
  }
}
